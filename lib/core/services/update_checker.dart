import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
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
  /// Set [testMode] to true to bypass debug restrictions and see verbose logs
  static Future<ReleaseInfo?> checkForUpdate({bool testMode = false}) async {
    if (_hasCheckedInCurrentSession && !testMode) return null;
    _hasCheckedInCurrentSession = true;

    // Skip update check in debug mode (dev builds shouldn't auto-update)
    // Test mode bypasses this for verification
    if (kDebugMode && !testMode) {
      debugPrint('[UpdateChecker] Update check skipped in debug mode');
      debugPrint('[UpdateChecker] Pass testMode: true to test update functionality');
      return null;
    }

    if (!Platform.isWindows && !testMode) return null;

    try {
      if (testMode) debugPrint('[UpdateChecker] TEST MODE: Checking GitHub API...');

      final headers = {
        'Accept': 'application/vnd.github+json',
        if (_githubToken != null) 'Authorization': 'Bearer $_githubToken',
      };

      if (testMode) debugPrint('[UpdateChecker] Fetching: $_apiUrl');
      final response = await http.get(Uri.parse(_apiUrl), headers: headers);
      if (response.statusCode != 200) {
        debugPrint('[UpdateChecker] GitHub API returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersionStr = data['tag_name']?.toString() ?? '';
      final currentVersionStr = await _getCurrentVersion(testMode: testMode);

      if (testMode) {
        debugPrint('[UpdateChecker] Current version: $currentVersionStr');
        debugPrint('[UpdateChecker] Latest version: $latestVersionStr');
      }

      if (latestVersionStr.isEmpty || currentVersionStr.isEmpty) {
        debugPrint('[UpdateChecker] Empty version string');
        return null;
      }

      // Strip 'v' prefix if present and parse
      final currentVersion = Version.parse(currentVersionStr.replaceAll(RegExp(r'^v'), ''));
      final latestVersion = Version.parse(latestVersionStr.replaceAll(RegExp(r'^v'), ''));

      if (testMode) {
        debugPrint('[UpdateChecker] Parsed current: $currentVersion');
        debugPrint('[UpdateChecker] Parsed latest: $latestVersion');
        debugPrint('[UpdateChecker] Update available: ${latestVersion > currentVersion}');
      }

      if (latestVersion > currentVersion) {
        final downloadUrl = _getWindowsAssetUrl(data);
        if (testMode) {
          debugPrint('[UpdateChecker] Download URL: $downloadUrl');
        }
        return ReleaseInfo(
          version: latestVersionStr,
          releaseNotes: data['body'] ?? 'No release notes available.',
          downloadUrl: downloadUrl,
        );
      } else if (testMode) {
        debugPrint('[UpdateChecker] No update needed - running latest version');
      }
    } catch (e, stack) {
      debugPrint('[UpdateChecker] Update check failed: $e');
      if (testMode) debugPrint('[UpdateChecker] Stack trace: $stack');
    }
    return null;
  }

  static Future<String> _getCurrentVersion({bool testMode = false}) async {
    // Try to read CI-built version file first (production builds)
    // This file is written during CI and bundled with the app
    final possiblePaths = [
      'version.json', // Same directory as executable (CI builds)
      '../version.json', // Relative to executable in build output
      'data/flutter_assets/version.json', // Flutter assets bundle location
    ];

    for (final path in possiblePaths) {
      try {
        final versionFile = File(path);
        final exists = await versionFile.exists();

        if (testMode) {
          debugPrint('[UpdateChecker] Checking path: $path');
          debugPrint('[UpdateChecker]   Exists: $exists');
        }

        if (!exists) continue;

        final content = await versionFile.readAsString();

        // Skip if empty
        if (content.trim().isEmpty) {
          if (testMode) debugPrint('[UpdateChecker]   File is empty, trying next');
          continue;
        }

        if (testMode) debugPrint('[UpdateChecker]   Content: $content');

        final data = jsonDecode(content) as Map<String, dynamic>?;
        if (data == null) {
          if (testMode) debugPrint('[UpdateChecker]   JSON is null, trying next');
          continue;
        }

        final version = data['version']?.toString();
        if (version == null || version.isEmpty) {
          if (testMode) debugPrint('[UpdateChecker]   Version field empty, trying next');
          continue;
        }

        debugPrint('[UpdateChecker] Using version from $path: $version');
        return version;

      } catch (e) {
        if (testMode) debugPrint('[UpdateChecker]   Error reading $path: $e');
        // Continue to next path
      }
    }

    // Fall back to package_info (development builds or when version.json not found)
    debugPrint('[UpdateChecker] version.json not found in any location, using package_info fallback');
    final packageInfo = await PackageInfo.fromPlatform();
    if (testMode) {
      debugPrint('[UpdateChecker] Using package_info version: ${packageInfo.version}');
    }
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

  /// Test method to verify update checker functionality in debug mode
  /// Returns detailed test results as a map
  static Future<Map<String, dynamic>> runTest() async {
    debugPrint('╔══════════════════════════════════════════════════════════════╗');
    debugPrint('║          UpdateChecker Test Mode - START                    ║');
    debugPrint('╚══════════════════════════════════════════════════════════════╝');

    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'isWindows': Platform.isWindows,
      'isDebug': kDebugMode,
    };

    // Test 1: Version retrieval
    debugPrint('\n[Test 1] Getting current version...');
    try {
      final version = await _getCurrentVersion(testMode: true);
      results['currentVersion'] = version;
      results['versionTest'] = 'PASS';
    } catch (e) {
      results['versionTest'] = 'FAIL';
      results['versionError'] = e.toString();
    }

    // Test 2: GitHub API check
    debugPrint('\n[Test 2] Checking GitHub API...');
    try {
      final update = await checkForUpdate(testMode: true);
      results['updateAvailable'] = update != null;
      results['apiTest'] = 'PASS';
      if (update != null) {
        results['latestVersion'] = update.version;
        results['downloadUrl'] = update.downloadUrl;
        results['releaseNotes'] = update.releaseNotes.substring(
          0, update.releaseNotes.length > 200 ? 200 : update.releaseNotes.length,
        );
      }
    } catch (e) {
      results['apiTest'] = 'FAIL';
      results['apiError'] = e.toString();
    }

    // Test 3: Version file check
    debugPrint('\n[Test 3] Checking version file...');
    try {
      final versionFile = File('assets/version.json');
      results['versionFileExists'] = await versionFile.exists();
      if (results['versionFileExists']) {
        final content = await versionFile.readAsString();
        results['versionFileContent'] = content;
      }
      results['fileTest'] = 'PASS';
    } catch (e) {
      results['fileTest'] = 'FAIL';
      results['fileError'] = e.toString();
    }

    debugPrint('\n╔══════════════════════════════════════════════════════════════╗');
    debugPrint('║          UpdateChecker Test Mode - COMPLETE                  ║');
    debugPrint('╚══════════════════════════════════════════════════════════════╝');
    debugPrint('\nResults:');
    results.forEach((key, value) {
      debugPrint('  $key: $value');
    });

    return results;
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
