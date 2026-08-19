import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/base_notifier.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/update_task.dart';
import 'add_edit_task_state.dart';

final addEditTaskNotifierProvider =
    NotifierProvider<AddEditTaskNotifier, AddEditTaskState>(
        AddEditTaskNotifier.new);

/// Deliberately not used with [BaseView]: a failed submit must never wipe
/// out the form the user just filled in, so [AddEditTaskPage] keeps its own
/// Scaffold/Form and just reacts to [isLoading]/[errorMessage]/[isSuccess].
class AddEditTaskNotifier extends BaseNotifier<AddEditTaskState> {
  late final CreateTask _createTask;
  late final UpdateTask _updateTask;

  @override
  AddEditTaskState build() {
    _createTask = sl<CreateTask>();
    _updateTask = sl<UpdateTask>();
    return const AddEditTaskState.initial();
  }

  @override
  AddEditTaskState loadingState(AddEditTaskState current) =>
      current.copyWith(isLoading: true, clearError: true, isSuccess: false);

  @override
  AddEditTaskState errorState(AddEditTaskState current, String message) =>
      current.copyWith(isLoading: false, errorMessage: message);

  Future<void> submit(TaskEntity task, {required bool isEditing}) {
    return guard(
      () => isEditing ? _updateTask(task) : _createTask(task),
      (current, _) =>
          current.copyWith(isLoading: false, isSuccess: true, clearError: true),
    );
  }
}
