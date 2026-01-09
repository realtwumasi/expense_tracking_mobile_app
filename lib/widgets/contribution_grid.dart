import 'package:flutter/material.dart';

class ContributionGrid extends StatefulWidget {
  final Map<DateTime, double> dailySpending;
  final Function(DateTime) onDateTap;
  final int year;
  final int? month; // If null, show full year
  final String currencySymbol; // Passed from parent to avoid Provider in itemBuilder

  const ContributionGrid({
    super.key,
    required this.dailySpending,
    required this.onDateTap,
    required this.year,
    required this.currencySymbol,
    this.month,
  });

  @override
  State<ContributionGrid> createState() => _ContributionGridState();
}

class _ContributionGridState extends State<ContributionGrid> {
  late ScrollController _scrollController;
  
  // Cache computed values
  late List<DateTime?> _days;
  late double _maxSpending;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _computeDaysAndMax();
  }

  @override
  void didUpdateWidget(ContributionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recompute only if relevant props changed
    if (oldWidget.year != widget.year || 
        oldWidget.month != widget.month ||
        oldWidget.dailySpending != widget.dailySpending) {
      _computeDaysAndMax();
    }
  }

  void _computeDaysAndMax() {
    final List<DateTime?> days = [];
    DateTime startDate;
    DateTime endDate;

    if (widget.month != null) {
      final daysInMonth = DateTime(widget.year, widget.month! + 1, 0).day;
      startDate = DateTime(widget.year, widget.month!, 1);
      endDate = DateTime(widget.year, widget.month!, daysInMonth);
    } else {
      startDate = DateTime(widget.year, 1, 1);
      final isLeap = widget.year % 4 == 0 && (widget.year % 100 != 0 || widget.year % 400 == 0);
      final totalDays = isLeap ? 366 : 365;
      endDate = startDate.add(Duration(days: totalDays - 1));
    }

    int paddingCount = startDate.weekday;
    if (paddingCount == 7) paddingCount = 0;
    
    for (int i = 0; i < paddingCount; i++) {
      days.add(null);
    }

    final diff = endDate.difference(startDate).inDays;
    for (int i = 0; i <= diff; i++) {
      days.add(startDate.add(Duration(days: i)));
    }

    _days = days;

    // Compute max spending
    _maxSpending = 1.0;
    if (widget.dailySpending.isNotEmpty) {
      _maxSpending = widget.dailySpending.values.reduce((a, b) => a > b ? a : b);
      if (_maxSpending == 0) _maxSpending = 1.0;
    }

    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 140, 
      child: GridView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        reverse: false,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, 
          mainAxisSpacing: 4, 
          crossAxisSpacing: 4, 
          childAspectRatio: 1.0, 
        ),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final date = _days[index];
          
          if (date == null) {
            return const SizedBox.shrink(); // Slightly more efficient
          }

          final amount = widget.dailySpending[date] ?? 0.0;
          final isToday = date == _today;
          
          return GestureDetector(
            onTap: () => widget.onDateTap(date),
            child: Tooltip(
              message: '${date.year}-${date.month}-${date.day}: ${widget.currencySymbol}${amount.toStringAsFixed(2)}',
              child: Container(
                decoration: BoxDecoration(
                  color: _getColorForAmount(colorScheme, amount),
                  borderRadius: BorderRadius.circular(2),
                  border: isToday
                    ? Border.all(color: colorScheme.onSurface, width: 1)
                    : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getColorForAmount(ColorScheme colorScheme, double amount) {
    if (amount <= 0) return colorScheme.surfaceContainerHighest;
    
    final ratio = amount / _maxSpending;
    final baseColor = colorScheme.primary;

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
