# Before submitting your GitHub link

- Open the project folder and confirm the default entry point works with your Firebase project.
- Finish every auth, task and notification test in FIREBASE_SETUP.md on a device.
- Confirm Firestore rules are deployed; a second user cannot access the first user's tasks.
- Run `flutter analyze` and `flutter test` after your configuration changes.
- Keep only this assignment project at the repository root. Do not commit `build/`, `.dart_tool/`, `node_modules/`, local SDK paths, private keys or tokens.
- `firebase_options.dart` and Google client config identify your Firebase project; they are not Admin secrets. This ZIP ignores downloaded native client config by default. Document how your instructor obtains/recreates configuration, or deliberately include only non-secret client configuration if your course requires a directly runnable checkout. Never include a service-account private key.
- Configure a real release signing key before publishing. The generated Android release configuration uses debug signing for assignment development.
- Submit your existing repository link: https://github.com/SABBIR-FOUNDER/Taskpilot-App-with-Firebase-

Suggested description: A Flutter task manager with Firebase Authentication, Google Sign-In, Firestore CRUD, FCM push notifications, foreground local notifications, and a consistent Taskpilot design.
