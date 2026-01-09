import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';

class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final Category category;
  final String currencySymbol;
  final VoidCallback onTap;

  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.category,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withValues(alpha: 0.2),
          child: Icon(category.iconData, color: category.color),
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: expense.description != null && expense.description!.isNotEmpty
            ? Text(expense.description!)
            : Text(DateFormat.jm().format(expense.date)),
        trailing: Text(
          '$currencySymbol${expense.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        onTap: onTap,
      ),
    );
  }
}
