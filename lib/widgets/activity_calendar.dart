import 'package:flutter/material.dart';
import '../utils/styles.dart';
import '../models/activity_log.dart';

class ActivityCalendar extends StatefulWidget {
  final List<ActivityLog> activityLogs;
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const ActivityCalendar({
    super.key,
    required this.activityLogs,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  State<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<ActivityCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedMonth;
  }

  @override
  void didUpdateWidget(ActivityCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      setState(() {
        _currentMonth = widget.selectedMonth;
      });
    }
  }

  void _previousMonth() {
    final prevMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month - 1,
      1,
    );
    widget.onMonthChanged(prevMonth);
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      1,
    );
    if (!nextMonth.isAfter(now)) {
      widget.onMonthChanged(nextMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
                color: AppColors.textPrimary,
              ),
              Text(
                '${_getMonthName(_currentMonth)} ${_currentMonth.year}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentMonth.year == now.year &&
                        _currentMonth.month == now.month
                    ? null
                    : _nextMonth,
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              7,
              (index) => SizedBox(
                width: 30,
                child: Text(
                  _getWeekdayName(index),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final firstDayOffset = _currentMonth.weekday - 1;
              final day = index - firstDayOffset + 1;
              final date =
                  DateTime(_currentMonth.year, _currentMonth.month, day);

              // Only hide dates before the first of the month or after the last day
              if (index < firstDayOffset || date.isAfter(lastDayOfMonth)) {
                return const SizedBox();
              }

              // Show the date but with different styling if it's in the future
              final now = DateTime.now();
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isFuture =
                  date.isAfter(DateTime(now.year, now.month, now.day));

              // Find the activity log for this date
              final dayLog = widget.activityLogs
                  .where((log) =>
                      log.date.year == date.year &&
                      log.date.month == date.month &&
                      log.date.day == date.day)
                  .toList();

              final completionRate = dayLog.isNotEmpty
                  ? (dayLog.first.habitsCompleted / dayLog.first.totalHabits) *
                      100
                  : 0.0;

              return Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isFuture
                      ? AppColors.surface
                      : _getColorForCompletion(completionRate),
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(
                          color: AppColors.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Tooltip(
                  message: isFuture
                      ? '${date.day}/${date.month}/${date.year}: Future date'
                      : dayLog.isNotEmpty
                          ? '${date.day}/${date.month}/${date.year}: ${dayLog.first.habitsCompleted}/${dayLog.first.totalHabits} habits completed'
                          : '${date.day}/${date.month}/${date.year}: No habits completed',
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isFuture
                            ? AppColors.textSecondary.withOpacity(0.5)
                            : (completionRate > 0
                                ? Colors.white
                                : AppColors.textSecondary),
                        fontSize: 10,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('Less', AppColors.surface),
              _buildLegendItem('', AppColors.primary.withOpacity(0.3)),
              _buildLegendItem('', AppColors.primary.withOpacity(0.5)),
              _buildLegendItem('', AppColors.primary.withOpacity(0.7)),
              _buildLegendItem('More', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    // Find the activity log for this date
    final dayLog = widget.activityLogs
        .where((log) =>
            log.date.year == date.year &&
            log.date.month == date.month &&
            log.date.day == date.day)
        .toList();

    final completionRate = dayLog.isNotEmpty
        ? (dayLog.first.habitsCompleted / dayLog.first.totalHabits) * 100
        : 0.0;

    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _getColorForCompletion(completionRate),
        borderRadius: BorderRadius.circular(4),
        border: isToday
            ? Border.all(
                color: AppColors.primary,
                width: 2,
              )
            : null,
      ),
      child: Tooltip(
        message: dayLog.isNotEmpty
            ? '${date.day}/${date.month}/${date.year}: ${dayLog.first.habitsCompleted}/${dayLog.first.totalHabits} habits completed'
            : '${date.day}/${date.month}/${date.year}: No habits completed',
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color:
                  completionRate > 0 ? Colors.white : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.1),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForCompletion(double percentage) {
    if (percentage == 0) return AppColors.surface;
    if (percentage <= 25) return AppColors.primary.withOpacity(0.3);
    if (percentage <= 50) return AppColors.primary.withOpacity(0.5);
    if (percentage <= 75) return AppColors.primary.withOpacity(0.7);
    return AppColors.primary;
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[date.month - 1];
  }

  int _getDaysInRange(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  String _getWeekdayName(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday];
  }
}
