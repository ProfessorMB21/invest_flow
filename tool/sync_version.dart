import 'dart:convert';
import 'dart:io';

/// Syncs version.json with pubspec.yaml version
/// Run this script before building: dart tool/sync_version.dart
/// Or use --check to verify versions are in sync
void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final pubspecFile = File('pubspec.yaml');
  final versionFile = File('version.json');

  if (!pubspecFile.existsSync()) {
    print('❌ pubspec.yaml not found');
    exit(1);
  }

  // Read pubspec.yaml
  final pubspecContent = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(pubspecContent);

  if (versionMatch == null) {
    print('❌ Could not find version in pubspec.yaml');
    exit(1);
  }

  final pubspecVersion = versionMatch.group(1)!.trim().split('+')[0].split('-')[0];

  // Read version.json
  String? jsonVersion;
  if (versionFile.existsSync()) {
    try {
      final versionData = jsonDecode(versionFile.readAsStringSync()) as Map<String, dynamic>;
      jsonVersion = versionData['version']?.toString();
    } catch (e) {
      // Ignore parse errors
    }
  }

  if (checkOnly) {
    // Verify mode
    if (jsonVersion != pubspecVersion) {
      print('❌ Version mismatch:');
      print('   pubspec.yaml: $pubspecVersion');
      print('   version.json: ${jsonVersion ?? 'not found'}');
      exit(1);
    }
    print('✅ Versions in sync: $pubspecVersion');
    return;
  }

  // Sync mode
  print('📄 pubspec.yaml version: $pubspecVersion');
  print('📄 version.json version: ${jsonVersion ?? 'not set'}');

  // Create/update version.json
  final versionData = <String, dynamic>{
    'version': pubspecVersion,
    'buildTime': DateTime.now().toUtc().toIso8601String(),
    'source': 'pubspec-sync',
  };

  const encoder = JsonEncoder.withIndent('  ');
  versionFile.writeAsStringSync('${encoder.convert(versionData)}\n');

  print('✅ Synced version.json to: $pubspecVersion');
}
