import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';

class CategorySummaryScreen extends StatelessWidget {
  const CategorySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category Summary')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final expenses = provider.expenses;
          final categories = provider.categories;
          
          if (expenses.isEmpty) {
             return const Center(child: Text('No expenses recorded'));
          }

          // Calculate summary map
          final Map<String, double> summary = {};
          double totalSpent = 0;
          for (var e in expenses) {
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

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color.withValues(alpha: 0.2),
                        child: Icon(category.iconData, color: category.color),
                      ),
                      title: Text(category.name),
                      trailing: Text('$currency${total.toStringAsFixed(2)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
