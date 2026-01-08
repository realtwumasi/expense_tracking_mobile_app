import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/contribution_grid.dart';
import 'add_edit_expense_screen.dart';
import 'category_summary_screen.dart';
import 'daily_expenses_screen.dart'; // Ensure this matches filename

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategorySummaryScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yearly Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ContributionGrid(
                  dailySpending: provider.dailySpending,
                  onDateTap: (date) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyExpensesScreen(date: date),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Could add recent expenses here
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
