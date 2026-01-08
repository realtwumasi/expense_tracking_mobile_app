import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

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
          for (var e in expenses) {
            summary[e.categoryId] = (summary[e.categoryId] ?? 0) + e.amount;
          }

          final sortedKeys = summary.keys.toList()
            ..sort((a, b) => summary[b]!.compareTo(summary[a]!));

          return ListView.builder(
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
                trailing: Text('\$${total.toStringAsFixed(2)}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              );
            },
          );
        },
      ),
    );
  }
}
