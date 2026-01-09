import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader(context, 'Profile'),
              _buildSettingsCard(
                context,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person, color: Colors.teal),
                    ),
                    title: const Text('Your Name'),
                    subtitle: Text(settings.userName ?? 'Not Set'),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: () => _editName(context, settings),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionHeader(context, 'Appearance'),
              _buildSettingsCard(
                context,
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      settings.themeMode == ThemeMode.light 
                          ? Icons.wb_sunny 
                          : settings.themeMode == ThemeMode.dark ? Icons.nightlight_round : Icons.brightness_auto,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Dark Mode'),
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildSectionHeader(context, 'Preferences'),
              _buildSettingsCard(
                context,
                children: [
                  ListTile(
                    leading: Icon(Icons.currency_exchange, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Currency'),
                    trailing: DropdownButton<String>(
                      value: settings.currencySymbol,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: '\$', child: Text('Dollar (\$)')),
                        DropdownMenuItem(value: '₵', child: Text('Cedi (₵)')),
                      ],
                      onChanged: (value) {
                         if (value != null) settings.setCurrencySymbol(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionHeader(context, 'Notifications'),
              _buildSettingsCard(
                context,
                children: [
                   SwitchListTile(
                    secondary: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Daily Reminder'),
                    subtitle: const Text('Get notified to log expenses'),
                    value: settings.isReminderEnabled,
                    onChanged: (value) => settings.toggleReminder(value),
                  ),
                  if (settings.isReminderEnabled)
                    ListTile(
                      leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.secondary),
                      title: const Text('Reminder Time'),
                      subtitle: Text(settings.reminderTime.format(context)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: settings.reminderTime,
                        );
                        if (picked != null) {
                          settings.setReminderTime(picked);
                        }
                      },
                    ),
                ],
              ),
               const SizedBox(height: 20),

              _buildSectionHeader(context, 'Data'),
              _buildSettingsCard(
                context,
                children: [
                  ListTile(
                    leading: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Export Data'),
                    subtitle: const Text('Backup details as CSV'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                       Provider.of<ExpenseProvider>(context, listen: false).exportExpensesToCsv();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  void _editName(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                settings.setUserName(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
