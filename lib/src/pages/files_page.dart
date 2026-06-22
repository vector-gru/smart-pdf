import 'package:flutter/material.dart';
import '../db/app_db.dart';

class FilesPage extends StatelessWidget {
  final AppDatabase db;
  const FilesPage({Key? key, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      body: const Center(child: Text('Files', style: TextStyle(fontSize: 18))),
    );
  }
}
