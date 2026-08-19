import 'package:equatable/equatable.dart';

import '../../../../core/presentation/base_state.dart';
import '../../domain/entities/task_entity.dart';
import 'task_list_filter.dart';

class TaskListState extends Equatable implements BaseState {
  @override
  final bool isLoading;
  @override
  final String? errorMessage;
  final List<TaskEntity> allTasks;
  final List<TaskEntity> filteredTasks;
  final String searchQuery;
  final TaskFilter filter;
  final TaskSortOption sortBy;
  final bool isSyncing;

  const TaskListState({
    required this.isLoading,
    this.errorMessage,
    required this.allTasks,
    required this.filteredTasks,
    required this.searchQuery,
    required this.filter,
    required this.sortBy,
    required this.isSyncing,
  });

  /// Starts loading — the first emission from the Hive-backed watch stream
  /// flips this off, whether or not there turn out to be any tasks.
  const TaskListState.initial()
      : isLoading = true,
        errorMessage = null,
        allTasks = const [],
        filteredTasks = const [],
        searchQuery = '',
        filter = TaskFilter.all,
        sortBy = TaskSortOption.dueDate,
        isSyncing = false;

  TaskListState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<TaskEntity>? allTasks,
    List<TaskEntity>? filteredTasks,
    String? searchQuery,
    TaskFilter? filter,
    TaskSortOption? sortBy,
    bool? isSyncing,
  }) {
    return TaskListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sortBy: sortBy ?? this.sortBy,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  bool get hasAnyTasks => allTasks.isNotEmpty;

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        allTasks,
        filteredTasks,
        searchQuery,
        filter,
        sortBy,
        isSyncing,
      ];
}
