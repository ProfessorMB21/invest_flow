# Changelog

All notable changes to the InvestFlow project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- PATCH.md for tracking development session changes
- CHANGELOG.md for version history
- Documentation guidelines in CLAUDE.md
- **New theme toggle button** that cycles through light/dark/system modes
- Theme toggle now available on login screen
- Update check progress callbacks for better UX
- `cycleThemeMode()` method to ThemeNotifierState
- `hasCheckedInCurrentSession` getter to UpdateChecker
- **Version synchronization system** - `version.json` synced with pubspec.yaml
- `tool/sync_version.dart` - Version sync and verification script
- **Profile edit screen** - Full profile editing with name, phone, bio fields
- **Debug test mode** for update checker with `runTest()` method
- Test button (bug icon) in login screen for debug builds

### Changed
- Updated CLAUDE.md with documentation structure
- Replaced all `print()` with `debugPrint()` for proper logging
- Moved `flutter_lints` from dependencies to dev_dependencies
- **Theme toggle UI**: Changed from dropdown menu to single-tap cycle button
- **Update checker**: Complete refactor with cleaner architecture, raw string batch scripts
- CI/CD workflow: Fixed syntax errors, added version sync verification
- Login screen version display now reads from `version.json`
- Dashboard TODOs implemented (notifications, totalInvested calculation, profile edit)

### Fixed
- Theme provider compilation errors (removed `final` from `_themeMode`)
- Theme toggle incorrect import path (relative → package:)
- Theme notifier access pattern (removed `.notifier` call on Provider)
- **Theme changes not propagating** - Changed `Provider` to `ChangeNotifierProvider`
- Deprecated `withOpacity()` → `withValues(alpha:)` (7 instances)
- Removed unused imports and variables (6 instances)
- Wrapped debug prints in `kDebugMode` checks
- CI/CD workflow syntax errors (`if : success()` → `if: success()`)

### Known Issues
- 2 BuildContext async gaps remaining (non-blocking)
- 4 deprecated Radio API usages (functional, needs RadioGroup migration)
- 2 unused helper methods in FirestoreInitService (kept for dev use)

---

## Template

### [X.Y.Z] - YYYY-MM-DD

#### Added
- New features

#### Changed
- Changes in existing functionality

#### Deprecated
- Soon-to-be removed features

#### Removed
- Now removed features

#### Fixed
- Bug fixes

#### Security
- Security improvements

---

## Version History

### [1.0.0] - TBD

#### Added
- Initial release
- Firebase Authentication (Email/Password)
- Firestore database integration
- Project creation and management
- Investment tracking
- Dashboard with analytics
- Theme switching (light/dark)
- Responsive navigation (mobile/desktop)

#### Features
- User profiles with roles (investor/admin)
- Real-time project updates via Firestore streams
- Project investment workflow
- Milestone tracking
- Message/comments on projects

---

## Migration Guides

### No migrations yet

When breaking changes are introduced, migration steps will be documented here.

