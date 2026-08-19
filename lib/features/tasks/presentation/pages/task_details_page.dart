import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_list_notifier.dart';
import 'add_edit_task_page.dart';

/// Takes the entity directly rather than re-fetching by id — the caller
/// already has it loaded. Stays live by re-selecting the same id out of
/// [taskListNotifierProvider] so edits/toggles made elsewhere are reflected
/// without this screen needing its own notifier.
class TaskDetailsPage extends ConsumerWidget {
  final TaskEntity task;

  const TaskDetailsPage({super.key, required this.task});

  TaskEntity? _findById(List<TaskEntity> tasks, String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
    if (confirmed == true) {
      await ref.read(taskListNotifierProvider.notifier).deleteTask(task.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveTasks =
        ref.watch(taskListNotifierProvider.select((s) => s.allTasks));
    final current = _findById(liveTasks, task.id) ?? task;

    final dateFormat = DateFormat.yMMMd();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditTaskPage(task: current),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    current.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                Switch(
                  value: current.isCompleted,
                  onChanged: (val) => ref
                      .read(taskListNotifierProvider.notifier)
                      .toggleCompletion(current.id, val),
                ),
              ],
            ),
            Text(
              current.isCompleted ? 'Completed' : 'Pending',
              style: theme.textTheme.labelLarge?.copyWith(
                color: current.isCompleted
                    ? Colors.green
                    : theme.colorScheme.outline,
              ),
            ),
            const Divider(height: 32),
            Text('Description', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              current.description.isEmpty
                  ? 'No description'
                  : current.description,
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Priority', value: current.priority.label),
            _DetailRow(
              label: 'Due date',
              value: dateFormat.format(current.dueDate),
            ),
            _DetailRow(
              label: 'Created',
              value: dateFormat.format(current.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
