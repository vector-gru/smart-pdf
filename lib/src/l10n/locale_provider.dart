import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  static const supportedLocales = [Locale('en'), Locale('fr')];
  static const _fallback = Locale('en');

  Locale _locale;

  LocaleProvider(Locale deviceLocale)
      : _locale = _resolve(deviceLocale);

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  static Locale _resolve(Locale device) {
    final match = supportedLocales.where(
      (l) => l.languageCode == device.languageCode,
    );
    return match.isNotEmpty ? match.first : _fallback;
  }
}
