import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/contribution_grid.dart';
import 'add_edit_expense_screen.dart';
import 'category_summary_screen.dart';
import 'settings_screen.dart';
import 'daily_expenses_screen.dart';
import '../widgets/expense_list_tile.dart';
import '../models/expense.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth; // Default to null ("All Year")

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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
                // Filter Row
                Row(
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    // Year Dropdown
                    DropdownButton<int>(
                      value: _selectedYear,
                      underline: Container(), // Remove underline
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      onChanged: (int? value) {
                        if (value != null) {
                          setState(() => _selectedYear = value);
                        }
                      },
                      items: List.generate(5, (index) {
                        // Last 5 years
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem(value: year, child: Text(year.toString()));
                      }),
                    ),
                    const SizedBox(width: 8),
                    // Month Dropdown
                    DropdownButton<int?>(
                      value: _selectedMonth,
                       underline: Container(),
                      onChanged: (int? value) {
                        setState(() => _selectedMonth = value);
                      },
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Year')),
                        ...List.generate(12, (index) {
                          final monthIndex = index + 1;
                          // Simple month names
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          return DropdownMenuItem(
                            value: monthIndex, 
                            child: Text(months[index]),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary Card
                _buildSummaryCard(provider, context),
                const SizedBox(height: 16),

                ContributionGrid(
                  dailySpending: provider.dailySpending,
                  year: _selectedYear,
                  month: _selectedMonth,
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
                
                // Recent Transactions
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildRecentTransactions(provider),
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

  Widget _buildSummaryCard(ExpenseProvider provider, BuildContext context) {
    double total = 0;
    // Calculate total based on filters
    for (var expense in provider.expenses) {
      if (expense.date.year == _selectedYear) {
        if (_selectedMonth == null || expense.date.month == _selectedMonth) {
          total += expense.amount;
        }
      }
    }
    
    final currency = Provider.of<SettingsProvider>(context).currencySymbol;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedMonth == null ? 'Total Spent ($_selectedYear)' : 'Total Spent',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.account_balance_wallet, size: 40, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ExpenseProvider provider) {
    if (provider.expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No expenses recorded yet.'),
      );
    }

    // Sort valid copy by date desc
    final recent = List<Expense>.from(provider.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Take top 5
    final top5 = recent.take(5).toList();

    return Column(
      children: top5.map<Widget>((expense) {
        final category = provider.categories.firstWhere(
          (c) => c.id == expense.categoryId,
          orElse: () => provider.categories.first,
        );

        return ExpenseListTile(
          expense: expense,
          category: category,
          onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditExpenseScreen(expense: expense),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
