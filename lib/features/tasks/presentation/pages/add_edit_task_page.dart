import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/add_edit_task_notifier.dart';

class AddEditTaskPage extends ConsumerStatefulWidget {
  static const routeName = '/task/edit';

  /// Null means "create"; a populated entity means "edit".
  final TaskEntity? task;

  const AddEditTaskPage({super.key, this.task});

  @override
  ConsumerState<AddEditTaskPage> createState() => _AddEditTaskPageState();
}

class _AddEditTaskPageState extends ConsumerState<AddEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  DateTime? _dueDate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Backdated due dates aren't selectable, for new tasks or edits — the
    // picker's range simply starts at today. An already-overdue task being
    // edited keeps its stored date shown as text unless the user opens the
    // picker and picks a new one, which can only be today or later.
    final initialDate =
        (_dueDate != null && !_dueDate!.isBefore(today)) ? _dueDate! : today;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;

    // Time defaults to 9:00 AM for a task that didn't have one yet — the
    // due-date reminder needs an actual time to fire at, not just a day.
    final initialTime = _dueDate != null
        ? TimeOfDay.fromDateTime(_dueDate!)
        : const TimeOfDay(hour: 9, minute: 0);
    final pickedTime =
        await showTimePicker(context: context, initialTime: initialTime);
    if (!mounted) return;

    final resolvedTime = pickedTime ?? initialTime;
    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        resolvedTime.hour,
        resolvedTime.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a due date')),
      );
      return;
    }

    final existing = widget.task;
    final task = TaskEntity(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      dueDate: _dueDate!,
      isCompleted: existing?.isCompleted ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    ref
        .read(addEditTaskNotifierProvider.notifier)
        .submit(task, isEditing: _isEditing);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(addEditTaskNotifierProvider, (previous, next) {
      if (next.isSuccess) {
        Navigator.of(context).pop();
      } else if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final state = ref.watch(addEditTaskNotifierProvider);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 20),
              Text('Priority', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: TaskPriority.values
                    .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                    .toList(),
                selected: {_priority},
                onSelectionChanged: (selection) =>
                    setState(() => _priority = selection.first),
              ),
              const SizedBox(height: 20),
              Text(
                'Due date & time',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate == null
                        ? 'Select a date and time'
                        : dateFormat.format(_dueDate!),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Create task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
