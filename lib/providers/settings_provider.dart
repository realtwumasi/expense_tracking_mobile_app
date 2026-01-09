import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _isReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0); // Default 8 PM
  ThemeMode _themeMode = ThemeMode.light;
  String _currencySymbol = '\$';

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  bool get isReminderEnabled => _isReminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 1; // Default to 1 (Light)
    _currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    
    _isReminderEnabled = prefs.getBool('reminder_enabled') ?? false;
    final timeString = prefs.getString('reminder_time');
    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    switch (themeIndex) {
      case 1:
        _themeMode = ThemeMode.light;
        break;
      case 2:
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    int themeIndex = 0;
    if (mode == ThemeMode.light) themeIndex = 1;
    if (mode == ThemeMode.dark) themeIndex = 2;
    await prefs.setInt('theme_mode', themeIndex);
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
  }

  Future<void> toggleReminder(bool isEnabled) async {
    _isReminderEnabled = isEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', isEnabled);
    
    // Schedule or Cancel
    if (isEnabled) {
      await NotificationService().scheduleDailyNotification(_reminderTime);
    } else {
      await NotificationService().cancelAll();
    }
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_time', '${time.hour}:${time.minute}');
    
    // Reschedule if enabled
    if (_isReminderEnabled) {
      await NotificationService().scheduleDailyNotification(time);
    }
  }
}
