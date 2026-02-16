import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _taskRef {
    final uid = _auth.currentUser!.uid;

    return _firestore.collection('users').doc(uid).collection('tasks');
  }

  // ➕ Add Task
  Future<void> addTask(String text) async {
    await _taskRef.add({
      'rawSpeechText': text,
      'parsedTaskText': text, // temporary (AI later)
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'reminderTimestamp': null,
    });
  }

  // 📡 Stream Tasks (Realtime)
  Stream<List<TaskModel>> streamTasks() {
    return _taskRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // ✅ Toggle Complete
  Future<void> toggleTask(String taskId, bool currentValue) async {
    await _taskRef.doc(taskId).update({'completed': !currentValue});
  }

  // ❌ Delete Task
  Future<void> deleteTask(String taskId) async {
    await _taskRef.doc(taskId).delete();
  }
}
