import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/task_store.dart';
import '../models/task.dart';
import 'common.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, required this.store, this.task});
  final TaskStore store;
  final Task? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title ?? '');
  late final _description = TextEditingController(
    text: widget.task?.description ?? '',
  );
  late DateTime _due =
      widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  bool _busy = false, _dirty = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final now = DateTime.now();
    final task = Task(
      id: widget.task?.id ?? '${now.microsecondsSinceEpoch}',
      title: _title.text.trim(),
      description: _description.text.trim(),
      dueDate: DateTime(_due.year, _due.month, _due.day),
      priority: _priority,
      completed: widget.task?.completed ?? false,
      createdAt: widget.task?.createdAt ?? now,
    );
    try {
      if (widget.task == null) {
        await widget.store.create(task);
      } else {
        await widget.store.update(task);
      }
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _busy = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error =
              'Could not save this task. Check your connection and try again.';
        });
      }
    }
  }

  Future<void> _leave() async {
    if (_busy) return;
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _leave,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.task == null ? 'New task' : 'Edit task'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _form,
              onChanged: () {
                if (!_dirty) setState(() => _dirty = true);
              },
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    widget.task == null
                        ? 'Make the next step clear.'
                        : 'Fine-tune your plan.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A specific task is easier to start.',
                    style: TextStyle(color: Brand.muted),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _title,
                    enabled: !_busy,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                      hintText: 'e.g. Complete the Flutter assignment',
                    ),
                    validator: validateTitle,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    enabled: !_busy,
                    maxLength: 2000,
                    minLines: 4,
                    maxLines: 7,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add useful details or a first step',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'DUE DATE',
                    style: TextStyle(
                      color: Brand.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_month_outlined,
                        color: Brand.indigo,
                      ),
                      title: Text(formatDate(_due)),
                      trailing: const Icon(Icons.expand_more),
                      onTap: _busy
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _due,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100, 12, 31),
                              );
                              if (date != null && mounted) {
                                setState(() {
                                  _due = date;
                                  _dirty = true;
                                });
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PRIORITY',
                    style: TextStyle(
                      color: Brand.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: TaskPriority.values
                        .map(
                          (p) => ChoiceChip(
                            selected: _priority == p,
                            label: Text(
                              p.name[0].toUpperCase() + p.name.substring(1),
                            ),
                            onSelected: _busy
                                ? null
                                : (_) => setState(() {
                                    _priority = p;
                                    _dirty = true;
                                  }),
                          ),
                        )
                        .toList(),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Brand.danger),
                      ),
                    ),
                  const SizedBox(height: 32),
                  BusyButton(
                    busy: _busy,
                    label: widget.task == null ? 'Create task' : 'Save changes',
                    onPressed: _save,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
