import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/task_store.dart';
import '../models/task.dart';
import 'common.dart';
import 'task_editor.dart';

class TaskDetail extends StatefulWidget {
  const TaskDetail({super.key, required this.id, required this.store});
  final String id;
  final TaskStore store;
  @override
  State<TaskDetail> createState() => _TaskDetailState();
}

class _TaskDetailState extends State<TaskDetail> {
  late final _stream = widget.store.watch();
  bool _busy = false;
  Future<void> _delete(Task task) async {
    final yes = await confirmDelete(context, task.title);
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.store.delete(task.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showNotice(context, 'Could not delete the task. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Task details')),
    body: StreamBuilder<List<Task>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('This task could not be loaded.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final matches = snapshot.data!.where((t) => t.id == widget.id);
        if (matches.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This task has been removed or is not available in this account.',
              ),
            ),
          );
        }
        final task = matches.first;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: PriorityPill(task.priority),
                ),
                const SizedBox(height: 20),
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  task.description.isEmpty
                      ? 'No description added.'
                      : task.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Due date'),
                        subtitle: Text(formatDate(task.dueDate)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Created'),
                        subtitle: Text(formatDate(task.createdAt)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(
                          task.completed ? 'Completed' : 'Mark as completed',
                        ),
                        value: task.completed,
                        onChanged: _busy
                            ? null
                            : (value) async {
                                setState(() => _busy = true);
                                try {
                                  await widget.store.setCompleted(
                                    task.id,
                                    value,
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    showNotice(
                                      context,
                                      'Could not update this task.',
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _busy = false);
                                }
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TaskEditor(store: widget.store, task: task),
                          ),
                        ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit task'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _delete(task),
                  icon: const Icon(Icons.delete_outline, color: Brand.danger),
                  label: const Text(
                    'Delete task',
                    style: TextStyle(color: Brand.danger),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: task.id));
                    if (context.mounted) showNotice(context, 'Task ID copied.');
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy task ID'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<bool?> confirmDelete(BuildContext context, String title) =>
    showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text('“$title” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
