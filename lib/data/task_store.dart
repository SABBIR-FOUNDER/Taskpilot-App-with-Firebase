import '../models/task.dart';

abstract class TaskStore {
  Stream<List<Task>> watch();
  Future<Task?> get(String id);
  Future<void> create(Task task);
  Future<void> update(Task task);
  Future<void> setCompleted(String id, bool completed);
  Future<void> delete(String id);
  Future<void> dispose();
}
