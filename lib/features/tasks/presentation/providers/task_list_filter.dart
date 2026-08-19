/// Display-only concerns — how the list is currently viewed, not a domain
/// rule — so these live in presentation rather than domain.
enum TaskFilter { all, completed, pending }

extension TaskFilterX on TaskFilter {
  String get label => switch (this) {
        TaskFilter.all => 'All',
        TaskFilter.completed => 'Completed',
        TaskFilter.pending => 'Pending',
      };
}

enum TaskSortOption { dueDate, priority }

extension TaskSortOptionX on TaskSortOption {
  String get label => switch (this) {
        TaskSortOption.dueDate => 'Due date',
        TaskSortOption.priority => 'Priority',
      };
}
