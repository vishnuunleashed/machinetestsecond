import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme_mode_notifier.dart';
import '../../../auth/presentation/providers/auth_form_notifier.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_list_filter.dart';
import '../providers/task_list_notifier.dart';
import '../providers/task_list_state.dart';
import 'add_edit_task_page.dart';
import 'task_details_page.dart';

/// Deliberately not built on BaseView: it needs search + filter chips +
/// sort control + sync indicator + list all visible together, which
/// doesn't fit BaseView's single-body-swap model. It reimplements the same
/// loading/error/content branch directly.
class TaskListPage extends ConsumerWidget {
  static const routeName = '/';

  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskListNotifierProvider);
    final notifier = ref.read(taskListNotifierProvider.notifier);
    final themeMode = ref.watch(themeModeNotifierProvider);

    ref.listen(taskListNotifierProvider.select((s) => s.errorMessage),
        (previous, next) {
      if (next != null && next != previous) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          if (state.isSyncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync now',
              onPressed: notifier.syncNow,
            ),
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Theme',
            initialValue: themeMode,
            onSelected: (mode) => ref
                .read(themeModeNotifierProvider.notifier)
                .setThemeMode(mode),
            itemBuilder: (context) => [
              _themeMenuItem(ThemeMode.light, 'Light', themeMode),
              _themeMenuItem(ThemeMode.dark, 'Dark', themeMode),
              _themeMenuItem(ThemeMode.system, 'System', themeMode),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authFormNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, state, notifier)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditTaskPage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  PopupMenuItem<ThemeMode> _themeMenuItem(
    ThemeMode mode,
    String label,
    ThemeMode current,
  ) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            mode == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TaskListState state,
    TaskListNotifier notifier,
  ) {
    if (state.isLoading && !state.hasAnyTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: notifier.syncNow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: notifier.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search tasks',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: TaskFilter.values.map((f) {
                      return ChoiceChip(
                        label: Text(f.label),
                        selected: state.filter == f,
                        onSelected: (_) => notifier.setFilter(f),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<TaskSortOption>(
                  value: state.sortBy,
                  underline: const SizedBox.shrink(),
                  items: TaskSortOption.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) notifier.setSortBy(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: state.filteredTasks.isEmpty
                ? _EmptyState(
                    hasAnyTasks: state.hasAnyTasks,
                    isFiltered: state.searchQuery.isNotEmpty ||
                        state.filter != TaskFilter.all,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                    itemCount: state.filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = state.filteredTasks[index];
                      return _TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: (value) =>
                            notifier.toggleCompletion(task.id, value),
                        onDelete: () => notifier.deleteTask(task.id),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskDetailsPage(task: task),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasAnyTasks;
  final bool isFiltered;

  const _EmptyState({required this.hasAnyTasks, required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noTasksAtAll = !hasAnyTasks;
    final message = noTasksAtAll
        ? 'No tasks yet — tap + to add your first one.'
        : 'No tasks match your search or filter.';
    final icon = noTasksAtAll ? Icons.task_alt : Icons.filter_alt_off;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskEntity task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  Color _priorityColor(BuildContext context) => switch (task.priority) {
        TaskPriority.high => Theme.of(context).colorScheme.error,
        TaskPriority.medium => Colors.orange,
        TaskPriority.low => Colors.green,
      };

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());
    final dateFormat = DateFormat.yMMMd();
    final errorColor = Theme.of(context).colorScheme.error;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration:
            BoxDecoration(color: errorColor, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          onTap: onTap,
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) => onToggle(value ?? false),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _priorityColor(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(task.priority.label),
              const SizedBox(width: 12),
              Icon(Icons.event, size: 14, color: isOverdue ? errorColor : null),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(task.dueDate),
                style: TextStyle(color: isOverdue ? errorColor : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
