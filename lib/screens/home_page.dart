import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_frequency.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../models/habit.dart';
import '../utils/styles.dart';
import '../widgets/add_habit_dialog.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final HabitService _habitService = HabitService();
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _updateProgress(double newProgress) {
    if (newProgress != _lastProgress) {
      _progressAnimation = Tween<double>(
        begin: _lastProgress,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));

      _lastProgress = newProgress;
      _progressController.forward(from: 0);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            final completedToday = habits.where((habit) {
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressCard(habits.length, completedToday),
                        const SizedBox(height: 24),
                        _buildTodaySection(),
                      ],
                    ),
                  ),
                ),
                if (habits.isEmpty)
                  SliverFillRemaining(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: 1.0,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.5, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) =>
                                  Transform.scale(
                                scale: value,
                                child: const Icon(
                                  Icons.note_add_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No habits yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add your first habit to get started',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: AnimationLimiter(
                      child: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildHabitItem(habits[index]),
                              ),
                            ),
                          ),
                          childCount: habits.length,
                        ),
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
      title: const Text(
        'My Habits',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: AppColors.textPrimary),
          onPressed: () async {
            await _authService.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ],
    );
  }

  Widget _buildProgressCard(int totalHabits, int completedToday) {
    final progress = totalHabits == 0 ? 0.0 : completedToday / totalHabits;

    _updateProgress(progress);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: 1.0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.containerDecoration(),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<double>(
                      valueListenable: _progressController,
                      builder: (context, value, child) {
                        final currentProgress = _progressAnimation.value;
                        return Text(
                          '${(currentProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 80,
                  width: 80,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _progressController,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        strokeWidth: 8,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStatItem('Total Habits', totalHabits.toString()),
                _buildAnimatedStatItem('Completed', completedToday.toString()),
                _buildAnimatedStatItem(
                  'Remaining',
                  (totalHabits - completedToday).toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatItem(String label, String value) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 20, end: 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (context, offset, child) => Transform.translate(
            offset: Offset(0, offset),
            child: Column(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySection() {
    return const Column(
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
      key: Key(habit.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.1),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: IconButton(
                icon: Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color:
                      isCompleted ? AppColors.primary : AppColors.textSecondary,
                  size: 28,
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
              title: Text(
                habit.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: Text(
                '${habit.time.format(context)} - ${habit.frequency.displayName}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: habit.hasReminder
                  ? const Icon(
                      Icons.notifications_active,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
