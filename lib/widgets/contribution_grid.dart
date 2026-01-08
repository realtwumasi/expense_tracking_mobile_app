import 'package:flutter/material.dart';

class ContributionGrid extends StatelessWidget {
  final Map<DateTime, double> dailySpending;
  final Function(DateTime) onDateTap;
  final int year;
  final int? month; // If null, show full year

  const ContributionGrid({
    super.key,
    required this.dailySpending,
    required this.onDateTap,
    required this.year,
    this.month,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize "now" to start of today locally
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Generate dates based on filters
    final List<DateTime> days = [];
    
    if (month != null) {
      // Monthly View: Show all days in that month
      // Last day of month is Day 0 of next month
      final daysInMonth = DateTime(year, month! + 1, 0).day;
      
      for (int i = 0; i < daysInMonth; i++) {
        // i=0 -> Day 1. 
        // We want reverse list: [Oct 31, Oct 30, ... Oct 1]
        final dayDate = DateTime(year, month!, daysInMonth - i);
        days.add(dayDate);
      }
    } else {
      // Year View: Show full year (Jan 1 - Dec 31)
      // Reverse order: Dec 31 at Right, Jan 1 at Left.
      final lastDayOfYear = DateTime(year, 12, 31);
      final isLeap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
      final totalDays = isLeap ? 366 : 365;

      for (int i = 0; i < totalDays; i++) {
         days.add(lastDayOfYear.subtract(Duration(days: i)));
      }
    }

    // Determine max spending to calculate quartiles

    double maxSpending = 0;
    if (dailySpending.isNotEmpty) {
      maxSpending = dailySpending.values.reduce((a, b) => a > b ? a : b);
    }
    if (maxSpending == 0) maxSpending = 1;



    return SizedBox(
      height: 140, 
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // Start from right (today)
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, 
          mainAxisSpacing: 4, 
          crossAxisSpacing: 4, 
          childAspectRatio: 1.0, 
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          // date is already normalized to midnight because we started with 'today'
          final amount = dailySpending[date] ?? 0.0;
          
          return GestureDetector(
            onTap: () => onDateTap(date),
            child: Tooltip(
              message: '${date.year}-${date.month}-${date.day}: \$${amount.toStringAsFixed(2)}',
              child: Container(
                decoration: BoxDecoration(
                  color: _getColorForAmount(context, amount, maxSpending),
                  borderRadius: BorderRadius.circular(2),
                  border: date == today
                    ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1)
                    : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getColorForAmount(BuildContext context, double amount, double maxSpending) {
    if (amount <= 0) return Theme.of(context).colorScheme.surfaceContainerHighest;
    
    // Calculate intensity ratio
    final ratio = amount / maxSpending;
    final baseColor = Theme.of(context).colorScheme.primary;

    // GitHub-style discrete levels
    // Level 1: > 0
    // Level 2: > 25%
    // Level 3: > 50%
    // Level 4: > 75%
    
    double alpha;
    if (ratio > 0.75) {
      alpha = 1.0;
    } else if (ratio > 0.5) {
      alpha = 0.8;
    } else if (ratio > 0.25) {
      alpha = 0.6;
    } else {
      alpha = 0.4;
    }
    
    return baseColor.withValues(alpha: alpha);
  }
}
