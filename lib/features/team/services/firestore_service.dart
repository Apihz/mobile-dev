import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //listen to all tasks in a project, ordered by when they were created
  Stream<List<Task>> watchTasks(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Task.fromMap(d.id, d.data())).toList());
  }

  Future<void> addTask(String projectId, Task task) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .add({
      ...task.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  //called when a card is dragged to a different column
  Future<void> updateTaskStatus(
      String projectId, String taskId, String newStatus) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask(
      String projectId, String taskId, Map<String, dynamic> data) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
}