import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/base_notifier.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/sync_tasks_now.dart';
import '../../domain/usecases/toggle_task_completion.dart';
import '../../domain/usecases/watch_sync_status.dart';
import '../../domain/usecases/watch_tasks.dart';
import 'task_list_filter.dart';
import 'task_list_state.dart';

final taskListNotifierProvider =
    NotifierProvider<TaskListNotifier, TaskListState>(TaskListNotifier.new);

/// Drives the task list screen. The task data itself is reactive (backed by
/// a Hive watch stream via [WatchTasks]) rather than a one-shot fetch, so
/// [loadingState]/[errorState] exist only to satisfy [BaseNotifier] — the
/// list's real loading/error signal comes from the stream subscriptions set
/// up in [build], not from [guard].
class TaskListNotifier extends BaseNotifier<TaskListState> {
  late final WatchTasks _watchTasks;
  late final WatchSyncStatus _watchSyncStatus;
  late final DeleteTask _deleteTask;
  late final ToggleTaskCompletion _toggleTaskCompletion;
  late final SyncTasksNow _syncTasksNow;

  @override
  TaskListState build() {
    _watchTasks = sl<WatchTasks>();
    _watchSyncStatus = sl<WatchSyncStatus>();
    _deleteTask = sl<DeleteTask>();
    _toggleTaskCompletion = sl<ToggleTaskCompletion>();
    _syncTasksNow = sl<SyncTasksNow>();

    final tasksSub = _watchTasks(const NoParams()).listen(_onTasksChanged);
    final syncSub = _watchSyncStatus(const NoParams()).listen(_onSyncChanged);
    ref.onDispose(() {
      tasksSub.cancel();
      syncSub.cancel();
    });

    return const TaskListState.initial();
  }

  @override
  TaskListState loadingState(TaskListState current) => current;

  @override
  TaskListState errorState(TaskListState current, String message) =>
      current.copyWith(isLoading: false, errorMessage: message);

  void _onTasksChanged(List<TaskEntity> tasks) {
    final next = state.copyWith(isLoading: false, allTasks: tasks);
    state = next.copyWith(filteredTasks: _applyFilters(tasks, next));
  }

  void _onSyncChanged(bool syncing) {
    state = state.copyWith(isSyncing: syncing);
  }

  void setSearchQuery(String query) {
    final next = state.copyWith(searchQuery: query);
    state = next.copyWith(filteredTasks: _applyFilters(state.allTasks, next));
  }

  void setFilter(TaskFilter filter) {
    final next = state.copyWith(filter: filter);
    state = next.copyWith(filteredTasks: _applyFilters(state.allTasks, next));
  }

  void setSortBy(TaskSortOption sortBy) {
    final next = state.copyWith(sortBy: sortBy);
    state = next.copyWith(filteredTasks: _applyFilters(state.allTasks, next));
  }

  /// Pure list transform — search/filter/sort all happen over the in-memory
  /// (Hive-sourced) list, never touching Firestore.
  List<TaskEntity> _applyFilters(
    List<TaskEntity> tasks,
    TaskListState criteria,
  ) {
    final query = criteria.searchQuery.trim().toLowerCase();

    final result = tasks.where((t) {
      final matchesQuery =
          query.isEmpty || t.title.toLowerCase().contains(query);
      final matchesFilter = switch (criteria.filter) {
        TaskFilter.all => true,
        TaskFilter.completed => t.isCompleted,
        TaskFilter.pending => !t.isCompleted,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    result.sort((a, b) => switch (criteria.sortBy) {
          TaskSortOption.dueDate => a.dueDate.compareTo(b.dueDate),
          TaskSortOption.priority =>
            b.priority.index.compareTo(a.priority.index),
        });

    return result;
  }

  Future<void> deleteTask(String id) async {
    final result = await _deleteTask(id);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {},
    );
  }

  Future<void> toggleCompletion(String id, bool isCompleted) async {
    final result = await _toggleTaskCompletion(
      ToggleTaskCompletionParams(id: id, isCompleted: isCompleted),
    );
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {},
    );
  }

  Future<void> syncNow() async {
    final result = await _syncTasksNow(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {},
    );
  }
}
