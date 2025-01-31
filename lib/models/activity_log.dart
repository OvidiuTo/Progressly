import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String userId;
  final DateTime date;
  final int habitsCompleted;
  final int totalHabits;
  final double completionRate;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.habitsCompleted,
    required this.totalHabits,
    required this.completionRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'habitsCompleted': habitsCompleted,
      'totalHabits': totalHabits,
      'completionRate': completionRate,
    };
  }

  factory ActivityLog.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLog(
      id: id,
      userId: map['userId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      habitsCompleted: map['habitsCompleted'] as int,
      totalHabits: map['totalHabits'] as int,
      completionRate: map['completionRate'] as double,
    );
  }
}
