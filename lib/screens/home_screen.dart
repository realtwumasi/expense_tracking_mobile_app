import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../widgets/contribution_grid.dart';
import '../widgets/empty_state.dart';
import 'add_edit_expense_screen.dart';
import 'category_summary_screen.dart';
import 'settings_screen.dart';
import 'daily_expenses_screen.dart';
import '../widgets/expense_list_tile.dart';
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
        //backgroundColor:Colors.transparent,
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
                  currencySymbol: Provider.of<SettingsProvider>(context, listen: false).currencySymbol,
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
      floatingActionButton: OpenContainer(
        openBuilder: (context, _) => const AddEditExpenseScreen(),
        closedElevation: 6.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)), // FAB standard radius
        ),
        closedColor: Theme.of(context).colorScheme.primaryContainer,
        openColor: Theme.of(context).colorScheme.surface,
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 500),
        closedBuilder: (context, openContainer) {
          return FloatingActionButton(
            elevation: 0,
            onPressed: openContainer,
            child: const Icon(Icons.add),
          );
        },
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Icon
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.account_balance_wallet,
              size: 150,
              color: colorScheme.onPrimary.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.attach_money, color: colorScheme.onPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedMonth == null 
                          ? 'Total Spent ($_selectedYear)' 
                          : 'Total Spent (${DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth!))})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '$currency${total.toStringAsFixed(2)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Overview',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(ExpenseProvider provider) {
    if (provider.expenses.isEmpty) {
      return const EmptyStateWidget(
        title: 'No expenses yet',
        subtitle: 'Tap the + button to track your first expense!',
        icon: Icons.receipt_long_outlined,
      );
    }

    // Expenses are already sorted by Date DESC, Timestamp DESC from DB
    final top5 = provider.expenses.take(5).toList();

    return Column(
      children: top5.map<Widget>((expense) {
        final category = provider.categories.firstWhere(
          (c) => c.id == expense.categoryId,
          orElse: () => provider.categories.first,
        );

        return ExpenseListTile(
          expense: expense,
          category: category,
          currencySymbol: Provider.of<SettingsProvider>(context, listen: false).currencySymbol,
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
