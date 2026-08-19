import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/task_entity.dart';

/// Local-only sync bookkeeping. Never sent to Firestore and never exposed
/// on [TaskEntity] — it's a data-layer concern.
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

class TaskModel extends TaskEntity {
  final SyncStatus syncStatus;

  /// Owning user's uid. Local-only stamping concern like [syncStatus] — not
  /// on [TaskEntity] — set by [TaskRepositoryImpl] from the signed-in user
  /// and used to scope every Firestore read/write to that user.
  final String userId;

  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.priority,
    required super.dueDate,
    required super.isCompleted,
    required super.createdAt,
    required this.syncStatus,
    required this.userId,
  });

  factory TaskModel.fromEntity(
    TaskEntity entity, {
    required String userId,
    SyncStatus syncStatus = SyncStatus.synced,
  }) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      priority: entity.priority,
      dueDate: entity.dueDate,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      syncStatus: syncStatus,
      userId: userId,
    );
  }

  TaskModel copyWithSyncStatus(SyncStatus status) =>
      TaskModel.fromEntity(this, syncStatus: status, userId: userId);

  // ---- Hive (local) ----

  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      priority: TaskPriorityX.fromStorageValue(map['priority'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      isCompleted: map['isCompleted'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.name == map['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      userId: map['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.storageValue,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'syncStatus': syncStatus.name,
        'userId': userId,
      };

  // ---- Firestore (remote) ----

  factory TaskModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      priority: TaskPriorityX.fromStorageValue(
        data['priority'] as String? ?? TaskPriority.medium.storageValue,
      ),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      // Anything pulled fresh from Firestore is, by definition, in sync.
      syncStatus: SyncStatus.synced,
      userId: data['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'priority': priority.storageValue,
        'dueDate': Timestamp.fromDate(dueDate),
        'isCompleted': isCompleted,
        'createdAt': Timestamp.fromDate(createdAt),
        'userId': userId,
      };
}
