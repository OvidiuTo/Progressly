import 'package:flutter/material.dart';
import '../utils/styles.dart';

class ActivityCalendar extends StatelessWidget {
  final List<DateTime> activeDates;
  final int monthsToShow;

  const ActivityCalendar({
    super.key,
    required this.activeDates,
    this.monthsToShow = 3,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(monthsToShow, (index) {
      return DateTime(now.year, now.month - index);
    }).reversed.toList();

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
          const Text(
            'Activity Calendar',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: months
                .map((month) => Text(
                      _getMonthName(month),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _getDaysInRange(months.first, now),
              itemBuilder: (context, index) {
                final date = months.first.add(Duration(days: index));
                if (date.isAfter(now)) return const SizedBox.shrink();

                return _buildDayCell(date);
              },
            ),
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
    final isActive = activeDates.any((activeDate) =>
        activeDate.year == date.year &&
        activeDate.month == date.month &&
        activeDate.day == date.day);

    final completionCount = activeDates
        .where((activeDate) =>
            activeDate.year == date.year &&
            activeDate.month == date.month &&
            activeDate.day == date.day)
        .length;

    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _getColorForCount(completionCount),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Tooltip(
        message:
            '${date.day}/${date.month}/${date.year}: $completionCount habits completed',
        child: const SizedBox.expand(),
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

  Color _getColorForCount(int count) {
    if (count == 0) return AppColors.surface;
    if (count <= 1) return AppColors.primary.withOpacity(0.3);
    if (count <= 2) return AppColors.primary.withOpacity(0.5);
    if (count <= 3) return AppColors.primary.withOpacity(0.7);
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
}
