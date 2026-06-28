import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, device }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.device;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode => switch (_mode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.device => ThemeMode.system,
  };

  void setMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
