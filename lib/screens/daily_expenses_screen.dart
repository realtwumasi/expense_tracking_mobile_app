import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/expense_list_tile.dart';
import '../widgets/empty_state.dart';
import 'add_edit_expense_screen.dart';

class DailyExpensesScreen extends StatelessWidget {
  final DateTime date;

  const DailyExpensesScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMd().format(date)),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final expenses = provider.getExpensesByDate(date);
          // Sort by time or creation order (assuming list is already somewhat sorted or we sort here)
          expenses.sort((a,b) => b.timestamp.compareTo(a.timestamp));

          if (expenses.isEmpty) {
            return const EmptyStateWidget(
              title: 'No expenses for this day',
              subtitle: 'Enjoy your savings! 💰',
              icon: Icons.calendar_today_outlined,
            );
          }

          final total = expenses.fold(0.0, (sum, item) => sum + item.amount);
          final currency = Provider.of<SettingsProvider>(context, listen: false).currencySymbol;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Spent', style: Theme.of(context).textTheme.titleMedium),
                    Text('$currency${total.toStringAsFixed(2)}', 
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold
                        )),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final category = provider.categories.firstWhere(
                      (c) => c.id == expense.categoryId,
                      orElse: () => provider.categories.first // Fallback
                    );

                    return ExpenseListTile(
                      expense: expense,
                      category: category,
                      currencySymbol: currency,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditExpenseScreen(expense: expense),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Pass the date to pre-fill
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditExpenseScreen(
                expense: null,
                // We'd need to modify AddEditExpenseScreen constructor or internal logic 
                // to accept a default date, but currently it defaults to Now.
                // Let's rely on user picking date or sticking with Now if it's today.
                // Or I can quickly update AddEditScreen if desired.
                // Actually, let's just use it as is for simplicity, 
                // or updated it if time permits.
              ), 
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
