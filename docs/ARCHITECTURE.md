# How Taskpilot works

`main.dart` initializes Firebase, registers the background entry point, starts the UI and initializes notifications without waiting for token registration. The auth gate creates a Firestore store for the current UID. Sign-out closes the workspace and clears local alerts/token state.

Firestore documents contain title, description, dueDate (Timestamp), priority (`low`, `medium`, `high`), completed (bool), createdAt and updatedAt (server timestamps). Task ID is the document ID. Edits preserve creation time and do not overwrite a completion change from another device. The UI uses live snapshots. Rules deny cross-user access and unexpected fields. The list loads the user's tasks and applies search/filter/sort locally; add paginated server queries for a large production dataset.

Foreground FCM → authenticated owner check → bounded message-ID deduplication → local notification. iOS automatic foreground presentation is disabled so the local display is the sole foreground banner. Background notification payloads are displayed by the OS; the background isolate initializes Firebase but never navigates or displays a duplicate local alert.

Notification taps enter a queue. Routing waits for an authenticated workspace. `taskId` and optional `userId` are validated; missing/invalid task IDs open the list. A valid task is looked up under the current user's Firestore path. A missing task shows an explanation. No permanent task-ID deduplication prevents later notifications from opening the same task.

Permission and token acquisition are explicit Workspace actions, with retry/error messages. Tokens are shown/copyable and refreshed in memory; a production backend would maintain per-user device registrations with secure token lifecycle cleanup. The included trusted sender uses Application Default Credentials. The app does not contain a server credential or send pushes directly.

`main_demo.dart` uses the same widgets and a persisted local task store. Preview is visibly labeled. It does not pretend to authenticate or receive push messages. The native Firebase build and the browser preview have separate entry points.

Due dates are calendar dates in the user's local timezone and are stored as timestamps; cross-timezone date semantics would need a date-only schema for a global product. They are not scheduled reminders. The assignment's local-notification requirement is foreground FCM display.
