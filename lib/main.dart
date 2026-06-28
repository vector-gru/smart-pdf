import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import 'src/constants/app_colors.dart';
import 'src/db/app_db.dart';
import 'src/l10n/locale_provider.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  runApp(MyApp(db: db));
}

class MyApp extends StatefulWidget {
  final AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    _localeProvider = LocaleProvider(deviceLocale);
    _localeProvider.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _localeProvider.dispose();
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
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.textPrimary,
          elevation: 1,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      home: AppShell(db: widget.db, localeProvider: _localeProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
