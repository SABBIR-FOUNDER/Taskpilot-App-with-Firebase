import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/task_store.dart';
import '../models/task.dart';
import '../services/notifications.dart';
import 'common.dart';
import 'settings_page.dart';
import 'task_detail.dart';
import 'task_editor.dart';

class Workspace extends StatefulWidget {
  const Workspace({
    super.key,
    required this.store,
    required this.name,
    required this.email,
    required this.onSignOut,
    this.notifications,
  });
  final TaskStore store;
  final String name, email;
  final Future<void> Function() onSignOut;
  final TaskpilotNotifications? notifications;
  @override
  State<Workspace> createState() => WorkspaceState();
}

class WorkspaceState extends State<Workspace> {
  late Stream<List<Task>> _stream = widget.store.watch();
  final _search = TextEditingController();
  final Set<String> _busy = {};
  int _tab = 0;
  TaskFilter _filter = TaskFilter.all;
  TaskPriority? _priority;
  TaskSort _sort = TaskSort.dueDate;
  void showTasks() {
    if (mounted) setState(() => _tab = 0);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit([Task? task]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditor(store: widget.store, task: task),
      ),
    );
    if (saved == true && mounted) {
      showNotice(context, task == null ? 'Task created.' : 'Changes saved.');
    }
  }

  Future<void> _action(Task task, Future<void> Function() operation) async {
    if (_busy.contains(task.id)) return;
    setState(() => _busy.add(task.id));
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        showNotice(
          context,
          'Could not update the task. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(task.id));
    }
  }

  Widget _card(Task task) {
    final overdue = task.isOverdue(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TaskDetail(id: task.id, store: widget.store),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 10, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                semanticLabel: task.completed
                    ? 'Mark ${task.title} as pending'
                    : 'Complete ${task.title}',
                value: task.completed,
                onChanged: _busy.contains(task.id)
                    ? null
                    : (value) => _action(
                        task,
                        () =>
                            widget.store.setCompleted(task.id, value ?? false),
                      ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.completed ? Brand.muted : Brand.navy,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Brand.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriorityPill(task.priority),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: overdue ? Brand.danger : Brand.muted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${overdue ? 'Overdue · ' : ''}${formatDate(task.dueDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: overdue ? Brand.danger : Brand.muted,
                              ),
                            ),
                          ],
                        ),
                        if (task.completed)
                          const Text(
                            'Completed',
                            style: TextStyle(
                              color: Color(0xFF087D65),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Task actions',
                enabled: !_busy.contains(task.id),
                onSelected: (value) async {
                  if (value == 'edit') _edit(task);
                  if (value == 'delete') {
                    final confirmed = await confirmDelete(context, task.title);
                    if (confirmed == true && mounted) {
                      _action(task, () => widget.store.delete(task.id));
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit task')),
                  PopupMenuItem(value: 'delete', child: Text('Delete task')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskPage() => StreamBuilder<List<Task>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: Brand.muted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tasks could not be loaded. Check your connection or Firestore access.',
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      setState(() => _stream = widget.store.watch()),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final all = snapshot.data!;
      final completed = all.where((t) => t.completed).length;
      final pending = all.length - completed;
      final visible = selectTasks(
        all,
        query: _search.text,
        filter: _filter,
        priority: _priority,
        sort: _sort,
      );
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your day, in focus.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome, ${widget.name.split(' ').first}. Make space for what matters.',
                    style: const TextStyle(color: Brand.muted),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Brand.navy,
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/brand/welcome_background.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'A LITTLE PROGRESS, EVERY DAY',
                          style: TextStyle(
                            color: Brand.mint,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pending == 0
                              ? 'Room for your next idea.'
                              : '$pending ${pending == 1 ? 'task' : 'tasks'} to move forward.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        LinearProgressIndicator(
                          value: all.isEmpty ? 0 : completed / all.length,
                          backgroundColor: const Color(0xFF39445A),
                          color: Brand.mint,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$completed of ${all.length} tasks completed',
                          style: const TextStyle(
                            color: Color(0xFFDDE5F5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.notifications == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'LOCAL PREVIEW · Saved on this device',
                        style: TextStyle(
                          fontSize: 11,
                          color: Brand.muted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search your tasks',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskFilter.values
                        .map(
                          (f) => ChoiceChip(
                            label: Text(switch (f) {
                              TaskFilter.all => 'All (${all.length})',
                              TaskFilter.pending => 'Pending ($pending)',
                              TaskFilter.completed => 'Completed ($completed)',
                            }),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PopupMenuButton<TaskSort>(
                        tooltip: 'Sort tasks',
                        onSelected: (s) => setState(() => _sort = s),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: TaskSort.dueDate,
                            child: Text('Due date'),
                          ),
                          PopupMenuItem(
                            value: TaskSort.newest,
                            child: Text('Newest first'),
                          ),
                          PopupMenuItem(
                            value: TaskSort.priority,
                            child: Text('Highest priority'),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 6,
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(Icons.sort, size: 19),
                              const SizedBox(width: 7),
                              Text(switch (_sort) {
                                TaskSort.dueDate => 'Due date',
                                TaskSort.newest => 'Newest',
                                TaskSort.priority => 'Priority',
                              }),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Filter by priority',
                        onSelected: (p) => setState(
                          () => _priority = p == 'all'
                              ? null
                              : TaskPriority.values.byName(p),
                        ),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'all',
                            child: Text('All priorities'),
                          ),
                          PopupMenuItem(value: 'high', child: Text('High')),
                          PopupMenuItem(value: 'medium', child: Text('Medium')),
                          PopupMenuItem(value: 'low', child: Text('Low')),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 6,
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(Icons.flag_outlined, size: 19),
                              const SizedBox(width: 7),
                              Text(
                                _priority == null
                                    ? 'All priorities'
                                    : '${_priority!.name} priority',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.task_alt_rounded,
                      size: 58,
                      color: Brand.indigo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      all.isEmpty
                          ? 'Your next step starts here.'
                          : 'No matching tasks.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      all.isEmpty
                          ? 'Create one small task to get moving.'
                          : 'Try another search or filter.',
                      style: const TextStyle(color: Brand.muted),
                    ),
                    if (all.isEmpty) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _edit(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create your first task'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, i) => _card(visible[i]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    },
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final wide = bounds.maxWidth >= 900;
      final content = _tab == 0
          ? _taskPage()
          : SettingsPage(
              name: widget.name,
              email: widget.email,
              onSignOut: widget.onSignOut,
              notifications: widget.notifications,
            );
      return Scaffold(
        appBar: AppBar(
          title: const BrandLogo(size: 32),
          actions: [
            if (_tab == 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  tooltip: 'Your workspace',
                  onPressed: () => setState(() => _tab = 1),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.checklist_rounded),
                      label: Text('Tasks'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tune_rounded),
                      label: Text('Workspace'),
                    ),
                  ],
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.checklist_rounded),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_rounded),
                    label: 'Workspace',
                  ),
                ],
              ),
        floatingActionButton: _tab == 0
            ? FloatingActionButton.extended(
                onPressed: () => _edit(),
                backgroundColor: Brand.indigo,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('New task'),
              )
            : null,
      );
    },
  );
}
