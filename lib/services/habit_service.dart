import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_frequency.dart';
import '../models/activity_log.dart';
import '../models/habit_category.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _habitsCollection =>
      _firestore.collection('habits');

  CollectionReference<Map<String, dynamic>> get _activityLogsCollection =>
      _firestore.collection('activity_logs');

  Future<Habit> addHabit({
    required String name,
    required TimeOfDay time,
    required HabitFrequency frequency,
    required bool hasReminder,
    required HabitCategory category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final habit = Habit(
      id: '',
      userId: user.uid,
      name: name,
      time: time,
      frequency: frequency,
      createdAt: DateTime.now(),
      hasReminder: hasReminder,
      category: category,
    );

    final docRef = await _habitsCollection.add(habit.toMap());
    final newHabit = Habit.fromMap(docRef.id, habit.toMap());

    return newHabit;
  }

  Stream<List<Habit>> getUserHabits() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _habitsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Habit.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateActivityLog() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final habits =
        await _habitsCollection.where('userId', isEqualTo: user.uid).get();

    final totalHabits = habits.docs.length;

    int completedHabits = 0;
    for (var habit in habits.docs) {
      final habitData = Habit.fromMap(habit.id, habit.data());
      if (habitData.completedDates.any((date) =>
          date.year == todayDate.year &&
          date.month == todayDate.month &&
          date.day == todayDate.day)) {
        completedHabits++;
      }
    }

    final completionRate =
        totalHabits > 0 ? (completedHabits / totalHabits) * 100 : 0.0;

    final existingLog = await _activityLogsCollection
        .where('userId', isEqualTo: user.uid)
        .where('date', isEqualTo: Timestamp.fromDate(todayDate))
        .get();

    final activityLog = ActivityLog(
      id: existingLog.docs.isNotEmpty ? existingLog.docs.first.id : '',
      userId: user.uid,
      date: todayDate,
      habitsCompleted: completedHabits,
      totalHabits: totalHabits,
      completionRate: completionRate,
    );

    if (existingLog.docs.isNotEmpty) {
      await _activityLogsCollection
          .doc(existingLog.docs.first.id)
          .update(activityLog.toMap());
    } else {
      await _activityLogsCollection.add(activityLog.toMap());
    }
  }

  Future<void> toggleHabitCompletion(String habitId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final habitDoc = await _habitsCollection.doc(habitId).get();
    if (!habitDoc.exists) throw Exception('Habit not found');

    final habit = Habit.fromMap(habitDoc.id, habitDoc.data()!);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    List<DateTime> updatedCompletedDates = List.from(habit.completedDates);
    final todayCompleted = updatedCompletedDates.any((date) =>
        date.year == todayDate.year &&
        date.month == todayDate.month &&
        date.day == todayDate.day);

    if (todayCompleted) {
      updatedCompletedDates.removeWhere((date) =>
          date.year == todayDate.year &&
          date.month == todayDate.month &&
          date.day == todayDate.day);
    } else {
      updatedCompletedDates.add(todayDate);
    }

    await _habitsCollection.doc(habitId).update({
      'completedDates': updatedCompletedDates
          .map((date) => Timestamp.fromDate(date))
          .toList(),
    });

    await updateActivityLog();
  }

  Future<void> deleteHabit(String habitId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final habitDoc = await _habitsCollection.doc(habitId).get();
    if (!habitDoc.exists) throw Exception('Habit not found');

    final habit = Habit.fromMap(habitDoc.id, habitDoc.data()!);
    if (habit.userId != user.uid) throw Exception('Not authorized');

    await _habitsCollection.doc(habitId).delete();
  }

  Future<void> updateHabitReminder(String habitId, bool hasReminder) async {
    final habit = await _habitsCollection.doc(habitId).get();
    if (!habit.exists) throw Exception('Habit not found');

    final habitData = Habit.fromMap(habit.id, habit.data()!);

    await _habitsCollection.doc(habitId).update({
      'hasReminder': hasReminder,
    });
  }
}
