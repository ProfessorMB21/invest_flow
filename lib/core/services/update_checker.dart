import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateChecker {
  static const String _owner = 'ProfessorMB21';
  static const String _repo = 'invest_flow';
  static const String _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static const String? _githubToken = null;

  // Session guard to prevent repeated checks after sign-out
  static bool _hasCheckedInCurrentSession = false;

  static Future<ReleaseInfo?> checkForUpdate() async {
    if (_hasCheckedInCurrentSession) return null;
    _hasCheckedInCurrentSession = true;

    if (!Platform.isWindows) return null;

    try {
      final headers = {
        'Accept': 'application/vnd.github+json',
        if (_githubToken != null) 'Authorization': 'Bearer $_githubToken',
      };

      final response = await http.get(Uri.parse(_apiUrl), headers: headers);
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Github API returned ${response.statusCode}');
        }
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersionStr = data['tag_name']?.toString() ?? '';
      final currentVersionStr = await _getCurrentVersion();

      if (latestVersionStr.isEmpty || currentVersionStr.isEmpty) return null;

      // Strip 'v' prefix if present and parse
      final currentVersion = Version.parse(currentVersionStr.replaceAll(RegExp(r'^v'), ''));
      final latestVersion = Version.parse(latestVersionStr.replaceAll(RegExp(r'v'), ''));

      if (latestVersion > currentVersion) {
        return ReleaseInfo(
          version: latestVersionStr,
          releaseNotes: data['body'] ?? 'No release notes available.',
          downloadUrl: _getWindowsAssetUrl(data),
        );
      }
    } catch (e) {
      throw Exception('Update check failed: $e');
    }
    return null;
  }

  static Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static String? _getWindowsAssetUrl(Map<String, dynamic> data) {
    final assets = data['assets'] as List<dynamic>?;
    if (assets == null) return null;
    
    for (final asset in assets) {
      final name = asset['name']?.toString().toLowerCase() ?? '';
      final url = asset['browser_download_url'] as String?;
      if (name.endsWith('.zip') && url != null) return url;
    }
    return null;
  }

  /// Shows a dialog and handles download/installation if confirmed
  static Future<void> promptAndInstall(BuildContext context, ReleaseInfo release) async {
    if (release.downloadUrl == null) {
      _showSnackBar(context, 'No Windows installer found for this release.', isError: true);
      return;
    }

    // Update dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.system_update, color: Colors.blue),
          SizedBox(width: 8),
          Text('Update Available')
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Version ${release.version} is ready to install.'),
              const SizedBox(height: 8),
              const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(release.releaseNotes, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
          ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.download),
              label: const Text('Update Now')
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _downloadAndInstall(context, release.downloadUrl!);
    }
  }

  static Future<void> _downloadAndInstall(BuildContext context, String url) async {
    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading & extracting update....')
            ]
          )
        );
      }
    );

    String? zipPath;
    String? extractDir;

    try {
      final tempDir = await getTemporaryDirectory();
      final zipName = url.split('/').last;
      zipPath = '${tempDir.path}/$zipName';
      extractDir = '${tempDir.path}/investflow_update_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Download ZIP
      final response = await http.Client().get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Download failed (HTTP ${response.statusCode})');
      await File(zipPath).writeAsBytes(response.bodyBytes);

      // 2. Extract ZIP
      await extractFileToDisk(zipPath, extractDir);

      if (context.mounted && dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // 3. Run updater script
      await _runWindowsUpdater(extractDir, zipPath);
      await Future.delayed(const Duration(microseconds: 400));
      exit(0);
    } catch (e) {
      if (context.mounted && dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        _showSnackBar(context, 'Update failed: ${e.toString().split('\n')}');
      }
    }
  }

  // Generates and executes a hidden batch script to replace locked files & relaunch
  static Future<void> _runWindowsUpdater(String extractDir, String zipPath) async {
    final tempDir = await getTemporaryDirectory();
    final batPath = '${tempDir.path}/apply_update.bat';
    final currentExe = Platform.resolvedExecutable;

    final batContent = '''
@echo off
setlocal EnableDelayedExpansion
set "CURRENT_EXE=%~1"
set "EXTRACT_DIR=%~2"
set "ZIP_PATH=%~3"

for %%i in ("%CURRENT_EXE%") do set "EXE_NAME=%%~nxi"

:: Wait for Flutter app to fully close (max 10s timeout)
set /a WAIT_COUNT=0
:wait
timeout /t 1 >nul 2>&1
set /a WAIT_COUNT+=1
tasklist /FI "IMAGENAME eq %EXE_NAME%" 2>nul | find /I "%EXE_NAME%" >nul
if not errorlevel 1 if !WAIT_COUNT! LSS 10 goto wait

:: Overwrite app files
xcopy "%EXTRACT_DIR%\\*" "%~dp1" /E /Y /I /Q /R > nul 2>&1

:: Relaunch app
start "" "%CURRENT_EXE%"

:: Cleanup temp files & self
timeout /t 2 >nul
rmdir /s /q "%EXTRACT_DIR%"
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%"
del /f /q "%~f0"
exit
''';

    await File(batPath).writeAsString(batContent);
    // runInShell ensures Windows handles the .bat correctly without showing a console window
    await Process.start('cmd', ['/c', batPath, currentExe, extractDir], runInShell: true);
  }

  // Extracts a ZIP archive to a target directory asynchronously
  static Future<void> extractFileToDisk(String zipPath, String outputDir) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw FileSystemException('ZIP file not found', zipPath);
    }

    await (() async {
      final inputStream = InputFileStream(zipPath);
      try {
        final archive = ZipDecoder().decodeStream(inputStream);

        for (final archiveFile in archive) {
          final fileName = archiveFile.name;
          if (fileName.isEmpty) continue;

          // Normalize forward slash to OS-specific separators
          final safeName = fileName.replaceAll('/', Platform.pathSeparator);
          final destinationPath = '$outputDir/$safeName';

          if (archiveFile.isFile) {
            final data = archiveFile.content as List<int>;
            final outFile = File(destinationPath);
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(data);
          } else {
            await Directory(destinationPath).create(recursive: true);
          }
        }
      } finally {
        await inputStream.close();
      }
    })();
    await Future.delayed(const Duration(microseconds: 100));
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    _showSnackBar(context, message, isError: true);
  }

  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Theme.of(context).primaryColor,
      ),
    );
  }
}

class ReleaseInfo {
  final String version;
  final String releaseNotes;
  final String? downloadUrl;
  const ReleaseInfo({required this.version, required this.releaseNotes, this.downloadUrl});
}
