import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String rawSpeechText;
  final String parsedTaskText;
  final bool completed;
  final DateTime createdAt;
  final DateTime? reminderTimestamp;

  TaskModel({
    required this.id,
    required this.rawSpeechText,
    required this.parsedTaskText,
    required this.completed,
    required this.createdAt,
    this.reminderTimestamp,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TaskModel(
      id: doc.id,
      rawSpeechText: data['rawSpeechText'],
      parsedTaskText: data['parsedTaskText'],
      completed: data['completed'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reminderTimestamp:
          data['reminderTimestamp'] != null
              ? (data['reminderTimestamp'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rawSpeechText': rawSpeechText,
      'parsedTaskText': parsedTaskText,
      'completed': completed,
      'createdAt': createdAt,
      'reminderTimestamp': reminderTimestamp,
    };
  }
}
