import 'package:flutter/material.dart';
import 'src/db/app_db.dart';
import 'src/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DB (it opens the DB lazily)
  final db = AppDatabase();

  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  const MyApp({Key? key, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'smart-pdf (starter)',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: HomePage(db: db),
      debugShowCheckedModeBanner: false,
    );
  }
}