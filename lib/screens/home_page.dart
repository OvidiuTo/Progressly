import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_frequency.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../models/habit.dart';
import '../utils/styles.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/app_drawer.dart';
import '../providers/route_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final HabitService _habitService = HabitService();

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

            // Sort habits: uncompleted first, then completed
            final sortedHabits = habits.toList()
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

            // Calculate completed habits count
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
                if (sortedHabits.isEmpty)
                  SliverFillRemaining(
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
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildHabitItem(sortedHabits[index]),
                        childCount: sortedHabits.length,
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

  Widget _buildProgressCard(int totalHabits, int completedToday) {
    final progress = totalHabits == 0 ? 0.0 : completedToday / totalHabits;

    return Container(
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
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Habits', totalHabits.toString()),
              _buildStatItem('Completed', completedToday.toString()),
              _buildStatItem(
                'Remaining',
                (totalHabits - completedToday).toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
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
              color: isCompleted ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            onPressed: () async {
              try {
                await _habitService.toggleHabitCompletion(habit.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update habit completion status'),
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
          trailing: IconButton(
            icon: Icon(
              habit.hasReminder
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: habit.hasReminder
                  ? AppColors.primary
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
}
