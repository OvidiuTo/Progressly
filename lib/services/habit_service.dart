import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_frequency.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _habitsCollection =>
      _firestore.collection('habits');

  Future<Habit> addHabit({
    required String name,
    required TimeOfDay time,
    required HabitFrequency frequency,
    required bool hasReminder,
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
    );

    final docRef = await _habitsCollection.add(habit.toMap());
    return Habit.fromMap(docRef.id, habit.toMap());
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
}
