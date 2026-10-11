import 'dart:async';
import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import '../models/notification_intent.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notification + data messages are displayed by the OS in background/terminated states.
  // Do not show a second local notification here, and do not navigate from this isolate.
}

class TaskpilotNotifications extends ChangeNotifier {
  final _local = FlutterLocalNotificationsPlugin();
  final Queue<NotificationIntent> _pending = Queue();
  final LinkedHashSet<String> _seen = LinkedHashSet();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Future<void>? _initialization;
  bool _initialized = false;
  bool busy = false;
  String? token;
  String? error;
  AuthorizationStatus? permission;
  bool get hasPending => _pending.isNotEmpty;
  NotificationIntent? takeNext() =>
      _pending.isEmpty ? null : _pending.removeFirst();

  static const normal = AndroidNotificationChannel(
    'taskpilot_tasks',
    'Task updates',
    description: 'Updates about your tasks',
    importance: Importance.high,
  );
  static const urgent = AndroidNotificationChannel(
    'taskpilot_urgent',
    'High priority tasks',
    description: 'Updates for high priority tasks',
    importance: Importance.high,
  );

  void _enqueue(NotificationIntent intent) {
    _pending.add(intent);
    notifyListeners();
  }

  void _remoteTap(RemoteMessage message) =>
      _enqueue(NotificationIntent.fromData(message.data));

  Future<void> initialize() => _initialization ??= _initializeSafely();
  Future<void> _initializeSafely() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _enqueue(NotificationIntent.fromPayload(response.payload)),
      );
      final android = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(normal);
      await android?.createNotificationChannel(urgent);
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((m) => unawaited(_foreground(m))),
      );
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen(_remoteTap),
      );
      _subscriptions.add(
        FirebaseMessaging.instance.onTokenRefresh.listen(
          (value) {
            token = value;
            notifyListeners();
          },
          onError: (Object _) {
            error = 'Could not refresh the device token.';
            notifyListeners();
          },
        ),
      );
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      final localLaunch = await _local.getNotificationAppLaunchDetails();
      if (localLaunch?.didNotificationLaunchApp ?? false) {
        _enqueue(
          NotificationIntent.fromPayload(
            localLaunch?.notificationResponse?.payload,
          ),
        );
      }
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _remoteTap(initial);
      _initialized = true;
    } catch (_) {
      error =
          'Notifications are not ready. Check the native configuration and try again.';
      for (final sub in _subscriptions) {
        await sub.cancel();
      }
      _subscriptions.clear();
    }
    notifyListeners();
  }

  Future<void> enable() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (!_initialized) {
        _initialization = null;
        await initialize();
      }
      if (!_initialized) return;
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      permission = settings.authorizationStatus;
      if (permission == AuthorizationStatus.denied ||
          permission == AuthorizationStatus.notDetermined) {
        error =
            'Notifications are off. You can allow them in your device settings.';
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) {
          error =
              'Apple push registration is still pending. Check APNs setup and tap Enable / refresh again.';
          return;
        }
      }
      token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        error = 'No device token yet. Check the connection and try again.';
      }
    } catch (_) {
      error =
          'Could not register notifications. Check your connection and Firebase/APNs configuration.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _foreground(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    final intent = NotificationIntent.fromData(message.data);
    if (user == null || !intent.belongsTo(user.uid)) return;
    final id = message.messageId;
    if (id != null && !_seen.add(id)) return;
    if (_seen.length > 100) _seen.remove(_seen.first);
    try {
      final high = message.data['priority'] == 'high';
      final title =
          message.notification?.title ??
          message.data['title']?.toString() ??
          'Task update';
      final body =
          message.notification?.body ??
          message.data['body']?.toString() ??
          'Open Taskpilot to view your tasks.';
      await _show(
        title: high ? 'High priority · $title' : title,
        body: body,
        high: high,
        payload: intent.toPayload(),
        id:
            (id?.hashCode ?? DateTime.now().millisecondsSinceEpoch) &
            0x7fffffff,
      );
    } catch (_) {
      error =
          'A task alert arrived, but the local notification could not be shown.';
      notifyListeners();
    }
  }

  Future<void> _show({
    required String title,
    required String body,
    required bool high,
    required String payload,
    required int id,
  }) => _local.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        high ? urgent.id : normal.id,
        high ? urgent.name : normal.name,
        channelDescription: high ? urgent.description : normal.description,
        icon: 'ic_notification',
        importance: Importance.high,
        priority: high ? Priority.max : Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    ),
    payload: payload,
  );

  Future<void> showTest() async {
    if (!_initialized) throw StateError('Enable notifications first.');
    await _show(
      title: 'Taskpilot is ready',
      body: 'Your local notifications are working.',
      high: false,
      payload: const NotificationIntent().toPayload(),
      id: 1946,
    );
  }

  Future<void> clearForSignOut() async {
    _pending.clear();
    token = null;
    try {
      await _local.cancelAll();
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      /* Signing out still completes if the network is unavailable. */
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }
}
