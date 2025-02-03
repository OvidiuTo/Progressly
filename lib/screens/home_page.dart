import 'package:flutter/material.dart';

import '../models/habit_frequency.dart';
import '../services/habit_service.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../utils/styles.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/app_drawer.dart';
import '../providers/route_provider.dart';
import 'dart:math' show pi;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HabitService _habitService = HabitService();
  HabitCategory? _selectedCategory;
  List<Habit> _currentHabits = [];
  List<Habit> _displayedHabits = [];

  @override
  Widget build(BuildContext context) {
    // Set current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RouteProvider.instance.setCurrentRoute('/home');
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: StreamBuilder<List<Habit>>(
          stream: _habitService.getUserHabits(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading habits: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final habits = snapshot.data ?? [];
            _currentHabits = _sortHabits(habits);

            // Apply category and search filters
            _displayedHabits = _getFilteredHabits(_currentHabits);

            // Calculate completed habits count
            final completedToday = _currentHabits.where((habit) {
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              return habit.completedDates.any((date) =>
                  date.year == todayDate.year &&
                  date.month == todayDate.month &&
                  date.day == todayDate.day);
            }).length;

            return CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressCard(_currentHabits.length, completedToday),
                      const SizedBox(height: 24),
                      _buildTodaySection(),
                      const SizedBox(height: 16),
                      _buildCategoryFilter(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                if (_displayedHabits.isEmpty)
                  _buildEmptyState()
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildHabitItem(_displayedHabits[index]),
                        childCount: _displayedHabits.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: const Text(
        'My Habits',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressCard(int totalHabits, int completedHabits) {
    final progress =
        totalHabits > 0 ? (completedHabits / totalHabits) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Progress',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${progress.toInt()}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  CustomPaint(
                    size: const Size(48, 48),
                    painter: ProgressRingPainter(
                      progress: progress / 100,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      progressColor: AppColors.primary,
                      strokeWidth: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$completedHabits of $totalHabits completed',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Habits',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Keep going, you\'re doing great!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(Habit habit) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final isCompleted = habit.completedDates.any(
      (date) =>
          date.year == todayDate.year &&
          date.month == todayDate.month &&
          date.day == todayDate.day,
    );

    return Dismissible(
      key: ValueKey(habit.id + isCompleted.toString()),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: AppColors.error),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        try {
          await _habitService.deleteHabit(habit.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Habit deleted')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete habit')),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? habit.category.color.withOpacity(0.2)
                : AppColors.textSecondary.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: habit.category.color.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? habit.category.color.withOpacity(0.15)
                  : habit.category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: isCompleted
                    ? habit.category.color
                    : AppColors.textSecondary,
                size: 24,
              ),
              onPressed: () async {
                try {
                  await _habitService.toggleHabitCompletion(habit.id);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Failed to update habit completion status'),
                      ),
                    );
                  }
                }
              },
            ),
          ),
          title: Row(
            children: [
              Icon(
                habit.category.icon,
                color: habit.category.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              habit.hasReminder
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              color: habit.hasReminder
                  ? habit.category.color
                  : AppColors.textSecondary,
              size: 24,
            ),
            onPressed: () async {
              try {
                await _habitService.updateHabitReminder(
                  habit.id,
                  !habit.hasReminder,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        habit.hasReminder
                            ? 'Reminder disabled'
                            : 'Reminder enabled',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update reminder settings'),
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  List<Habit> _getFilteredHabits(List<Habit> habits) {
    if (_selectedCategory == null) return habits;
    return habits
        .where((habit) => habit.category == _selectedCategory)
        .toList();
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: HabitCategory.values.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          // First item is "All"
          if (index == 0) {
            final isSelected = _selectedCategory == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                label: const Text('All'),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.transparent,
                selectedColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(0.2),
                ),
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
            );
          }

          final category = HabitCategory.values[index - 1];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected ? Colors.white : category.color,
                  ),
                  const SizedBox(width: 4),
                  Text(category.label),
                ],
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: Colors.transparent,
              selectedColor: category.color,
              side: BorderSide(
                color: isSelected
                    ? category.color
                    : AppColors.textSecondary.withOpacity(0.2),
              ),
              onSelected: (_) => setState(() => _selectedCategory = category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.note_add_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No habits yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first habit to get started',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Habit> _sortHabits(List<Habit> habits) {
    // Sort habits: uncompleted first, then completed
    return habits.toList()
      ..sort((a, b) {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        final aCompleted = a.completedDates.any((date) =>
            date.year == todayDate.year &&
            date.month == todayDate.month &&
            date.day == todayDate.day);

        final bCompleted = b.completedDates.any((date) =>
            date.year == todayDate.year &&
            date.month == todayDate.month &&
            date.day == todayDate.day);

        if (aCompleted == bCompleted) {
          return a.time.hour * 60 +
              a.time.minute -
              (b.time.hour * 60 + b.time.minute);
        }
        return aCompleted ? 1 : -1;
      });
  }

  Future<void> _showAddHabitDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );

    if (result != null) {
      try {
        await _habitService.addHabit(
          name: result['name'] as String,
          time: result['time'] as TimeOfDay,
          frequency: result['frequency'] as HabitFrequency,
          hasReminder: result['hasReminder'] as bool,
          category: result['category'] as HabitCategory,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add habit: ${e.toString()}')),
          );
        }
      }
    }
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * (pi / 180), // Start from top
      progress * 2 * pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
