import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/contribution_grid.dart';
import 'add_edit_expense_screen.dart';
import 'category_summary_screen.dart';
import 'settings_screen.dart';
import 'daily_expenses_screen.dart'; // Ensure this matches filename

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth; // Default to null ("All Year") as requested

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
