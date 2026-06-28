import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import 'src/constants/app_colors.dart';
import 'src/db/app_db.dart';
import 'src/l10n/locale_provider.dart';
import 'src/theme/theme_provider.dart';
import 'src/settings/settings_provider.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final settingsProvider = await SettingsProvider.load();
  runApp(MyApp(db: db, settingsProvider: settingsProvider));
}

class MyApp extends StatefulWidget {
  final AppDatabase db;
  final SettingsProvider settingsProvider;
  const MyApp({super.key, required this.db, required this.settingsProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LocaleProvider _localeProvider;
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    _localeProvider = LocaleProvider(deviceLocale);
    _localeProvider.addListener(() => setState(() {}));
    _themeProvider.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _localeProvider.dispose();
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPDF',
      locale: _localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleProvider.supportedLocales,
      themeMode: _themeProvider.themeMode,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.textPrimary,
          elevation: 1,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.dark,
      ),
      home: AppShell(
        db: widget.db,
        localeProvider: _localeProvider,
        themeProvider: _themeProvider,
        settingsProvider: widget.settingsProvider,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
