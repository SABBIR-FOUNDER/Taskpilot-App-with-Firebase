# Taskpilot — App with Firebase

Your day, in focus. A branded Flutter task manager for the Firebase Push Notification + Local Notification assignment.

- **GitHub repository:** `Taskpilot-App-with-Firebase` (your existing repository URL ends in a hyphen).
- **Android Studio project / Dart package:** `taskpilot`.
- **App display name:** Taskpilot.
- **Android application ID / iOS bundle ID:** `com.sabbirfounder.taskpilot`.
- **Repository description:** A Flutter task manager with Firebase Authentication, Google Sign-In, Firestore task CRUD, FCM push notifications, and foreground local notifications.

## 1. Run the app first

Install Flutter stable (validated with Flutter 3.47.7 / Dart 3.13.5), Android Studio, its Flutter/Dart plugins, and an Android SDK. Open this folder, the one containing `pubspec.yaml`, in Android Studio.

```sh
flutter doctor
flutter pub get
flutter run -t lib/main_demo.dart
```

Select **Explore Taskpilot** to use the local preview. Create, edit, complete, search, filter, sort, and delete tasks. Preview tasks persist on that device. Email/Google authentication and push delivery require Firebase; the preview explains this when a sign-in button is used.

For a browser UI preview:

```sh
flutter run -d chrome -t lib/main_demo.dart
```

The Firebase assignment build targets **Android and iOS**. Web is provided for the local UI preview; web Firebase messaging/service workers are outside this project.

## 2. Connect Firebase and finish the assignment

Follow [the numbered Firebase setup guide](docs/FIREBASE_SETUP.md), then run:

```sh
flutter run -t lib/main.dart
```

The supplied `lib/firebase_options.dart` is intentionally a configuration stub. `flutterfire configure` replaces it with your actual project values. Without configuration, the default entry point shows a setup page with a local-preview button instead of crashing.

## Features included

| Area | Delivered behavior |
| --- | --- |
| Authentication | Email/password sign-in, sign-up, Google sign-in, password reset, sign-out, validation and error states |
| Tasks | Firestore create/read/update/delete scoped to the signed-in user, due dates, priorities, completion and created dates |
| Navigation | Responsive task list, detail, editor, account/notification settings |
| Organization | Search title/description, Pending/Completed filters, priority filter, due-date/newest/priority sorting |
| Safety of edits | Delete confirmation, unsaved-change confirmation, disabled duplicate save actions, retained form after failed saves |
| FCM | Background handler, device token and token refresh, foreground message listener, initial-message and opened-app handling |
| Local notifications | Foreground FCM becomes a local notification; priority-aware Android channels; local test button |
| Notification tap | Open the task list, or the matching task when `taskId` is present; defer until sign-in; safely handle missing tasks |
| Branding | Original plane/checkmark logo, launcher icons, navy/indigo/mint theme, generated abstract background |
| Security | Owner-only Firestore rules with field/type/length validation; trusted-computer notification sender |

## Project map

- `lib/app.dart` — authentication gate, preview, notification navigation.
- `lib/services/` — Firebase Authentication and notification lifecycle.
- `lib/data/` — Firestore and local-preview storage.
- `lib/models/` — task data, filters, and safe notification payload parsing.
- `lib/ui/` — welcome/sign-in, task list, task editor/detail, workspace settings.
- `android/`, `ios/`, `web/` — generated platform projects plus branding/native configuration.
- `assets/brand/` — logo source, icon PNG, background.
- `test/` — Flutter model and widget tests.
- `tools/` — trusted FCM sender and Firestore security-rule tests.
- `docs/` — setup, architecture, test results, brand notes, submission checklist.

## Checks

```sh
flutter analyze
flutter test
flutter build web -t lib/main_demo.dart
```

See [validation results and limits](docs/VALIDATION.md). Native authentication, APNs/FCM delivery, and signed builds must be verified against your Firebase project on devices. Due dates organize tasks; they do not schedule alarms automatically.

## Submit

Copy the contents of this project folder to your `Taskpilot-App-with-Firebase-` repository, keeping `pubspec.yaml` at the repository root. Commit source, assets, native projects, tests, rules, docs and lockfiles. Exclude build folders, dependencies, machine paths and credentials using the included `.gitignore`. This ZIP has not been pushed to GitHub.
