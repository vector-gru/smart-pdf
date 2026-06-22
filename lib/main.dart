import 'package:flutter/material.dart';
import 'src/constants/app_colors.dart';
import 'src/db/app_db.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPDF',
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.textPrimary,
          elevation: 1,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      home: AppShell(db: db),
      debugShowCheckedModeBanner: false,
    );
  }
}
