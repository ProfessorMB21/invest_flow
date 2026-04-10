import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

/// Callback for update progress updates
/// [downloaded] - bytes downloaded so far
/// [total] - total bytes to download, null if unknown
/// [phase] - current phase: 'checking', 'downloading', 'extracting', 'installing'
typedef UpdateProgressCallback = void Function(int downloaded, int? total, String phase);

/// Service for checking and installing app updates from GitHub releases
class UpdateChecker {
  static const String _owner = 'ProfessorMB21';
  static const String _repo = 'invest_flow';
  static const String _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  // GitHub token for private repos or higher rate limits
  static const String? _githubToken = null;

  // Session guard to prevent repeated checks
  static bool _hasCheckedInCurrentSession = false;

  /// Returns true if update check has been performed this session
  static bool get hasCheckedInCurrentSession => _hasCheckedInCurrentSession;

  /// Resets the session check flag (call on logout)
  static void resetSessionCheck() {
    _hasCheckedInCurrentSession = false;
  }

  /// Checks if an update is available
  /// Returns [ReleaseInfo] if update is available, null otherwise
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
        debugPrint('GitHub API returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersionStr = data['tag_name']?.toString() ?? '';
      final currentVersionStr = await _getCurrentVersion();

      if (latestVersionStr.isEmpty || currentVersionStr.isEmpty) return null;

      // Strip 'v' prefix if present and parse
      final currentVersion = Version.parse(currentVersionStr.replaceAll(RegExp(r'^v'), ''));
      final latestVersion = Version.parse(latestVersionStr.replaceAll(RegExp(r'^v'), ''));

      if (latestVersion > currentVersion) {
        return ReleaseInfo(
          version: latestVersionStr,
          releaseNotes: data['body'] ?? 'No release notes available.',
          downloadUrl: _getWindowsAssetUrl(data),
        );
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  static Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Extracts the Windows ZIP asset URL from GitHub release data
  static String? _getWindowsAssetUrl(Map<String, dynamic> data) {
    final assets = data['assets'] as List<dynamic>?;
    if (assets == null) return null;

    for (final asset in assets) {
      final name = asset['name']?.toString().toLowerCase() ?? '';
      final url = asset['browser_download_url'] as String?;
      // Look for Windows ZIP file
      if (name.contains('windows') && name.endsWith('.zip') && url != null) {
        return url;
      }
    }
    return null;
  }

  /// Shows update dialog and handles installation if confirmed
  static Future<bool> promptAndInstall(
    BuildContext context,
    ReleaseInfo release, {
    UpdateProgressCallback? onProgress,
  }) async {
    if (release.downloadUrl == null) {
      _showErrorSnackBar(context, 'No download available for this release');
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue),
            SizedBox(width: 8),
            Text('Update Available')
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Version ${release.version} is ready to install.'),
              const SizedBox(height: 8),
              const Text(
                'Release Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                release.releaseNotes,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.download),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      return await _downloadAndInstall(
        context,
        release.downloadUrl!,
        onProgress: onProgress,
      );
    }
    return false;
  }

  /// Downloads and installs the update
  static Future<bool> _downloadAndInstall(
    BuildContext context,
    String url, {
    UpdateProgressCallback? onProgress,
  }) async {
    BuildContext? dialogContext;
    String? zipPath;
    String? extractDir;

    void updateProgress(int downloaded, int? total, String phase) {
      onProgress?.call(downloaded, total, phase);
    }

    try {
      // Show progress dialog
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
                Text('Downloading update...'),
              ],
            ),
          );
        },
      );

      updateProgress(0, null, 'downloading');

      // Setup paths
      final tempDir = await getTemporaryDirectory();
      final zipName = url.split('/').last;
      zipPath = '${tempDir.path}/$zipName';
      extractDir = '${tempDir.path}/investflow_update_${DateTime.now().millisecondsSinceEpoch}';

      // Download with progress
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed (HTTP ${response.statusCode})');
      }

      final contentLength = response.contentLength;
      final file = File(zipPath);
      final sink = file.openWrite();
      int downloaded = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        updateProgress(downloaded, contentLength, 'downloading');
      }
      await sink.close();

      // Close progress dialog
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Check if context is still valid after async operations
      if (!context.mounted) {
        await _cleanup(zipPath, extractDir);
        return false;
      }

      // Show installing dialog
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
                Text('Installing update...'),
              ],
            ),
          );
        },
      );

      updateProgress(downloaded, contentLength, 'extracting');

      // Extract ZIP
      await _extractZip(zipPath, extractDir);

      // Close installing dialog
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Run updater and exit
      await _runWindowsUpdater(extractDir, zipPath);
      await Future.delayed(const Duration(milliseconds: 400));
      exit(0);
    } catch (e) {
      // Cleanup dialogs
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Cleanup files
      await _cleanup(zipPath, extractDir);

      if (context.mounted) {
        _showErrorSnackBar(context, 'Update failed: ${e.toString()}');
      }
      return false;
    }
  }

  /// Extracts ZIP file to output directory
  static Future<void> _extractZip(String zipPath, String outputDir) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw FileSystemException('ZIP file not found', zipPath);
    }

    final inputStream = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeStream(inputStream);

      for (final archiveFile in archive) {
        final fileName = archiveFile.name;
        if (fileName.isEmpty) continue;

        // Normalize path separators
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
  }

  /// Creates and runs batch script to replace files and relaunch
  static Future<void> _runWindowsUpdater(String extractDir, String zipPath) async {
    final tempDir = await getTemporaryDirectory();
    final batPath = '${tempDir.path}/apply_update.bat';
    final currentExe = Platform.resolvedExecutable;
    final appDir = File(currentExe).parent.path;
    final tempDirPath = tempDir.path;

    // Find the extracted app folder (it might be nested in a subfolder)
    final extractDirObj = Directory(extractDir);
    String sourceDir = extractDir;

    // Check if there's a single subfolder (common in ZIP releases)
    final contents = await extractDirObj.list().toList();
    final subdirs = contents.whereType<Directory>().toList();
    if (subdirs.length == 1) {
      sourceDir = subdirs.first.path;
    }

    // Use raw string to avoid Dart interpreting $ as interpolation
    final batContent = r'''
@echo off
setlocal EnableDelayedExpansion

set "CURRENT_EXE=''' + currentExe.replaceAll(r'%', r'%%') + r'''"
set "APP_DIR=''' + appDir.replaceAll(r'%', r'%%') + r'''"
set "SOURCE_DIR=''' + sourceDir.replaceAll(r'%', r'%%') + r'''"
set "ZIP_PATH=''' + zipPath.replaceAll(r'%', r'%%') + r'''"
set "TEMP_DIR=''' + tempDirPath.replaceAll(r'%', r'%%') + r'''"

for %%i in ("%CURRENT_EXE%") do set "EXE_NAME=%%~nxi"

:: Wait for Flutter app to close (max 10s timeout)
set /a WAIT_COUNT=0
:wait
timeout /t 1 >nul 2>nul
set /a WAIT_COUNT+=1
tasklist /FI "IMAGENAME eq %EXE_NAME%" 2>nul | find /I "%EXE_NAME%" >nul
if not errorlevel 1 if !WAIT_COUNT! LSS 10 goto wait

:: Copy all files from extracted folder to app directory
xcopy "%SOURCE_DIR%\*" "%APP_DIR%\" /E /Y /I /Q /R >nul 2>nul

:: Relaunch app
start "" "%CURRENT_EXE%"

:: Cleanup after short delay
timeout /t 2 >nul
if exist "%SOURCE_DIR%" rmdir /s /q "%SOURCE_DIR%"
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%"
if exist "%TEMP_DIR%\investflow_update_*" rmdir /s /q "%TEMP_DIR%\investflow_update_*"
del /f /q "%~f0"
exit
''';

    await File(batPath).writeAsString(batContent);

    // Run batch file hidden (no console window)
    await Process.start('cmd', ['/c', batPath], runInShell: true);
  }

  /// Cleans up temporary files
  static Future<void> _cleanup(String? zipPath, String? extractDir) async {
    try {
      if (zipPath != null) {
        final zipFile = File(zipPath);
        if (await zipFile.exists()) await zipFile.delete();
      }
      if (extractDir != null) {
        final dir = Directory(extractDir);
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  /// Shows error message in a snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

/// Information about a release
class ReleaseInfo {
  final String version;
  final String releaseNotes;
  final String? downloadUrl;

  const ReleaseInfo({
    required this.version,
    required this.releaseNotes,
    this.downloadUrl,
  });
}
