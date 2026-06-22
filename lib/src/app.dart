import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'db/app_db.dart';
import 'db/docs_notifier.dart';
import 'pages/home_page.dart';
import 'pages/files_page.dart';
import 'pages/recent_page.dart';
import 'pages/favourite_page.dart';

class AppShell extends StatefulWidget {
  final AppDatabase db;
  const AppShell({super.key, required this.db});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final DocsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = DocsNotifier(widget.db);
    _notifier.reload();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(db: widget.db, notifier: _notifier),
      FilesPage(db: widget.db, notifier: _notifier),
      RecentPage(notifier: _notifier),
      FavouritePage(notifier: _notifier),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryMuted,
        unselectedItemColor: AppColors.navUnselected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Recent'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favourite'),
        ],
      ),
    );
  }
}
