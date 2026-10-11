import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    final notifications = TaskpilotNotifications();
    runApp(TaskpilotApp(auth: AuthService(), notifications: notifications));
    // Device registration never delays the login/task UI.
    unawaited(notifications.initialize());
  } catch (_) {
    runApp(const TaskpilotApp(setupRequired: true));
  }
}
