import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import 'task_store.dart';

class FirestoreTaskStore implements TaskStore {
  FirestoreTaskStore(String uid)
    : _ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks');
  final CollectionReference<Map<String, dynamic>> _ref;
  Task _decode(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Task(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      priority: TaskPriority.values.byName(data['priority'] as String),
      completed: data['completed'] as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, Object?> _editable(Task task) => {
    'title': task.title.trim(),
    'description': task.description.trim(),
    'dueDate': Timestamp.fromDate(task.dueDate),
    'priority': task.priority.name,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  @override
  Stream<List<Task>> watch() =>
      _ref.snapshots().map((s) => s.docs.map(_decode).toList());
  @override
  Future<Task?> get(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? _decode(doc) : null;
  }

  @override
  Future<void> create(Task task) => _ref.doc(task.id).set({
    ..._editable(task),
    'completed': task.completed,
    'createdAt': FieldValue.serverTimestamp(),
  });
  @override
  Future<void> update(Task task) => _ref.doc(task.id).update(_editable(task));
  @override
  Future<void> setCompleted(String id, bool completed) => _ref.doc(id).update({
    'completed': completed,
    'updatedAt': FieldValue.serverTimestamp(),
  });
  @override
  Future<void> delete(String id) => _ref.doc(id).delete();
  @override
  Future<void> dispose() async {}
}
