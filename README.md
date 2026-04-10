# InvestFlow

Transparent Investment Tracking & Goal Management

[![Flutter Version](https://img.shields.io/badge/Flutter-3.11+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Firestore%20%7C%20Auth-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

InvestFlow is a Flutter-based crowdfunding and investment platform that connects investors with project owners. Built with Firebase backend (Firestore, Authentication), it provides real-time project tracking, investment management, and comprehensive analytics.

## Features

### For Investors
- Browse active investment projects
- Track investment portfolio in real-time
- View project milestones and progress
- Receive notifications on project updates

### For Project Owners
- Create and manage investment campaigns
- Track funding progress with visual analytics
- Manage project milestones
- Communicate with investors via messaging

### Platform Features
- **Real-time Updates**: Live project data via Firestore streams
- **Responsive Design**: Optimized for mobile and desktop
- **Theme Support**: Light/dark mode with system default option
- **Role-based Access**: Investor and Admin roles

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.11+ |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Backend** | Firebase (Auth, Firestore) |
| **Charts** | FL Chart |
| **Fonts** | Google Fonts (Inter) |

## Architecture

```
lib/
├── core/
│   ├── models/         # Data models (Project, Investment, UserProfile)
│   ├── providers/     # Riverpod providers
│   ├── repositories/  # Data access layer
│   ├── services/      # Firebase services
│   └── utils/         # Utilities & themes
├── features/
│   ├── auth/          # Authentication flow
│   ├── dashboard/     # Main dashboard
│   ├── projects/      # Project management
│   └── investments/   # Investment flow
└── main.dart
```

**Patterns Used:**
- Repository Pattern for data access
- Riverpod for state management
- Singleton pattern for services
- Immutable models with `copyWith`

## Getting Started

### Prerequisites

- Flutter SDK ^3.11.3
- Firebase CLI (for deployment)
- Android Studio / Xcode (for emulators)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd investflow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   
   Required files (not in git):
   - `android/app/google-services.json` - Android Firebase config
   - `lib/firebase_options.dart` - Flutter Firebase config
   - `firebase.json` - Firebase CLI config
   
   To configure:
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Running Tests

```bash
# Run all tests
flutter test

# With coverage
flutter test --coverage
```

## Project Documentation

| File | Description |
|------|-------------|
| [CLAUDE.md](CLAUDE.md) | Development guidelines and patterns |
| [PATCH.md](PATCH.md) | Session-by-session change tracking |
| [CHANGELOG.md](CHANGELOG.md) | Version history and release notes |

> **Note:** `CLAUDE.md` is local-only and not committed to git.

## Firebase Collections

| Collection | Purpose |
|------------|---------|
| `profiles` | User accounts (roles: investor, admin) |
| `projects` | Investment campaigns |
| `investments` | Individual investment records |
| `milestones` | Project progress milestones |
| `messages` | Project comments/messages |
| `app_settings` | App configuration |

## Available Scripts

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Build for production
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web

# Deploy Firebase rules
firebase deploy --only firestore:rules
```

## Contributing

1. Check [PATCH.md](PATCH.md) for active work queue
2. Update [CHANGELOG.md](CHANGELOG.md) for significant changes
3. Follow the patterns in [CLAUDE.md](CLAUDE.md)
4. Ensure `flutter analyze` passes before committing

## Roadmap

- [ ] Push notifications
- [ ] Payment integration
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Dark mode polish

## License

This project is licensed under the MIT License.

---

Built with Flutter and Firebase.
