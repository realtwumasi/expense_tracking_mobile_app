import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(
                  settings.themeMode == ThemeMode.light
                      ? 'Light Mode'
                      : settings.themeMode == ThemeMode.dark
                          ? 'Dark Mode'
                          : 'System Default',
                ),
                trailing: Switch(
                  value: settings.themeMode == ThemeMode.light,
                  onChanged: (isLight) {
                    settings.setThemeMode(
                      isLight ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Currency'),
                subtitle: const Text('Select your preferred currency'),
                trailing: DropdownButton<String>(
                  value: settings.currencySymbol,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: '\$', child: Text('Dollar (\$)')),
                    DropdownMenuItem(value: '₵', child: Text('Cedi (₵)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setCurrencySymbol(value);
                    }
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Data (CSV)'),
                subtitle: const Text('Backup your expenses'),
                onTap: () {
                   Provider.of<ExpenseProvider>(context, listen: false).exportExpensesToCsv();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
