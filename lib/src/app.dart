import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import 'widgets/app_drawer.dart';
import 'widgets/camera_capture_page.dart'
    show CameraCapturePage, IdCardCameraPage, IdCardCameraResult;
import 'constants/app_colors.dart';
import 'constants/app_constants.dart';
import 'db/app_db.dart';
import 'db/docs_notifier.dart';
import 'l10n/locale_provider.dart';
import 'theme/theme_provider.dart';
import 'settings/settings_provider.dart';
import 'pages/home_page.dart';
import 'pages/files_page.dart';
import 'db/collections_notifier.dart';
import 'pages/collections_page.dart';
import 'pages/favourite_page.dart';
import 'pages/scanner_page.dart' show ScannerPage, ScannerResult;
import 'pages/viewer_page.dart';
import 'package:image_picker/image_picker.dart';
import 'pages/id_card_edit_page.dart';

class AppShell extends StatefulWidget {
  final AppDatabase db;
  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;
  final SettingsProvider settingsProvider;
  const AppShell({
    super.key,
    required this.db,
    required this.localeProvider,
    required this.themeProvider,
    required this.settingsProvider,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final DocsNotifier _notifier;
  late final CollectionsNotifier _collectionsNotifier;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _notifier = DocsNotifier(widget.db);
    _collectionsNotifier = CollectionsNotifier(widget.db);
    _notifier.reload();
    _collectionsNotifier.reload();
    _initSharingIntent();
  }

  void _initSharingIntent() {
    // Only handle warm-start shares (app already running).
    // Cold-start initial media is handled in main.dart.
    ReceiveSharingIntent.instance.getMediaStream().listen(_handleSharedFiles);
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final pdfFile = files.firstWhere(
      (f) =>
          f.path.toLowerCase().endsWith('.pdf') ||
          (f.mimeType?.toLowerCase() == 'application/pdf'),
      orElse: () => SharedMediaFile(
        path: '',
        mimeType: null,
        thumbnail: null,
        type: SharedMediaType.file,
      ),
    );
    if (pdfFile.path.isEmpty) return;
    ReceiveSharingIntent.instance.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rawPath = pdfFile.path;
      // Derive a display title: use last path segment, strip query params
      final segment = rawPath.split('/').last.split('?').first;
      final title = segment.toLowerCase().endsWith('.pdf')
          ? segment
          : (pdfFile.mimeType != null ? segment : rawPath.split('/').last);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ViewerPage(pdfPath: rawPath, title: title),
        ),
      );
    });
  }

  @override
  void dispose() {
    _notifier.dispose();
    _collectionsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        db: widget.db,
        notifier: _notifier,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      FilesPage(db: widget.db, notifier: _notifier),
      CollectionsPage(
        db: widget.db,
        collectionsNotifier: _collectionsNotifier,
        docsNotifier: _notifier,
      ),
      FavouritePage(notifier: _notifier),
    ];
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: AppDrawer(
        localeProvider: widget.localeProvider,
        themeProvider: widget.themeProvider,
        settingsProvider: widget.settingsProvider,
      ),
      body: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).padding.bottom;
          return Stack(
            children: [
              IndexedStack(index: _currentIndex, children: pages),
              Positioned(
                right: 16,
                bottom: bottomInset + 32,
                child: _ScanFab(
                  db: widget.db,
                  notifier: _notifier,
                  settingsProvider: widget.settingsProvider,
                ),
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

  static const _icons = [
    (Icons.home_outlined, Icons.home),
    (Icons.description_outlined, Icons.description),
    (Icons.folder_copy_outlined, Icons.folder_copy),
    (Icons.star_outline, Icons.star),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.navHome,
      l10n.navFiles,
      l10n.navCollections,
      l10n.navFavourite,
    ];
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
            children: List.generate(_icons.length, (i) {
              final selected = i == currentIndex;
              final item = _icons[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.$2 : item.$1,
                        color: selected
                            ? AppColors.primaryMuted
                            : AppColors.navUnselected,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: selected
                              ? AppColors.primaryMuted
                              : AppColors.navUnselected,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
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
  final SettingsProvider settingsProvider;
  const _ScanFab({
    required this.db,
    required this.notifier,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.fabRadius),
        color: AppColors.primaryMuted,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppConstants.fabRadius),
              ),
              onTap: () => _showScanTypeSheet(context, useCamera: false),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.fabPaddingH,
                  vertical: AppConstants.fabPaddingV,
                ),
                child: Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: AppConstants.fabIconSize,
                ),
              ),
            ),
          ),
          Container(
            width: AppConstants.fabDividerWidth,
            height: AppConstants.fabDividerHeight,
            color: AppColors.fabDivider,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppConstants.fabRadius),
              ),
              onTap: () => _showScanTypeSheet(context, useCamera: true),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.fabPaddingH,
                  vertical: AppConstants.fabPaddingV,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: AppConstants.fabIconSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet letting the user pick Standard or ID Card scan mode,
  /// then proceeds with [useCamera] (camera) or gallery accordingly.
  void _showScanTypeSheet(BuildContext context, {required bool useCamera}) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.scannerScanTypeTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Standard
              _ScanTypeOption(
                icon: Icons.description_outlined,
                title: l10n.scannerScanTypeStandard,
                subtitle: l10n.scannerScanTypeStandardSub,
                onTap: () {
                  Navigator.pop(ctx);
                  if (useCamera) {
                    _openCamera(context);
                  } else {
                    _openGallery(context);
                  }
                },
              ),
              const SizedBox(height: 8),
              // ID Card
              _ScanTypeOption(
                icon: Icons.credit_card,
                title: l10n.scannerScanTypeIdCard,
                subtitle: l10n.scannerScanTypeIdCardSub,
                onTap: () {
                  Navigator.pop(ctx);
                  if (useCamera) {
                    _openIdCardCamera(context);
                  } else {
                    _openIdCardGallery(context);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Standard scan ───────────────────────────────────────────────────────

  void _openGallery(BuildContext context) async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 90);
    if (images.isEmpty || !context.mounted) return;
    _navigate(context, images.map((f) => f.path).toList());
  }

  void _openCamera(BuildContext context) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      if (!context.mounted) return;
      final path = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => CameraCapturePage(camera: rear)),
      );
      if (path == null) return;
      if (!context.mounted) return;
      _navigate(context, [path]);
    } catch (_) {}
  }

  // ─── ID Card scan ─────────────────────────────────────────────────────────

  /// Camera flow: single session, front then back, then ID card editor.
  void _openIdCardCamera(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      if (!context.mounted) return;

      final shotResult = await Navigator.of(context).push<IdCardCameraResult>(
        MaterialPageRoute(
          builder: (_) => IdCardCameraPage(
            camera: rear,
            frontLabel: l10n.scannerIdCardFront,
            backLabel: l10n.scannerIdCardBack,
          ),
        ),
      );
      if (shotResult == null || !context.mounted) return;
      await _openIdCardEditor(
        context,
        shotResult.frontPath,
        shotResult.backPath,
      );
    } catch (_) {}
  }

  /// Gallery flow: picks up to 2 images at once.
  ///   - 2 selected → front + back immediately.
  ///   - 1 selected → prompt for the second separately.
  void _openIdCardGallery(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.scannerIdCardGalleryInstructions),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 400));

    final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
    if (picked.isEmpty || !context.mounted) return;

    String frontPath = picked.first.path;
    String backPath;

    if (picked.length >= 2) {
      backPath = picked[1].path;
    } else {
      // Only one — ask for the second
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scannerIdCardSelectBack),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 400));
      final backFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (backFile == null || !context.mounted) return;
      backPath = backFile.path;
    }

    await _openIdCardEditor(context, frontPath, backPath);
  }

  /// Opens the ID card editor for layout + rotation, then navigates to the scanner.
  Future<void> _openIdCardEditor(
    BuildContext context,
    String frontPath,
    String backPath,
  ) async {
    if (!context.mounted) return;
    final editResult = await Navigator.of(context).push<IdCardEditResult>(
      MaterialPageRoute(
        builder: (_) =>
            IdCardEditPage(frontPath: frontPath, backPath: backPath),
      ),
    );
    if (editResult == null || !context.mounted) return;
    _navigate(context, [editResult.compositePath]);
  }

  // ─── Navigate to ScannerPage ──────────────────────────────────────────────

  void _navigate(BuildContext context, List<String> paths) async {
    if (!context.mounted) return;
    final result = await Navigator.of(context).push<ScannerResult>(
      MaterialPageRoute(
        builder: (_) => ScannerPage(
          initialImages: paths,
          autoCrop: settingsProvider.autoCrop,
        ),
      ),
    );
    if (result != null && result.images.isNotEmpty) {
      final created = await db.createDocumentFromImages(
        result.title,
        result.images,
        originals: result.originals,
      );
      await notifier.reload();
      final doc = await db.getDocumentById(created);
      if (doc != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ViewerPage(pdfPath: doc.filePath, title: doc.title),
          ),
        );
      }
    }
  }
}

/// A tappable card used inside the scan-type bottom sheet.
class _ScanTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryMuted, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
