import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';
import '../db/docs_notifier.dart';
import '../widgets/app_drawer.dart';
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
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
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
      drawer: AppDrawer(
        onImportFiles: () {},
        onImportImages: _openGallery,
      ),
      body: ListenableBuilder(
        listenable: widget.notifier,
        builder: (context, _) {
          final allDocs = widget.notifier.all;
          final docs = (allDocs.where((d) => !d.isImported).toList())
              .where((d) => _searchQuery.isEmpty || d.title.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
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
            padding: const EdgeInsets.only(
              top: AppConstants.listTopPadding,
              bottom: 64 + 12 + 16 + 48 + AppConstants.listBottomPadding,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              return DocumentCard(
                document: d,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewerPage(pdfPath: d.filePath, title: d.title))),
                onShare: (rect) => shareDoc(d, rect),
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
    );
  }

  void _openGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 90);
    if (images.isEmpty || !mounted) return;
    final result = await Navigator.of(context).push<ScannerResult>(
      MaterialPageRoute(builder: (_) => ScannerPage(initialImages: images.map((f) => f.path).toList())),
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
