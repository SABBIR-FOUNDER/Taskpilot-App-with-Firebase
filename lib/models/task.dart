enum TaskPriority { low, medium, high }

enum TaskFilter { all, pending, completed }

enum TaskSort { dueDate, newest, priority }

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.completed,
    required this.createdAt,
  });
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool completed;
  final DateTime createdAt;

  bool isOverdue(DateTime now) =>
      !completed &&
      DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      ).isBefore(DateTime(now.year, now.month, now.day));

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? completed,
  }) => Task(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    dueDate: dueDate ?? this.dueDate,
    priority: priority ?? this.priority,
    completed: completed ?? this.completed,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'priority': priority.name,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> data) => Task(
    id: data['id'] as String,
    title: data['title'] as String,
    description: data['description'] as String,
    dueDate: DateTime.parse(data['dueDate'] as String),
    priority: TaskPriority.values.byName(data['priority'] as String),
    completed: data['completed'] as bool,
    createdAt: DateTime.parse(data['createdAt'] as String),
  );
}

List<Task> selectTasks(
  Iterable<Task> tasks, {
  String query = '',
  TaskFilter filter = TaskFilter.all,
  TaskPriority? priority,
  TaskSort sort = TaskSort.dueDate,
}) {
  final text = query.trim().toLowerCase();
  final result = tasks
      .where(
        (t) =>
            (filter == TaskFilter.all ||
                (filter == TaskFilter.completed) == t.completed) &&
            (priority == null || t.priority == priority) &&
            ('${t.title} ${t.description}'.toLowerCase().contains(text)),
      )
      .toList();
  result.sort((a, b) {
    final order = switch (sort) {
      TaskSort.dueDate => a.dueDate.compareTo(b.dueDate),
      TaskSort.newest => b.createdAt.compareTo(a.createdAt),
      TaskSort.priority => b.priority.index.compareTo(a.priority.index),
    };
    return order != 0 ? order : a.id.compareTo(b.id);
  });
  return result;
}
