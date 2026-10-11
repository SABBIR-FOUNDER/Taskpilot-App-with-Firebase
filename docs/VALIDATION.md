# Taskpilot validation

Checked on 12 October 2026 (Bangladesh time) with Flutter 3.47.7 and Dart 3.13.5. This report records checks actually performed; it is not a guarantee that every device or configuration behaves identically.

## Automated checks

| Check | Result |
| --- | --- |
| Flutter analyzer | No issues found |
| Dart formatting | Passed |
| Flutter model and widget tests | 13 passed |
| Firestore emulator rule tests | 5 passed; zero failures |
| Browser build for `lib/main_demo.dart` | Passed |
| JSON, Android XML, iOS plist parsing | Passed |
| Relative Dart imports and required native project files | Passed |
| JavaScript syntax for sender and security tests | Passed |

The Flutter tests cover task serialization, identity preservation, date/overdue behavior, search/filter/sort, notification payload ownership and malformed input, form validation, creating/completing a task, keeping a draft after a failed save, and 320px-wide layouts at 150% text scale. Security tests verify owner CRUD, cross-user denial, unauthenticated denial, field validation and immutable creation timestamps. Notification settings were included in the enlarged-text layout checks.

A separate internal render was used to inspect the welcome and task dashboard layouts. Its temporary capture script is not included in the submission project.

## Reproduce the checks

From the project root:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web -t lib/main_demo.dart
```

For Firestore rules, install Node.js 22+ and Java 21+, then:

```sh
cd tools
npm ci
npm run test:rules
```

The bundled GitHub Actions workflow runs these checks when the project is pushed. No GitHub push was performed while preparing this ZIP.

## Device checks still required

No Android SDK/emulator, Xcode signing environment, Firebase project configuration, or physical phone was available for end-to-end native testing. Consequently these are **not verified on a device**:

- Android APK and iOS native builds/signing.
- Email/password and Google OAuth against your project.
- Firestore synchronization between actual devices.
- Android notification permission and iOS/APNs provisioning.
- FCM foreground/background/terminated delivery and notification-tap navigation.

Complete the numbered device test matrix in `FIREBASE_SETUP.md` after configuring Firebase. The browser build verifies the local preview, not mobile FCM integration. Due dates do not schedule reminders. The supplied trusted-computer sender and Firebase Console provide the assignment's push-test path; task creation does not automatically send a push.

The provided Figma frames were inaccessible during development. The UI is a consistent original Taskpilot design based on the assignment requirements; an exact Figma match has not been verified.
