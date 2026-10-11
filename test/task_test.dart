import 'package:flutter_test/flutter_test.dart';
import 'package:taskpilot/models/task.dart';
import 'package:taskpilot/models/notification_intent.dart';
import 'package:taskpilot/core/format.dart';

Task task(
  String id, {
  bool completed = false,
  TaskPriority priority = TaskPriority.medium,
  int day = 12,
}) => Task(
  id: id,
  title: 'Write $id',
  description: 'Flutter assignment',
  dueDate: DateTime(2026, 10, day),
  priority: priority,
  completed: completed,
  createdAt: DateTime(2026, 10, 10),
);
void main() {
  test('Task JSON round-trip preserves all fields', () {
    final original = task('a');
    expect(Task.fromJson(original.toJson()).toJson(), original.toJson());
  });
  test('copy preserves identity and created date', () {
    final original = task('a');
    final changed = original.copyWith(title: 'Changed', completed: true);
    expect(changed.id, original.id);
    expect(changed.createdAt, original.createdAt);
    expect(changed.completed, true);
  });
  test('due today is not overdue, completed tasks never overdue', () {
    expect(task('a', day: 11).isOverdue(DateTime(2026, 10, 11, 23)), false);
    expect(task('a', day: 10).isOverdue(DateTime(2026, 10, 11)), true);
    expect(
      task('a', day: 10, completed: true).isOverdue(DateTime(2026, 10, 11)),
      false,
    );
  });
  test('query, status and priority filters combine correctly', () {
    final tasks = [
      task('a', priority: TaskPriority.high),
      task('b', completed: true),
      task('c'),
    ];
    expect(
      selectTasks(
        tasks,
        query: ' FLUTTER ',
        filter: TaskFilter.pending,
        priority: TaskPriority.high,
      ).map((t) => t.id),
      ['a'],
    );
    expect(selectTasks(tasks, query: 'missing'), isEmpty);
    expect(selectTasks(tasks, filter: TaskFilter.completed).map((t) => t.id), [
      'b',
    ]);
  });
  test('sort uses due date or descending priority', () {
    final tasks = [
      task('late', day: 14),
      task('urgent', day: 13, priority: TaskPriority.high),
      task('first', day: 12),
    ];
    expect(selectTasks(tasks).first.id, 'first');
    expect(selectTasks(tasks, sort: TaskSort.priority).first.id, 'urgent');
  });
  test('notification payload retains task and owner', () {
    final intent = NotificationIntent.fromData({
      'taskId': 'task-1',
      'userId': 'user-1',
    });
    final restored = NotificationIntent.fromPayload(intent.toPayload());
    expect(restored.taskId, 'task-1');
    expect(restored.belongsTo('user-1'), true);
    expect(restored.belongsTo('user-2'), false);
  });
  test('bad notification payload falls back safely to task list', () {
    for (final value in [null, 'not json', '[]', '42', '{"taskId":"a/b"}']) {
      expect(NotificationIntent.fromPayload(value).taskId, isNull);
    }
    expect(NotificationIntent.fromData({'taskId': 12}).taskId, isNull);
  });
  test('form validation rejects blank titles and malformed email', () {
    expect(validateTitle('   '), isNotNull);
    expect(validateTitle('x' * 121), isNotNull);
    expect(validateTitle('Complete assignment'), isNull);
    expect(validateEmail('no-at-sign'), isNotNull);
    expect(validateEmail('person@example.com'), isNull);
  });
}
