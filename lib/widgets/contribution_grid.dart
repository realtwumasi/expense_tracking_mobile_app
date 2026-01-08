import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ContributionGrid extends StatefulWidget {
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
  State<ContributionGrid> createState() => _ContributionGridState();
}

class _ContributionGridState extends State<ContributionGrid> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Default scroll position is 0.0 (Start/Jan), which matches user request.
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate dates based on filters
    final List<DateTime?> days = []; // Nullable for padding
    DateTime? startDate;
    DateTime? endDate;

    if (widget.month != null) {
      // Monthly View
      final daysInMonth = DateTime(widget.year, widget.month! + 1, 0).day;
      startDate = DateTime(widget.year, widget.month!, 1);
      endDate = DateTime(widget.year, widget.month!, daysInMonth);
    } else {
      // Year View
      startDate = DateTime(widget.year, 1, 1);
      final isLeap = widget.year % 4 == 0 && (widget.year % 100 != 0 || widget.year % 400 == 0);
      final totalDays = isLeap ? 366 : 365;
      endDate = startDate.add(Duration(days: totalDays - 1));
    }

    // Add padding to align start day correctly in column 1
    // GitHub grid flows Column by Column.
    // If GridView flows Row by Row (default horizontal), we need `Axis.horizontal`.
    // Wait, GitHub grid fills column 1 (Sun-Sat), then column 2.
    // GridView default with `horizontal` fills Top-to-Bottom, then Left-to-Right.
    // So visual rows are:
    // Row 0: Sun
    // Row 1: Mon ...
    // Row 6: Sat
    
    // If startDate is Wed (weekday 3), we need 3 empty slots (Sun, Mon, Tue)
    // before placing wed in slot 3.
    // DateTime.weekday: Mon=1...Sun=7.
    // We want 0-indexed: Sun=0, Mon=1...Sat=6?
    // Let's assume standard Sun-start week.
    // If Date is Sun -> Index 0. Padding 0.
    // If Date is Mon -> Index 1. Padding 1.
    // ...
    // If Date is Sat -> Index 6. Padding 6.
    
    // DateTime.weekday map: Mon(1)->1, Tue(2)->2 ... Sat(6)->6, Sun(7)->0.
    int paddingCount = startDate.weekday;
    if (paddingCount == 7) paddingCount = 0; // Sun is 0 in standard grid
    
    for (int i = 0; i < paddingCount; i++) {
      days.add(null);
    }

    // Add actual days
    final diff = endDate.difference(startDate).inDays;
    for (int i = 0; i <= diff; i++) {
      days.add(startDate.add(Duration(days: i)));
    }

    // Determine max spending to calculate quartiles
    double maxSpending = 0;
    if (widget.dailySpending.isNotEmpty) {
      maxSpending = widget.dailySpending.values.reduce((a, b) => a > b ? a : b);
    }
    if (maxSpending == 0) maxSpending = 1;

    // Normalizing today for border check
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 140, 
      child: GridView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        reverse: false, // Standard LTR (Jan -> Dec)
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, 
          mainAxisSpacing: 4, 
          crossAxisSpacing: 4, 
          childAspectRatio: 1.0, 
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          
          if (date == null) {
            return const SizedBox(); // Empty tile for padding
          }

          final amount = widget.dailySpending[date] ?? 0.0;
          
          final currency = Provider.of<SettingsProvider>(context).currencySymbol;
          return GestureDetector(
            onTap: () => widget.onDateTap(date),
            child: Tooltip(
              message: '${date.year}-${date.month}-${date.day}: $currency${amount.toStringAsFixed(2)}',
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
