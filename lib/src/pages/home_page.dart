import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';
import '../db/docs_notifier.dart';
import '../widgets/document_card.dart';
import 'doc_actions.dart';
import 'scanner_page.dart' show ScannerPage, ScannerResult;
import 'viewer_page.dart';

class HomePage extends StatefulWidget {
  final AppDatabase db;
  final DocsNotifier notifier;
  const HomePage({super.key, required this.db, required this.notifier});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with DocActionsMixin {
  bool _searchActive = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  AppDatabase get db => widget.db;
  @override
  DocsNotifier get notifier => widget.notifier;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: _searchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Search documents…', border: InputBorder.none),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('SmartPDF', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.emoji_events, color: AppColors.crown), onPressed: () {}),
          IconButton(
            icon: Icon(_searchActive ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searchActive = !_searchActive;
              if (!_searchActive) { _searchQuery = ''; _searchController.clear(); }
            }),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.notifier,
        builder: (context, _) {
          final allDocs = widget.notifier.all;
          final docs = _searchQuery.isEmpty
              ? allDocs
              : allDocs.where((d) => d.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf, size: AppConstants.emptyIconSize, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No documents yet', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Tap the button below to scan or import', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppConstants.listTopPadding, bottom: AppConstants.listBottomPadding),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              return DocumentCard(
                document: d,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewerPage(pdfPath: d.filePath, title: d.title))),
                onShare: () => shareDoc(d),
                onDelete: () => deleteDoc(d),
                onEdit: () => editDoc(d),
                onFavourite: () => toggleFavourite(d),
                onRename: () => renameDoc(d),
                onPrint: () => printDoc(d),
              );
            },
          );
        },
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.fabRadius),
        color: AppColors.primaryMuted,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppConstants.fabRadius)),
              onTap: _openGallery,
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
              onTap: _openCamera,
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

  void _openCamera() async {
    final picker = ImagePicker();
    final hasCamera = await picker.supportsImageSource(ImageSource.camera);
    if (!hasCamera) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera not available')));
      return;
    }
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (photo == null || !mounted) return;
    _navigateToScanner([photo.path]);
  }

  void _openGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 90);
    if (images.isEmpty || !mounted) return;
    _navigateToScanner(images.map((f) => f.path).toList());
  }

  void _navigateToScanner(List<String> paths) async {
    final result = await Navigator.of(context).push<ScannerResult>(
      MaterialPageRoute(builder: (_) => ScannerPage(initialImages: paths)),
    );
    if (result != null && result.images.isNotEmpty && mounted) {
      final created = await widget.db.createDocumentFromImages(result.title, result.images);
      await notifier.reload();
      final doc = await widget.db.getDocumentById(created);
      if (doc != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewerPage(pdfPath: doc.filePath, title: doc.title)));
      }
    }
  }
}
