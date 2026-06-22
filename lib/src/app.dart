import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'db/app_db.dart';
import 'pages/home_page.dart';
import 'pages/files_page.dart';

class AppShell extends StatefulWidget {
  final AppDatabase db;
  const AppShell({super.key, required this.db});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(db: widget.db),
      FilesPage(db: widget.db),
      _PlaceholderPage(title: 'Recent'),
      _PlaceholderPage(title: 'Favourite'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
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

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 18))),
    );
  }
}
