import 'package:flutter/material.dart';

class ContributionGrid extends StatelessWidget {
  final Map<DateTime, double> dailySpending;
  final Function(DateTime) onDateTap;

  const ContributionGrid({
    super.key,
    required this.dailySpending,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dates for the current year or last 365 days
    final now = DateTime.now();
    final endDate = now;
    // Start 52 weeks ago (approx 364 days)
    final startDate = endDate.subtract(const Duration(days: 364));

    // Determine max spending for color scaling
    double maxSpending = 0;
    if (dailySpending.isNotEmpty) {
      maxSpending = dailySpending.values.reduce((a, b) => a > b ? a : b);
    }
    if (maxSpending == 0) maxSpending = 1;

    List<DateTime> days = [];
    for (int i = 0; i <= 364; i++) {
        days.add(startDate.add(Duration(days: i)));
    }

    return SizedBox(
      height: 140, // Height for 7 rows (approx 14px * 7 + gaps)
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // Start from right
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, // 7 days per column
          mainAxisSpacing: 4, // Vertical gap (between rows in column)
          crossAxisSpacing: 4, // Horizontal gap (between columns)
          childAspectRatio: 1.0, // Square tiles
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final dateKey = DateTime(date.year, date.month, date.day);
          final amount = dailySpending[dateKey] ?? 0.0;
          final intensity = (amount / maxSpending).clamp(0.0, 1.0);
          
          return GestureDetector(
            onTap: () => onDateTap(dateKey),
            child: Tooltip(
              message: '${date.year}-${date.month}-${date.day}: \$${amount.toStringAsFixed(2)}',
              child: Container(
                decoration: BoxDecoration(
                  color: _getColorForIntensity(context, intensity, amount > 0),
                  borderRadius: BorderRadius.circular(2),
                  border: dateKey == DateTime(now.year, now.month, now.day)
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
                    : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getColorForIntensity(BuildContext context, double intensity, bool hasSpending) {
    if (!hasSpending) return Theme.of(context).colorScheme.surfaceContainerHighest;
    
    // Lerp from light green to dark green (or primary color)
    final baseColor = Theme.of(context).colorScheme.primary;
    // Remap intensity to have a minimum visibility if > 0
    final adjustedIntensity = 0.2 + (intensity * 0.8); 
    
    return baseColor.withValues(alpha: adjustedIntensity);
  }
}
