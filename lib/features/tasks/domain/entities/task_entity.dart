import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
      };

  /// Stable string used in both Hive and Firestore so storage never breaks
  /// if the enum's declaration order changes.
  String get storageValue => name;

  static TaskPriority fromStorageValue(String value) {
    return TaskPriority.values.firstWhere(
      (p) => p.name == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Pure domain object for a task — no knowledge of Hive, Firestore, or
/// widgets. Sync bookkeeping lives on [TaskModel] in the data layer, not
/// here.
class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
    required this.createdAt,
  });

  TaskEntity copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return TaskEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, description, priority, dueDate, isCompleted, createdAt];
}
