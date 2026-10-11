import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskpilot/core/theme.dart';
import 'package:taskpilot/data/task_store.dart';
import 'package:taskpilot/models/task.dart';
import 'package:taskpilot/ui/auth_page.dart';
import 'package:taskpilot/ui/workspace.dart';
import 'package:taskpilot/ui/task_editor.dart';
import 'package:taskpilot/ui/settings_page.dart';
import 'package:taskpilot/services/notifications.dart';

class MemoryStore implements TaskStore {
  final rows = <Task>[];
  final changes = StreamController<List<Task>>.broadcast();
  bool failWrites = false;
  void emit() => changes.add(List.of(rows));
  @override
  Stream<List<Task>> watch() async* {
    yield List.of(rows);
    yield* changes.stream;
  }

  @override
  Future<Task?> get(String id) async =>
      rows.where((t) => t.id == id).firstOrNull;
  @override
  Future<void> create(Task t) async {
    if (failWrites) throw StateError('offline');
    rows.add(t);
    emit();
  }

  @override
  Future<void> update(Task t) async {
    rows[rows.indexWhere((v) => v.id == t.id)] = t;
    emit();
  }

  @override
  Future<void> delete(String id) async {
    rows.removeWhere((t) => t.id == id);
    emit();
  }

  @override
  Future<void> setCompleted(String id, bool value) async {
    final i = rows.indexWhere((t) => t.id == id);
    rows[i] = rows[i].copyWith(completed: value);
    emit();
  }

  @override
  Future<void> dispose() async {
    await changes.close();
  }
}

Widget host(Widget child, {double scale = 1}) => MaterialApp(
  theme: Brand.theme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);
void main() {
  testWidgets('notification settings fit enlarged text on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notifications = TaskpilotNotifications();
    addTearDown(notifications.dispose);
    await tester.pumpWidget(
      host(
        SettingsPage(
          name: 'Test User',
          email: 'test@example.com',
          onSignOut: () async {},
          notifications: notifications,
        ),
        scale: 1.5,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('welcome fits narrow screens and large text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(AuthPage(onPreview: () {}), scale: 1.5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Taskpilot'), findsOneWidget);
  });
  testWidgets('editor validates, saves a task, and workspace can complete it', (
    tester,
  ) async {
    final store = MemoryStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      host(
        Workspace(
          store: store,
          name: 'Tester',
          email: 'test@example.com',
          onSignOut: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Create task'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    expect(store.rows, isEmpty);
    await tester.enterText(find.byType(TextFormField).first, 'Ship Taskpilot');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Create task'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    expect(store.rows.single.title, 'Ship Taskpilot');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(Checkbox),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(store.rows.single.completed, true);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed writes preserve the task form and show an error', (
    tester,
  ) async {
    final store = MemoryStore()..failWrites = true;
    addTearDown(store.dispose);
    await tester.pumpWidget(host(TaskEditor(store: store)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Keep this draft');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Create task'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Create task')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(store.rows, isEmpty);
  });
  testWidgets('workspace handles narrow layout and enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryStore();
    addTearDown(store.dispose);
    store.rows.add(
      Task(
        id: '1',
        title: 'A longer task title that wraps gracefully',
        description: 'Useful details',
        dueDate: DateTime(2025),
        priority: TaskPriority.high,
        completed: false,
        createdAt: DateTime(2025),
      ),
    );
    await tester.pumpWidget(
      host(
        Workspace(
          store: store,
          name: 'Tester',
          email: 'test@example.com',
          onSignOut: () async {},
        ),
        scale: 1.5,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
