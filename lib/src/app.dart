import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'constants/app_constants.dart';
import 'db/app_db.dart';
import 'db/docs_notifier.dart';
import 'pages/home_page.dart';
import 'pages/files_page.dart';
import 'pages/recent_page.dart';
import 'pages/favourite_page.dart';
import 'pages/scanner_page.dart' show ScannerPage, ScannerResult;
import 'pages/viewer_page.dart';
import 'package:image_picker/image_picker.dart';

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
      extendBody: true,
      body: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).padding.bottom;
          return Stack(
            children: [
              IndexedStack(index: _currentIndex, children: pages),
              Positioned(
                right: 16,
                bottom: bottomInset + 32,
                child: _ScanFab(db: widget.db, notifier: _notifier),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.description_outlined, Icons.description, 'Files'),
    (Icons.access_time_outlined, Icons.access_time_filled, 'Recent'),
    (Icons.star_outline, Icons.star, 'Favourite'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              final item = _items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.$2 : item.$1,
                        color: selected ? AppColors.primaryMuted : AppColors.navUnselected,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? AppColors.primaryMuted : AppColors.navUnselected,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  final AppDatabase db;
  final DocsNotifier notifier;
  const _ScanFab({required this.db, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.fabRadius),
        color: AppColors.primaryMuted,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppConstants.fabRadius)),
              onTap: () => _openGallery(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppConstants.fabPaddingH, vertical: AppConstants.fabPaddingV),
                child: Icon(Icons.photo_library, color: Colors.white, size: AppConstants.fabIconSize),
              ),
            ),
          ),
          Container(width: AppConstants.fabDividerWidth, height: AppConstants.fabDividerHeight, color: AppColors.fabDivider),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppConstants.fabRadius)),
              onTap: () => _openCamera(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppConstants.fabPaddingH, vertical: AppConstants.fabPaddingV),
                child: Icon(Icons.camera_alt, color: Colors.white, size: AppConstants.fabIconSize),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext context) async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 90);
    if (images.isEmpty) return;
    _navigate(context, images.map((f) => f.path).toList());
  }

  void _openCamera(BuildContext context) async {
    final picker = ImagePicker();
    if (!await picker.supportsImageSource(ImageSource.camera)) return;
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (photo == null) return;
    _navigate(context, [photo.path]);
  }

  void _navigate(BuildContext context, List<String> paths) async {
    final result = await Navigator.of(context).push<ScannerResult>(
      MaterialPageRoute(builder: (_) => ScannerPage(initialImages: paths)),
    );
    if (result != null && result.images.isNotEmpty) {
      final created = await db.createDocumentFromImages(result.title, result.images);
      await notifier.reload();
      final doc = await db.getDocumentById(created);
      if (doc != null && context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ViewerPage(pdfPath: doc.filePath, title: doc.title),
        ));
      }
    }
  }
}
