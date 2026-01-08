import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';

enum TimeFilter {
  last7Days,
  lastMonth,
  last6Months,
  lastYear,
  all
}

class CategorySummaryScreen extends StatefulWidget {
  const CategorySummaryScreen({super.key});

  @override
  State<CategorySummaryScreen> createState() => _CategorySummaryScreenState();
}

class _CategorySummaryScreenState extends State<CategorySummaryScreen> {
  TimeFilter _selectedFilter = TimeFilter.all;

  String _getFilterName(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.last7Days:
        return 'Last 7 Days';
      case TimeFilter.lastMonth:
        return 'Last 30 Days';
      case TimeFilter.last6Months:
        return 'Last 6 Months';
      case TimeFilter.lastYear:
        return 'Last Year';
      case TimeFilter.all:
        return 'All Time';
    }
  }

  List<Expense> _filterExpenses(List<Expense> allExpenses) {
    if (_selectedFilter == TimeFilter.all) return allExpenses;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Calculate cutoff based on filter
    DateTime cutoff;
    switch (_selectedFilter) {
      case TimeFilter.last7Days:
        cutoff = today.subtract(const Duration(days: 7));
        break;
      case TimeFilter.lastMonth:
        cutoff = today.subtract(const Duration(days: 30));
        break;
      case TimeFilter.last6Months:
        cutoff = today.subtract(const Duration(days: 180));
        break;
      case TimeFilter.lastYear:
        cutoff = today.subtract(const Duration(days: 365));
        break;
      default:
        cutoff = DateTime(1970);
    }

    return allExpenses.where((expense) {
      return expense.date.isAfter(cutoff);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Summary'),
        actions: [
          DropdownButton<TimeFilter>(
            value: _selectedFilter,
            dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
            underline: Container(),
            icon: Icon(Icons.filter_list, color: Theme.of(context).iconTheme.color),
            onChanged: (TimeFilter? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                });
              }
            },
            items: TimeFilter.values.map((TimeFilter filter) {
              return DropdownMenuItem<TimeFilter>(
                value: filter,
                child: Text(
                  _getFilterName(filter),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final allExpenses = provider.expenses;
          final categories = provider.categories;
          
          final filteredExpenses = _filterExpenses(allExpenses);

          if (filteredExpenses.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text(
                     'No expenses in ${_getFilterName(_selectedFilter)}',
                     style: Theme.of(context).textTheme.titleMedium,
                   ),
                 ],
               ),
             );
          }

          // Calculate summary map
          final Map<String, double> summary = {};
          double totalSpent = 0;
          for (var e in filteredExpenses) {
            summary[e.categoryId] = (summary[e.categoryId] ?? 0) + e.amount;
            totalSpent += e.amount;
          }

          final sortedKeys = summary.keys.toList()
            ..sort((a, b) => summary[b]!.compareTo(summary[a]!));

          final currency = Provider.of<SettingsProvider>(context).currencySymbol;

          return Column(
            children: [
              if (totalSpent > 0)
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sortedKeys.map((catId) {
                        final category = categories.firstWhere(
                          (c) => c.id == catId, 
                          orElse: () => categories.first
                        );
                        final amount = summary[catId]!;
                        final percentage = (amount / totalSpent) * 100;
                        
                        return PieChartSectionData(
                          color: category.color,
                          value: amount,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              
              // Total for range
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Total: $currency${totalSpent.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final catId = sortedKeys[index];
                    final total = summary[catId]!;
                    final category = categories.firstWhere(
                      (c) => c.id == catId, 
                      orElse: () => categories.first // Fallback
                    );

                    final percentage = (total / totalSpent) * 100;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color.withValues(alpha: 0.2),
                        child: Icon(category.iconData, color: category.color),
                      ),
                      title: Text(category.name),
                      subtitle: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        color: category.color,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$currency${total.toStringAsFixed(2)}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${percentage.toStringAsFixed(1)}%', 
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
