import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyAutoCrop = 'settings_auto_crop';

  bool _autoCrop;

  bool get autoCrop => _autoCrop;

  SettingsProvider._(this._autoCrop);

  static Future<SettingsProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsProvider._(prefs.getBool(_keyAutoCrop) ?? true);
  }

  Future<void> setAutoCrop(bool value) async {
    if (_autoCrop == value) return;
    _autoCrop = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCrop, value);
  }
}
