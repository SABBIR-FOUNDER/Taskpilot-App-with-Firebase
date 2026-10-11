import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'task_store.dart';

class LocalTaskStore implements TaskStore {
  LocalTaskStore._(this._prefs, this._tasks);
  final SharedPreferencesAsync _prefs;
  List<Task> _tasks;
  final _changes = StreamController<List<Task>>.broadcast();
  Future<void> _writes = Future.value();
  static const _key = 'taskpilot_preview_tasks_v1';

  static Future<LocalTaskStore> open() async {
    final prefs = SharedPreferencesAsync();
    final saved = await prefs.getString(_key);
    if (saved != null) {
      final rows = jsonDecode(saved) as List;
      return LocalTaskStore._(
        prefs,
        rows
            .map((v) => Task.fromJson(Map<String, dynamic>.from(v as Map)))
            .toList(),
      );
    }
    final now = DateTime.now();
    final store = LocalTaskStore._(prefs, [
      Task(
        id: 'preview-plan',
        title: 'Plan the week ahead',
        description:
            'Choose three priorities and give each one a realistic due date.',
        dueDate: now.add(const Duration(days: 1)),
        priority: TaskPriority.high,
        completed: false,
        createdAt: now,
      ),
      Task(
        id: 'preview-flutter',
        title: 'Finish the Flutter assignment',
        description:
            'Build, connect Firebase, and test notifications in every app state.',
        dueDate: now.add(const Duration(days: 3)),
        priority: TaskPriority.high,
        completed: false,
        createdAt: now,
      ),
      Task(
        id: 'preview-notes',
        title: 'Organize workshop notes',
        description: 'A little clarity makes tomorrow easier.',
        dueDate: now.add(const Duration(days: 5)),
        priority: TaskPriority.low,
        completed: false,
        createdAt: now,
      ),
      Task(
        id: 'preview-start',
        title: 'Create a clear task list',
        description: 'You are already moving forward.',
        dueDate: now,
        priority: TaskPriority.medium,
        completed: true,
        createdAt: now,
      ),
    ]);
    await prefs.setString(
      _key,
      jsonEncode(store._tasks.map((t) => t.toJson()).toList()),
    );
    return store;
  }

  @override
  Stream<List<Task>> watch() async* {
    yield List.unmodifiable(_tasks);
    yield* _changes.stream;
  }

  @override
  Future<Task?> get(String id) async {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<void> _mutate(List<Task> Function(List<Task>) action) {
    final result = _writes.then((_) async {
      final next = action(List.of(_tasks));
      await _prefs.setString(
        _key,
        jsonEncode(next.map((t) => t.toJson()).toList()),
      );
      _tasks = next;
      if (!_changes.isClosed) _changes.add(List.unmodifiable(_tasks));
    });
    _writes = result.catchError((Object _) {});
    return result;
  }

  @override
  Future<void> create(Task task) => _mutate((tasks) {
    if (tasks.any((t) => t.id == task.id)) {
      throw StateError('This task already exists.');
    }
    return [...tasks, task];
  });
  @override
  Future<void> update(Task task) => _mutate((tasks) {
    if (!tasks.any((t) => t.id == task.id)) {
      throw StateError('This task was removed.');
    }
    return tasks
        .map((t) => t.id == task.id ? task.copyWith(completed: t.completed) : t)
        .toList();
  });
  @override
  Future<void> setCompleted(String id, bool completed) => _mutate(
    (tasks) => tasks
        .map((t) => t.id == id ? t.copyWith(completed: completed) : t)
        .toList(),
  );
  @override
  Future<void> delete(String id) =>
      _mutate((tasks) => tasks.where((t) => t.id != id).toList());
  @override
  Future<void> dispose() async {
    await _writes;
    await _changes.close();
  }
}
