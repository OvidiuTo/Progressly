import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_log.dart';
import '../utils/styles.dart';
import '../widgets/app_drawer.dart';
import '../providers/route_provider.dart';
import '../widgets/activity_calendar.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getMonthlyLogs(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final logs = snapshot.data?.docs
                  .map((doc) => ActivityLog.fromMap(doc.id, doc.data()))
                  .toList() ??
              [];

          if (logs.isEmpty) {
            return const Center(
              child: Text('No activity data for this month'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                _buildStatCard(
                  'Active Days',
                  totalDays.toString(),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Completed Habits',
                  totalCompletedHabits.toString(),
                  Icons.check_circle,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Average Completion',
                  '${averageCompletion.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
                const SizedBox(height: 24),
                ActivityCalendar(
                  activeDates: logs
                      .where((log) => log.habitsCompleted > 0)
                      .map((log) => log.date)
                      .toList(),
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
                Expanded(
                  child: ListView.builder(
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _getMonthlyLogs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('activity_logs')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .snapshots();
  }
}
