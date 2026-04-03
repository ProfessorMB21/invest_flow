import 'dart:convert';
import 'dart:io';
import 'dart:ui';

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

  static Future<ReleaseInfo?> checkForUpdate() async {
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
      if (kDebugMode) {
        print('Update check failed: $e');
      }
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
      
      // Look for windows installer or portable executable
      if (name.endsWith('.exe') || name.endsWith('.msi')) {
        return asset['browser_download_url'] as String?;
      }
    }
    return null;
  }

  /// Shows a dialog and handles download/installation if confirmed
  static Future<void> promptAndInstall(BuildContext context, ReleaseInfo release) async {
    if (release.downloadUrl == null) {
      _showSnackBar(context, 'No Windows installer found for this release.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔄 Update Available'),
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
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update Now')),
        ],
      ),
    );

    if (confirmed == true) {
      await _downloadAndInstall(context, release.downloadUrl!);
    }
  }

  static Future<void> _downloadAndInstall(BuildContext context, String url) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = '${tempDir.path}/$fileName';

      final response = await http.Client().get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Download failed (HTTP ${response.statusCode})');

      await File(filePath).writeAsBytes(response.bodyBytes);

      if (context.mounted) Navigator.pop(context); // Close progress dialog

      // Launch installer & close current app
      if (Platform.isWindows) {
        // runInShell: true ensures Windows handles the .exe/.msi correctly
        await Process.start(filePath, [], runInShell: true);
        // Brief delay to let the OS spawn the installer process
        await Future.delayed(const Duration(milliseconds: 800));
        exit(0);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(context, 'Failed to download update: $e', isError: true);
      }
    }
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
