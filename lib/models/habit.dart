import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'habit_frequency.dart';

class Habit {
  final String id;
  final String userId;
  final String name;
  final TimeOfDay time;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final List<DateTime> completedDates;
  final bool hasReminder;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.time,
    required this.frequency,
    required this.createdAt,
    required this.hasReminder,
    this.completedDates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'time': '${time.hour}:${time.minute}',
      'frequency': frequency.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDates':
          completedDates.map((date) => Timestamp.fromDate(date)).toList(),
      'hasReminder': hasReminder,
    };
  }

  factory Habit.fromMap(String id, Map<String, dynamic> map) {
    final timeParts = (map['time'] as String).split(':');
    return Habit(
      id: id,
      userId: map['userId'] as String,
      name: map['name'] as String,
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == map['frequency'],
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedDates: (map['completedDates'] as List)
          .map((date) => (date as Timestamp).toDate())
          .toList(),
      hasReminder: map['hasReminder'] as bool? ?? false,
    );
  }
}
