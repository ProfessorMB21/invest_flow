# Patch Log

This file tracks changes made during development sessions. Each entry should include the date, description of changes, files modified, and any migration notes.

## Format

```markdown
### YYYY-MM-DD - Brief Description

**Changes:**
- List of specific changes made
- Bug fixes, features, refactors, etc.

**Files Modified:**
- `path/to/file.dart` - What changed

**Migration Notes:** (if applicable)
- Steps needed for existing code/data

**Known Issues:** (if any)
- Any issues introduced or remaining
```

---

## Log Entries

### 2026-04-10 - Documentation Setup

**Changes:**
- Created PATCH.md for tracking development changes
- Created CHANGELOG.md for version history

**Files Modified:**
- `PATCH.md` - Created
- `CHANGELOG.md` - Created

---

### 2026-04-10 - Fix Critical Compilation Errors

**Changes:**
- Fixed `theme_provider.dart` - removed `final` from `_themeMode` field to allow reassignment
- Fixed `theme_toggle.dart` - changed import from relative path to `package:` syntax
- Fixed `theme_toggle.dart` - corrected provider access pattern (removed `.notifier`)
- Fixed `main.dart:120` - corrected provider access pattern for theme provider
- Fixed `pubspec.yaml` - moved `flutter_lints` from dependencies to dev_dependencies

**Files Modified:**
- `lib/core/providers/theme_provider.dart:10` - Changed `final ThemeMode _themeMode` to `ThemeMode _themeMode`
- `lib/features/dashboard/presentation/widgets/theme_toggle.dart:3` - Fixed import path
- `lib/features/dashboard/presentation/widgets/theme_toggle.dart:10-11` - Fixed provider access
- `lib/main.dart:120` - Fixed theme notifier access
- `pubspec.yaml` - Moved flutter_lints to dev_dependencies

**Migration Notes:**
- Run `flutter pub get` to update dependencies after pulling changes

**Known Issues:**
- 35 warnings/info remain (non-blocking): print statements, deprecated withOpacity, unused imports/variables

---

### 2026-04-10 - Fix Warnings and Info Messages

**Changes:**
- Replaced all `print()` with `debugPrint()` (11 instances across repositories and services)
- Replaced deprecated `withOpacity()` with `withValues()` (7 instances)
- Removed unused imports and variables (6 instances)
- Wrapped debug prints in `kDebugMode` checks in `firestore_init_service.dart`
- Added `foundation.dart` imports for `debugPrint` and `kDebugMode`
- Removed unused `_isCheckingUpdate` field from `login_screen.dart`
- Removed unused `_ref` parameter from `ProjectNotifier` constructor

**Files Modified:**
- `lib/core/repositories/user_repository.dart:1-2,27` - Added foundation import, replaced print
- `lib/core/repositories/project_repository.dart:1-2,27` - Added foundation import, replaced print
- `lib/core/repositories/investment_repository.dart:1-2,27` - Added foundation import, replaced print
- `lib/core/services/firestore_init_service.dart:84,198,224,229,231` - Wrapped prints in kDebugMode
- `lib/core/utils/app_colors.dart:66-72` - Replaced withOpacity with withValues
- `lib/features/dashboard/presentation/dashboard_screen.dart:60,156` - Replaced withOpacity
- `lib/features/dashboard/presentation/widgets/profile_section.dart:37,75` - Replaced withOpacity
- `lib/features/dashboard/logic/dashboard_notifier.dart:120,149,163` - Replaced print, removed unused variable
- `lib/features/dashboard/presentation/dashboard_shell.dart:8` - Removed unused import
- `lib/features/auth/presentation/login_screen.dart:31,55,58` - Removed unused field and references
- `lib/features/projects/logic/project_notifier.dart:2,49-50,146` - Removed unused import, parameter, variable
- `lib/features/projects/presentation/project_detail_screen.dart:21` - Removed unused field

**Result:**
- Reduced from 44 issues to 12 issues
- All compilation errors resolved
- Remaining: 2 warnings, 10 info messages (non-blocking)

**Known Issues:**
- `_addSampleProjects` and `_addSampleUsers` unused in firestore_init_service (kept for dev use)
- 3 unnecessary underscores in widget variable names
- 2 BuildContext async gaps (potential runtime issues)
- 4 deprecated Radio API usages (functional, needs migration to RadioGroup)

---

### 2026-04-10 - Fix Theme Changes Not Propagating

**Changes:**
- Changed `themeModeProvider` from `Provider` to `ChangeNotifierProvider`
- Updated imports in theme_provider.dart to use `flutter_riverpod/legacy.dart`
- This ensures UI rebuilds when `notifyListeners()` is called on theme change

**Files Modified:**
- `lib/core/providers/theme_provider.dart:1-2,39` - Changed to ChangeNotifierProvider, updated imports

**Result:**
- Theme now changes across all screens in real-time
- Theme toggle in app bar and navigation rail both work correctly

---

### 2026-04-10 - Refactor Auto-Update System

**Changes:**
- Refactored `update_checker.dart` with cleaner code structure
- Replaced `print` statements with `debugPrint`
- Improved batch script generation using raw strings
- Added progress callback support (`UpdateProgressCallback`)
- Added proper error handling and cleanup
- Fixed potential memory leaks with proper stream handling
- Added `hasCheckedInCurrentSession` getter for external access
- Fixed CI/CD workflow syntax errors (line 63-64, typo `is_mamual_tag`)

**Files Modified:**
- `lib/core/services/update_checker.dart` - Complete refactor, raw string batch script, progress callbacks
- `lib/features/auth/presentation/login_screen.dart` - Simplified update check flow, removed unused `_isCheckingUpdate` field
- `.github/workflows/flutter_ci_cd.yml` - Fixed syntax errors in version calculation

**Migration Notes:**
- Update check progress callback is now available but optional
- Session guard prevents repeated checks automatically
- Call `UpdateChecker.resetSessionCheck()` on logout if needed

---

### 2026-04-10 - Change Theme Toggle to Cycle Button

**Changes:**
- Changed `ThemeToggle` from dropdown menu to simple icon button
- Button cycles through modes: light → dark → system → light
- Added `cycleThemeMode()` method to `ThemeNotifierState`
- Added tooltips showing next mode
- Added theme toggle button to login screen (top-right corner)
- Login screen converted to `ConsumerStatefulWidget` to use Riverpod

**Files Modified:**
- `lib/core/providers/theme_provider.dart` - Added `cycleThemeMode()` method
- `lib/features/dashboard/presentation/widgets/theme_toggle.dart` - Complete rewrite as IconButton with cycle logic
- `lib/features/auth/presentation/login_screen.dart` - Added ThemeToggle to Stack, converted to ConsumerStatefulWidget

**Behavior:**
- Tap once: switches to next theme mode
- Icon shows current mode (light_mode, dark_mode, brightness_auto)
- Tooltip shows what mode will be selected on next tap

---

### 2026-04-11 - Version Synchronization System & TODO Implementation

**Changes:**
- Implemented version.json synchronization system between pubspec.yaml and CI builds
- Created `tool/sync_version.dart` for version sync and verification
- Updated CI workflow to sync versions before build
- Modified login screen to read version from version.json
- Implemented TODOs in dashboard_screen.dart (notifications, totalInvested, profile edit)
- Added ProfileEditScreen with form fields (name, phone, bio)
- Added debug test mode for update checker with `runTest()` method
- Added test button (bug icon) in login screen for debug builds

**Files Modified:**
- `tool/sync_version.dart` - Created version sync script
- `.github/workflows/flutter_ci_cd.yml` - Added version sync and verification steps
- `lib/features/auth/presentation/login_screen.dart` - Read version from file, added test button
- `lib/features/dashboard/presentation/dashboard_screen.dart` - Implemented all TODOs
- `lib/features/dashboard/logic/dashboard_notifier.dart` - Implemented totalInvested calculation
- `lib/features/dashboard/presentation/screens/profile_edit_screen.dart` - Created profile edit screen
- `lib/core/services/update_checker.dart` - Added test mode and verbose logging
- `lib/main.dart` - Added ProfileEditScreen route
- `pubspec.yaml` - Added version.json to assets
- `version.json` - Created version tracking file

**Migration Notes:**
- Run `dart tool/sync_version.dart` before local builds to sync versions
- CI builds automatically sync versions during workflow

---

### 2026-04-19 - Fix Dark Theme Color Inconsistency

**Changes:**
- Removed `customDarkTheme` (had orange seed color and transparent black cards)
- Updated `darkTheme` to use consistent blue seed (0xFF0052CC) matching light theme
- Fixed card colors to use solid dark grays instead of transparent/semi-transparent
- Added explicit `scaffoldBackgroundColor` for proper dark mode base
- Updated `main.dart` to use single `darkTheme` for both dark and system modes

**Files Modified:**
- `lib/core/theme/app_theme.dart` - Removed customDarkTheme, updated darkTheme colors
- `lib/main.dart` - Simplified _getThemeData to use single darkTheme

**Result:**
- Dark theme now has consistent color scheme with light theme (blue accent)
- No more semi-transparent cards (black54) causing visual issues
- Cleaner theme configuration with single source of truth

---

## Active Work Queue

### High Priority (Completed ✓)
- [x] Fix `theme_provider.dart` - `_themeMode` final field assignment error
- [x] Fix `theme_toggle.dart` - incorrect import path
- [x] Fix `main.dart:120` - incorrect provider notifier access

### Medium Priority (Completed ✓)
- [x] Replace deprecated `withOpacity` with `withValues()` (7 instances)
- [x] Move `flutter_lints` to dev_dependencies
- [x] Remove or replace `print` statements with proper logging (11 instances)
- [ ] Fix `BuildContext` async gap issues (2 instances) - Low priority

### Low Priority (Pending)
- [x] Clean up unused fields and variables (6 instances)
- [ ] Update deprecated Radio API usage (4 instances) - Can wait
- [ ] Write actual widget tests
- [ ] Add proper error handling for repository methods

---

## Notes

- Always update this file when making changes
- Mark items as complete when done: [x]
- Keep migration notes for breaking changes
- Link to relevant CHANGELOG entries for major features
