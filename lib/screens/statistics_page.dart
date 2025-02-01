import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../models/activity_log.dart';
import '../utils/styles.dart';
import '../widgets/app_drawer.dart';
import '../providers/route_provider.dart';
import '../widgets/activity_calendar.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late DateTime _selectedMonth;
  final Map<String, List<ActivityLog>> _monthlyLogsCache = {};

  // Add method to preload adjacent months
  void _preloadAdjacentMonths(DateTime month) {
    // Preload previous month
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    _getMonthData(prevMonth);

    // Preload next month if it's not in the future
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final now = DateTime.now();
    if (!nextMonth.isAfter(DateTime(now.year, now.month, 1))) {
      _getMonthData(nextMonth);
    }
  }

  // Separate data fetching logic
  Stream<List<ActivityLog>> _getMonthData(DateTime month) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final cacheKey = _getCacheKey(month);

    return FirebaseFirestore.instance
        .collection('activity_logs')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.id, doc.data()))
          .toList();

      _monthlyLogsCache[cacheKey] = logs;
      return logs;
    });
  }

  Stream<List<ActivityLog>> _getMonthlyLogs() {
    _preloadAdjacentMonths(_selectedMonth);
    return _getMonthData(_selectedMonth);
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _selectedMonth = newMonth;
    });
    _preloadAdjacentMonths(newMonth);
  }

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _preloadAdjacentMonths(_selectedMonth);
  }

  String _getCacheKey(DateTime date) {
    return '${date.year}-${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    // Set current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RouteProvider.instance.setCurrentRoute('/statistics');
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: StreamBuilder<List<ActivityLog>>(
          key: ValueKey(_getCacheKey(_selectedMonth)),
          stream: _getMonthlyLogs(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final cacheKey = _getCacheKey(_selectedMonth);
            final logs = snapshot.data ?? _monthlyLogsCache[cacheKey] ?? [];

            if (logs.isEmpty && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (logs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Overview',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Active Days',
                              '0',
                              StatIcon.lottie('assets/lottie/fire.json'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Completed',
                              '0',
                              StatIcon.icon(Icons.check_circle),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Completion',
                              '0%',
                              StatIcon.icon(Icons.trending_up),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ActivityCalendar(
                        activityLogs: logs,
                        selectedMonth: _selectedMonth,
                        onMonthChanged: _onMonthChanged,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No activity data for this month',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Calculate monthly statistics
            final totalDays = logs.length;
            final totalCompletedHabits =
                logs.fold<int>(0, (sum, log) => sum + log.habitsCompleted);
            final averageCompletion =
                logs.fold<double>(0, (sum, log) => sum + log.completionRate) /
                    totalDays;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Overview',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Active Days',
                            totalDays.toString(),
                            StatIcon.lottie('assets/lottie/fire.json'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            totalCompletedHabits.toString(),
                            StatIcon.icon(Icons.check_circle),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Completion',
                            '${averageCompletion.toStringAsFixed(1)}%',
                            StatIcon.icon(Icons.trending_up),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ActivityCalendar(
                      activityLogs: logs,
                      selectedMonth: _selectedMonth,
                      onMonthChanged: _onMonthChanged,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Daily Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: AppColors.surface,
                          child: ListTile(
                            title: Text(
                              '${log.date.day}/${log.date.month}/${log.date.year}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${log.habitsCompleted}/${log.totalHabits} habits completed',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              '${log.completionRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _getCompletionColor(log.completionRate),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, StatIcon icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon.icon != null)
            Icon(icon.icon, color: AppColors.primary, size: 20)
          else if (icon.lottieAsset != null)
            SizedBox(
              width: 24,
              height: 24,
              child: Lottie.asset(
                icon.lottieAsset!,
                repeat: false,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            softWrap: true,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(double completion) {
    if (completion >= 80) return Colors.green;
    if (completion >= 50) return Colors.orange;
    return Colors.red;
  }
}

// First, create a helper class to handle both types of widgets
class StatIcon {
  final IconData? icon;
  final String? lottieAsset;

  const StatIcon.icon(this.icon) : lottieAsset = null;
  const StatIcon.lottie(this.lottieAsset) : icon = null;
}
