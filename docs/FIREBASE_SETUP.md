# Firebase setup — step by step

Complete the local preview first, then connect this same project. Commands run from the folder containing `pubspec.yaml` unless stated otherwise. Use your own values wherever `<...>` appears.

## A. Prepare Android and Firebase

1. Install Flutter stable, Android Studio and its Flutter/Dart plugins. Run `flutter doctor` and fix missing Android SDK/licenses. Use Java 17 or the version required by your installed Android Studio/Gradle; this project compiles Java source for 17. Install **Android SDK Platform 36**. The supplied Gradle configuration enables core library desugaring. Minimum Android is API 24.
2. Open `Taskpilot` in Android Studio. Run `flutter pub get`. Connect an Android phone with USB debugging or start an emulator image that includes Google Play services. Run `flutter devices` to confirm the device appears.
3. Go to https://console.firebase.google.com/ and create a project, for example **Taskpilot**. Firebase assigns a unique project ID; it need not match the GitHub repository name. Analytics is optional for this assignment.
4. Install Node.js 22+ and the Firebase/FlutterFire command-line tools:
   ```sh
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```
   Add Dart's global pub-cache `bin` directory to PATH if `flutterfire` is not found. See https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path.
5. Configure the app:
   ```sh
   flutterfire configure --project=<your-project-id> --platforms=android,ios
   ```
   Select/create the Android app with package `com.sabbirfounder.taskpilot` and the iOS app with bundle ID `com.sabbirfounder.taskpilot`. Android-only students can use `--platforms=android` initially and rerun later for iOS. Allow replacement of `lib/firebase_options.dart`.
6. Confirm `android/app/google-services.json` belongs to this package/project. If absent, download it from Firebase Project settings → Your apps → Android and place it there. The Gradle Google services plugin is already declared and applies when this file exists. Do not add a duplicate plugin line if the CLI has already configured it. For iOS, obtain `ios/Runner/GoogleService-Info.plist` from the same project.

## B. Enable authentication

7. Firebase Console → Build → Authentication → Get started → Sign-in method: enable **Email/Password**. Enable **Google**, set a project support email, and save.
8. Register your Android signing fingerprints. From `android/`, run `./gradlew signingReport` on macOS/Linux or `gradlew.bat signingReport` on Windows. Copy the **debug SHA-1 and SHA-256** into Project settings → Your Android app → Add fingerprint. For a release build, also register the actual release/Play App Signing fingerprints.
9. After enabling Google and adding fingerprints, download the updated `google-services.json` again. Confirm it contains an OAuth client with `client_type: 3` (web client used as the server client ID). Run `flutterfire configure` again if needed, then completely rebuild the app. A hot reload does not apply native JSON changes.
10. Try sign-up with a name, valid email and a password of at least eight characters. Sign out, test email sign-in, test Google sign-in, and check that both users appear in Firebase Authentication. Password reset uses the email entered on the sign-in form.

## C. Create Firestore and publish rules

11. Firebase Console → Build → Firestore Database → Create database. Choose a suitable location and **production mode**. The app uses the default database.
12. Deploy the included rules and indexes:
    ```sh
    firebase deploy --only firestore --project <your-project-id>
    ```
    Alternatively paste `firestore.rules` into the Console's Rules tab and click Publish. Do not leave broad test-mode rules enabled. Each user's data lives at `users/{uid}/tasks/{taskId}`. No composite index is needed because this assignment-sized list is sorted/filtered in the app.
13. Run `flutter run -t lib/main.dart`. Create a task, edit it, set a due date and priority, mark it complete, search/filter it, and delete it after confirmation. Reopen the app and verify saved tasks remain. Sign in as another user and confirm the first user's tasks are not visible.

## D. Enable notifications and get the token

14. Open the app's **Workspace** tab. Under notifications, tap **Enable / refresh**, then allow notifications when the operating system asks. Android 13+ needs notification permission. If denied, enable it in system settings and try again. On iOS, finish section F first.
15. Expand **Device FCM token** and copy it. Tokens can change after reinstalling the app, clearing data, signing out, or refresh; always copy the current token for a test. The service listens for token refresh. This assignment exposes the token on the device; it does not automatically register a multi-device server token directory.
16. Tap **Test local notification**. A Taskpilot local notification should appear. Tap it to open the task list. This verifies local permission/display/navigation; it does not prove FCM delivery.

## E. Send a real Firebase push

17. In Firebase Console, open Messaging (sometimes under Engage), create a notification campaign, and enter:
    - Title: `New Task`
    - Text: `You have a new task: Complete Flutter Assignment`
    Choose **Send test message**, paste the device's current FCM token, and send. A plain notification opens the task list. Console labels may change; look for the test-device/token action.
18. For an exact-task test, use a notification **plus data** payload. Data values must be strings:
    ```json
    {"taskId":"ACTUAL_FIRESTORE_TASK_ID","userId":"ACTUAL_AUTH_UID","priority":"high"}
    ```
    The task detail screen has **Copy task ID**. The UID is in Firebase Authentication. Add these values under campaign custom data when supported, or use the supplied sender below. An arbitrary made-up task ID cannot open a real task. The app checks the owner and only reads the signed-in user's path.
19. Optional trusted-computer sender (never put Admin credentials in the mobile app): install Google Cloud CLI, then run:
    ```sh
    gcloud auth application-default login
    gcloud auth application-default set-quota-project <your-project-id>
    cd tools
    npm ci
    ```
    Your account needs permission to read the target task and send FCM messages in that Firebase project. Enable the Firebase Cloud Messaging API if it is disabled. Set `TASKPILOT_FCM_TOKEN` in the current terminal, then run:
    ```sh
    npm run send -- <your-project-id> <user-uid> <task-id>
    ```
    macOS/Linux: `export TASKPILOT_FCM_TOKEN='paste-token'`.
    PowerShell: `$env:TASKPILOT_FCM_TOKEN='paste-token'`.
    The sender reads the actual task, sends notification + data, and uses the matching priority channel. A returned message ID means FCM accepted it; verify display on the device. Do not commit a token, service-account key or ADC credential file.
20. Test each state separately:

    | State | Test and expected behavior |
    | --- | --- |
    | Foreground | Leave the task list visible, send FCM; `onMessage` creates one local notification. Tap opens the matching task/list. |
    | Background | Press Home, send FCM; the OS displays the notification. Tap invokes `onMessageOpenedApp`. |
    | Terminated | Close the app normally, send FCM, tap; `getInitialMessage` or local launch details route after startup/sign-in. |
    | Signed out | Tap a prior notification, sign in as the intended user; navigation is deferred until authentication. |
    | Missing task | Delete the target, then tap an old alert; show a friendly unavailable message and list. |
    | Repeated taps | Send two alerts for the same task; each tap should work. |
    | Different user | A payload addressed to another UID must not open that user's task. |

    Android **Force stop** and iOS swipe-away restrictions can prevent delivery until the app is reopened. Delivery timing is controlled by the OS/network; do not use data-only messages to judge the assignment's standard visible-background-notification flow. Android channel importance can be changed by the user; heads-up banners also depend on OS settings/Do Not Disturb.

## F. iOS setup (requires macOS and an Apple account)

21. Use Xcode and an iOS 15+ device. Add `GoogleService-Info.plist` to Runner in Xcode with **Runner target membership**. Open `ios/Runner.xcworkspace` after Flutter has prepared dependencies. Select your development team and check that the Runner bundle identifier matches Firebase.
22. Enable **Push Notifications** and **Background Modes → Remote notifications** under Runner → Signing & Capabilities. The background mode and notification delegate wiring are already present in source; signing capabilities/entitlements still belong to your Apple team. Xcode creates the appropriate signed `aps-environment` entitlement.
23. Apple Developer → Keys: create/choose an APNs authentication key. Upload its `.p8` file, Key ID and Team ID in Firebase Project settings → Cloud Messaging → Apple app configuration. Keep the private key outside the repository. APNs setup is required before a usable FCM token is available.
24. Configure Google sign-in in `ios/Runner/Info.plist`. Copy the actual values from your downloaded Firebase plist:
    ```xml
    <key>GIDClientID</key>
    <string>VALUE_OF_CLIENT_ID</string>
    <key>CFBundleURLTypes</key>
    <array><dict><key>CFBundleURLSchemes</key>
      <array><string>VALUE_OF_REVERSED_CLIENT_ID</string></array>
    </dict></array>
    ```
    Insert these inside the top-level `<dict>` and replace the example values. Do not disable Firebase method swizzling. The Google plugin documentation explains an optional web/server client ID if your OAuth configuration requires it.
25. Rebuild on the iPhone. Allow notification permission, tap Enable / refresh, and repeat all state/tap tests. If APNs registration is pending, verify capabilities, network and Firebase APNs key, then refresh again.

## Troubleshooting

- **Setup page remains:** FlutterFire options are still the stub, or Firebase initialization failed. Confirm project files and run a full rebuild.
- **Google sign-in fails/cancels unexpectedly:** check package/bundle ID, SHA fingerprints, enabled provider, updated JSON, OAuth client and iOS URL scheme.
- **Permission denied in Firestore:** deploy the included rules to the same project as `firebase_options.dart`; sign in; use the default database.
- **No banner in foreground:** enable notifications, test the local button, check system channel settings and Do Not Disturb. Inspect the Workspace error message.
- **No FCM token on iOS:** finish APNs capabilities/key setup; use a physical device and retry.
- **Background duplicates:** send one notification + data message. Do not add a second local display inside `firebaseBackgroundHandler`.
- **App blocked while saving offline:** Firestore writes can wait for a server connection; restore connectivity. The editor keeps the draft and prevents repeated submissions.
- **Build SDK mismatch:** use the validated Flutter version and install Android Platform 36. Run `flutter clean`, `flutter pub get`, then rebuild after native configuration changes.

## Optional: run the security tests locally

Install Node.js 22+ and Java 21+, then from the project root run:

```sh
cd tools
npm ci
npm run test:rules
```

This uses a local Firestore emulator with the demo project ID `demo-taskpilot`;
it does not deploy rules or modify your real Firebase project. Expected
permission-denied log entries are part of the negative tests. Check the final
test summary for zero failures.

## Primary documentation links

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- https://firebase.google.com/docs/cloud-messaging/flutter/receive
- https://pub.dev/packages/flutter_local_notifications
- https://pub.dev/packages/google_sign_in_android
- https://pub.dev/packages/google_sign_in_ios
