# InvestFlow - Development Guidelines

## Project Overview

InvestFlow is a Flutter crowdfunding/investment platform built with Firebase (Firestore, Auth) as the backend. It allows investors to browse and invest in projects, and project owners to manage campaigns.

### Architecture

```
lib/
├── core/          # Shared utilities, models, repositories, providers
│   ├── models/    # Data models (Project, Investment, UserProfile, etc.)
│   ├── providers/ # Riverpod providers
│   ├── repositories/  # Data access layer
│   ├── services/  # Firebase services
│   └── utils/     # Utilities
├── features/      # Feature modules
│   ├── auth/      # Authentication flow
│   ├── dashboard/ # Main dashboard
│   ├── projects/  # Project browsing & creation
│   ├── investments/ # Investment flow
│   └── ...
├── widgets/       # Reusable widgets
└── main.dart      # App entry point
```

---

## Key Patterns & Conventions

### 1. State Management: Riverpod

Use Flutter Riverpod for all state management:

```dart
// Define providers
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ref.watch(databaseServiceProvider).projectRepository;
});

// Consume in widgets
final projects = ref.watch(activeProjectsStreamProvider);
```

### 2. Repository Pattern

All data access goes through repositories in `core/repositories/`:

- `UserRepository` - User profiles
- `ProjectRepository` - Campaigns
- `InvestmentRepository` - Investments
- `MilestoneRepository` - Project milestones
- `MessageRepository` - Comments/messages

Repositories are obtained from `DatabaseService` (lazy-initialized singleton).

### 3. Firebase Collections

Standard collection names (defined in `FirestoreInitService`):

| Collection | Purpose |
|------------|---------|
| `profiles` | User accounts (role: investor|owner|admin) |
| `projects` | Investment campaigns |
| `investments` | Individual investment records |
| `milestones` | Project progress milestones |
| `messages` | Comments/messages on projects |
| `app_settings` | App configuration |

### 4. Model Classes

All models are immutable with a `copyWith` method:

```dart
class Project {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double goalAmount;
  final double raisedAmount;
  final ProjectStatus status; // active|completed|cancelled|paused
  // ...
  
  Project.copyWith({...})
}
```

Factory constructors:
- `fromFirestore(DocumentSnapshot)` - From Firestore
- `toFirestore()` - For saving to Firestore

### 5. Authentication Flow

1. `AuthService()` singleton manages auth state
2. Uses `AuthProviderInterface` with `FirebaseAuthProvider` implementation
3. Profile is created on first login via `createUserProfile()`
4. Auth state changes notify GoRouter for navigation

---

## Common Tasks

### Creating a New Feature

1. Create feature directory: `lib/features/feature_name/`
2. Add models to `core/models/` if needed
3. Add repository methods to existing repos or create new one
4. Add Riverpod streams/providers
5. Create screens in feature directory
6. Add navigation in main.dart or router file

### Adding a New Model

```dart
// lib/core/models/my_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MyModelStatus { pending, approved, rejected }

class MyModel {
  final String id;
  final String ownerId;
  final String title;
  final DateTime createdAt;
  
  MyModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.createdAt,
  });
  
  factory MyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MyModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'ownerId': ownerId,
    'title': title,
    'createdAt': Timestamp.fromDate(createdAt),
  };
  
  MyModel copyWith({...}) {
    return MyModel(
      id: this.id,
      ownerId: ownerId ?? this.ownerId,
      // ...
    );
  }
}
```

### Using Repositories in Widgets

```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => ConsumerState<MyScreen>();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(activeProjectsStreamProvider);
    
    return Scaffold(
      body: ListView.builder(
        itemCount: projects.length,
        itemBuilder: (ctx, i) => Card(
          child: Text(projects[i].title),
        ),
      ),
    );
  }
}
```

---

## Important Notes

### Firebase Initialization

The app auto-initializes Firestore collections on first launch. Check status via:

```dart
final status = await ref.read(firestoreInitService).getInitializationStatus();
```

### Security Rules

Firestore rules are in `firestore.rules`. Common patterns:

```javascript
match /profiles/{userId} {
  allow create: if request.auth.uid == userId;
  allow update, delete: if request.auth.uid == userId;
}

match /projects/{projectId} {
  allow read: if true; // public read
  allow create: if request.auth != null;
  allow update, delete: if request.auth.uid == resource.data.ownerId;
}

match /investments/{projectId}/{investmentId} {
  allow read: if true;
  allow create: if request.auth != null && 
                 request.data.projectId == resource.data.projectId;
  allow update, delete: if request.auth.uid == resource.data.investorId;
}
```

### GoRouter Navigation

Navigation uses GoRouter with named routes:

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/login',
      builder: (ctx, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (ctx, state) => const DashboardShell(),
    ),
    GoRoute(
      path: '/projects',
      builder: (ctx, state) => const ProjectsScreen(),
    ),
    GoRoute(
      path: '/projects/create',
      builder: (ctx, state) => const CreateProjectScreen(),
    ),
    GoRoute(
      path: '/projects/:projectId',
      builder: (ctx, state) => ProjectDetailScreen(
        projectId: state.pathParameters['projectId']!,
      ),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (ctx, state) => const ProfileEditScreen(),
    ),
  ],
);
```

### Theme

App uses custom theme in `lib/theme/app_theme.dart`:

- `lightTheme` - Default light mode
- `darkTheme` - Dark mode with grey cards
- Uses Google Fonts Inter

#### Theme Toggle

Theme mode managed via `ThemeNotifierState` (ChangeNotifier):

```dart
// Cycle through: light → dark → system → light
ref.read(themeModeProvider.notifier).cycleThemeMode();
```

- Toggle button in dashboard app bar and login screen
- Uses `ChangeNotifierProvider` for reactive UI updates

---

## Environment Setup

### Required Files (Not in Git)

These files are NOT tracked in git:

- `android/app/google-services.json` - Android Firebase config
- `firebase.json` - Firebase CLI config
- `firestore.rules` - Firestore security rules
- `firestore.indexed.json` - Index definitions
- `.firebaserc` - Firebase project config
- `lib/firebase_options.dart` - Generated Firebase config

To set up Firebase:

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize: `firebase init`
4. Deploy rules: `firebase deploy --only firestore:rules`

### Dependencies (pubspec.yaml)

Key packages:

- `flutter_riverpod` - State management
- `go_router` - Navigation
- `cloud_firestore`, `cloud_functions` - Firebase
- `google_sign_in`, `firebase_auth` - Authentication
- `google_fonts` - Typography
- `flutter_local_notifications` - Push notifications
- `package_info_plus` - App version info
- `http`, `path_provider`, `archive` - Update downloading

### Auto-Update System (Windows)

Automatic updates via GitHub releases:

**Flow:**
1. Check GitHub releases on startup (once per session)
2. Download ZIP if newer version exists
3. Extract to temp, run batch updater
4. Batch script replaces files and relaunches

**Usage:**
```dart
final update = await UpdateChecker.checkForUpdate();
if (update != null) {
  await UpdateChecker.promptAndInstall(context, update);
}
```

---

## Testing

Run tests:

```bash
flutter test
```

Coverage:

```bash
flutter test --coverage
```

---

## Performance Tips

1. **Batch Firestore operations** when creating multiple records
2. **Use collection groups** for cross-collection queries
3. **Implement pagination** for large lists (startAfter)
4. **Cache expensive data** with Riverpod future providers
5. **Monitor Firebase usage** in Firebase Console

## Code Style

- Use `flutter analyze` to check for issues
- Follow Dart style guide
- Prefer `final` over `var`
- Use `copyWith` for immutable objects
- Add comments for complex logic only

## Git Commits

- Never add "Co-authored-by: Claude" or similar attribution messages in git commits

---

## Project Documentation

### Documentation Files

| File | Purpose | When to Update |
|------|---------|----------------|
| `CLAUDE.md` | Project guidelines and patterns | When patterns change or new conventions are established |
| `PATCH.md` | Session-by-session change tracking | After every development session |
| `CHANGELOG.md` | Version history and release notes | When cutting releases or for major changes |

### Using PATCH.md

Always update `PATCH.md` when making changes:

1. **Before starting work:** Check the "Active Work Queue" for pending items
2. **During development:** Add entries under the current date
3. **After completing:** Mark items as complete `[x]`
4. **For breaking changes:** Include migration notes

**Rule:** Update PATCH.md and/or CHANGELOG.md before committing changes. Never commit without updating documentation.

### Using CHANGELOG.md

**Rule:** Always update `CHANGELOG.md` before committing changes. This is the primary documentation for users and release notes.

Update `CHANGELOG.md` for:

- New features (under `[Unreleased]` → `Added`)
- Bug fixes (under `[Unreleased]` → `Fixed`)
- Breaking changes (under `[Unreleased]` → `Changed` + migration guide)
- Release versions (move from `[Unreleased]` to `[X.Y.Z]`)
- Security improvements (under `[Unreleased]` → `Security`)

**Classification:** `CHANGELOG.md` is **documentation** — it describes what changed and why for end users. Keep it user-focused, not implementation-focused.

---

## Known Issues & Technical Debt

### Resolved ✅
| Issue | Location | Resolution |
|-------|----------|------------|
| `final` field reassignment | `theme_provider.dart:10` | Removed `final` keyword |
| Import path error | `theme_toggle.dart:3` | Changed to `package:` import |
| Provider access error | `main.dart:120` | Fixed notifier access pattern |
| `avoid_print` warnings | Multiple files | Replaced with `debugPrint` in `kDebugMode` |
| `withOpacity` deprecated | 7 instances | Replaced with `withValues()` |
| Unused imports/variables | 6 instances | Removed |
| `flutter_lints` dependency | `pubspec.yaml` | Moved to dev_dependencies |
| CI/CD workflow syntax errors | `.github/workflows/flutter_ci_cd.yml` | Fixed |
| Dashboard TODOs | `dashboard_screen.dart` | Implemented (notifications, totalInvested, profile edit) |
| Dark theme inconsistency | `app_theme.dart` | Consolidated to single darkTheme with blue seed, solid colors |
| Auto-login without consent | `firebase_auth_provider.dart` | Added "Remember me" toggle + sign out on init if disabled |
| Version text invisible | `login_screen.dart:281` | Changed from `Colors.white54` to theme-aware `colorScheme.onSurface` |

---

## Authentication Features

### Remember Me / Quick Login

The app implements configurable session persistence:

```dart
// AuthPersistenceService handles saved credentials and persistence
final persistence = AuthPersistenceService();

// Check if user wants to stay logged in
bool rememberMe = persistence.rememberMe;

// Get saved credentials for quick login
String? savedEmail = persistence.savedEmail;
String? savedUsername = persistence.savedUsername;
```

**Features:**
- **Remember me checkbox** on login screen (default: true)
- **Quick login**: Shows saved username with password-only entry after first successful login
- **Firebase persistence** controlled by user preference (LOCAL vs NONE)
- **Clear on logout**: Optional credential clearing on sign out

**UI Flow:**
1. First login: Enter email + password, check "Remember me"
2. Next launch: Shows user card + password field (quick login)
3. Tap "Not you?" to switch to full email entry
4. Uncheck "Remember me" → session not persisted, user signed out on app restart

**Important:** If the user previously enabled "Remember me" but later disables it, they will be automatically signed out on the next app launch to respect the preference change.

### High Priority (Pending)
None - all resolved.

### Medium Priority (Pending)
| Issue | Count | Action |
|-------|-------|--------|
| Deprecated Radio API | 4 | Migrate to RadioGroup |
| BuildContext async gaps | 2 | Add mounted checks |
| Widget style issues | 1 | Reorder constructor args |

### Low Priority (Pending)
- Test coverage is minimal
- Naming style inconsistencies (`__` in variables)
