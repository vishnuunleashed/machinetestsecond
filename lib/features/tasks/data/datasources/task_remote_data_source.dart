import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  /// Only the signed-in user's tasks — see Firestore rules, which enforce
  /// the same scoping server-side.
  Future<List<TaskModel>> fetchAllTasks();

  Future<void> createTask(TaskModel task);

  Future<void> updateTask(TaskModel task);

  Future<void> deleteTask(String id);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  TaskRemoteDataSourceImpl({required this.firestore, required this.firebaseAuth});

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('tasks');

  @override
  Future<List<TaskModel>> fetchAllTasks() async {
    try {
      final uid = firebaseAuth.currentUser?.uid;
      if (uid == null) return const [];
      final snapshot =
          await _collection.where('userId', isEqualTo: uid).get();
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> createTask(TaskModel task) async {
    try {
      await _collection.doc(task.id).set(task.toFirestore());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await _collection
          .doc(task.id)
          .set(task.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
