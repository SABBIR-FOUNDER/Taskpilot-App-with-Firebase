import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme.dart';
import 'data/task_store.dart';
import 'data/local_task_store.dart';
import 'data/firestore_task_store.dart';
import 'services/auth_service.dart';
import 'services/notifications.dart';
import 'ui/auth_page.dart';
import 'ui/common.dart';
import 'ui/workspace.dart';
import 'ui/task_detail.dart';

class TaskpilotApp extends StatefulWidget {
  const TaskpilotApp({
    super.key,
    this.auth,
    this.notifications,
    this.previewStore,
    this.setupRequired = false,
  });
  final AuthService? auth;
  final TaskpilotNotifications? notifications;
  final TaskStore? previewStore;
  final bool setupRequired;
  @override
  State<TaskpilotApp> createState() => _TaskpilotAppState();
}

class _TaskpilotAppState extends State<TaskpilotApp> {
  final _navigator = GlobalKey<NavigatorState>();
  GlobalKey<WorkspaceState> _workspace = GlobalKey<WorkspaceState>();
  StreamSubscription<User?>? _authSubscription;
  TaskStore? _store;
  User? _user;
  bool _preview = false,
      _ready = false,
      _handlingTap = false,
      _openingPreview = false;
  String? _previewError;
  @override
  void initState() {
    super.initState();
    widget.notifications?.addListener(_scheduleTaps);
    if (widget.auth != null) {
      _authSubscription = widget.auth!.changes.listen(_onUser);
    } else {
      _ready = true;
    }
  }

  void _onUser(User? user) {
    if (!mounted) return;
    if (_user?.uid != user?.uid || !_ready) {
      final previous = _store;
      _navigator.currentState?.popUntil((r) => r.isFirst);
      setState(() {
        _user = user;
        _preview = false;
        _ready = true;
        _store = user == null ? null : FirestoreTaskStore(user.uid);
        _workspace = GlobalKey<WorkspaceState>();
      });
      if (previous != null && previous != widget.previewStore) {
        unawaited(previous.dispose());
      }
    } else {
      setState(() => _user = user);
    }
    _scheduleTaps();
  }

  Future<void> _openPreview() async {
    if (_openingPreview) return;
    setState(() {
      _openingPreview = true;
      _previewError = null;
    });
    try {
      final store = widget.previewStore ?? await LocalTaskStore.open();
      if (!mounted) {
        if (store != widget.previewStore) await store.dispose();
        return;
      }
      setState(() {
        _store = store;
        _preview = true;
        _workspace = GlobalKey<WorkspaceState>();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _previewError =
              'The local preview could not load. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _openingPreview = false);
    }
  }

  Future<void> _signOut() async {
    _navigator.currentState?.popUntil((r) => r.isFirst);
    if (_preview) {
      final old = _store;
      setState(() {
        _store = null;
        _preview = false;
      });
      if (old != null && old != widget.previewStore) await old.dispose();
    } else {
      await widget.notifications?.clearForSignOut();
      await widget.auth!.signOut();
    }
  }

  void _scheduleTaps() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_handleTaps());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _handleTaps() async {
    if (_handlingTap || _user == null || _preview || _store == null) return;
    _handlingTap = true;
    try {
      while (mounted &&
          _user != null &&
          !_preview &&
          (widget.notifications?.hasPending ?? false)) {
        final intent = widget.notifications!.takeNext()!;
        final uid = _user!.uid;
        if (!intent.belongsTo(uid)) continue;
        final store = _store!;
        _navigator.currentState?.popUntil((r) => r.isFirst);
        _workspace.currentState?.showTasks();
        if (intent.taskId == null) continue;
        try {
          final task = await store.get(intent.taskId!);
          if (!mounted || _user?.uid != uid || _preview) continue;
          final nav = _navigator.currentState;
          if (nav == null) continue;
          if (task == null) {
            showNotice(nav.context, 'This task is no longer available.');
          } else {
            unawaited(
              nav.push(
                MaterialPageRoute<void>(
                  builder: (_) => TaskDetail(store: store, id: task.id),
                ),
              ),
            );
          }
        } catch (_) {
          if (mounted && _user?.uid == uid) {
            final context = _navigator.currentContext;
            if (context != null && context.mounted) {
              showNotice(
                context,
                'Could not open this task. Please check your connection.',
              );
            }
          }
        }
      }
    } finally {
      _handlingTap = false;
    }
  }

  @override
  void dispose() {
    widget.notifications?.removeListener(_scheduleTaps);
    unawaited(_authSubscription?.cancel());
    if (_store != null && _store != widget.previewStore) {
      unawaited(_store!.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Taskpilot',
    debugShowCheckedModeBanner: false,
    theme: Brand.theme,
    navigatorKey: _navigator,
    home: !_ready
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _store != null
        ? Workspace(
            key: _workspace,
            store: _store!,
            name: _preview
                ? 'Preview explorer'
                : (_user?.displayName ?? 'Your workspace'),
            email: _preview ? 'Saved on this device' : (_user?.email ?? ''),
            onSignOut: _signOut,
            notifications: _preview ? null : widget.notifications,
          )
        : widget.setupRequired
        ? Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandLogo(),
                        const SizedBox(height: 40),
                        Text(
                          'Welcome to Taskpilot',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your app is ready for Firebase setup. Follow docs/FIREBASE_SETUP.md in the project, then rebuild.',
                        ),
                        const SizedBox(height: 24),
                        BusyButton(
                          busy: _openingPreview,
                          onPressed: _openPreview,
                          label: 'Explore the local preview',
                        ),
                        if (_previewError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(_previewError!),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : AuthPage(
            auth: widget.auth,
            onPreview: widget.auth == null ? _openPreview : null,
          ),
  );
}
