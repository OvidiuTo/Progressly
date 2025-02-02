import 'package:flutter/material.dart';

enum HabitCategory {
  health(Icons.favorite_rounded, 'Health', Color(0xFFFF5C77)),
  fitness(Icons.fitness_center_rounded, 'Fitness', Color(0xFF4CAF50)),
  mind(Icons.self_improvement_rounded, 'Mind', Color(0xFF9C27B0)),
  work(Icons.work_rounded, 'Work', Color(0xFF2196F3)),
  learn(Icons.school_rounded, 'Learn', Color(0xFFFF9800)),
  social(Icons.people_rounded, 'Social', Color(0xFF795548)),
  other(Icons.category_rounded, 'Other', Color(0xFF607D8B));

  final IconData icon;
  final String label;
  final Color color;

  const HabitCategory(this.icon, this.label, this.color);
}
