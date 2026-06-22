import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';
import '../widgets/document_card.dart';
import 'scanner_page.dart';
import 'viewer_page.dart';

class HomePage extends StatefulWidget {
  final AppDatabase db;
  const HomePage({super.key, required this.db});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Document>>? _docsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  void _loadDocs() {
    _docsFuture = widget.db.getAllDocuments();
    setState(() {});
  }

  Future<void> _deleteDoc(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Are you sure you want to delete "${doc.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final f = File(doc.filePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await widget.db.deleteDocumentById(doc.id);
    _loadDocs();
  }

  void _shareDoc(Document doc) {
    Share.shareXFiles([XFile(doc.filePath)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Text('PDF Scanner', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: AppColors.crown),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<Document>>(
        future: _docsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data ?? [];
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
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewerPage(pdfPath: d.filePath)));
                },
                onShare: () => _shareDoc(d),
                onDelete: () => _deleteDoc(d),
                onExport: () {},
                onMore: () => _showMoreMenu(d),
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
              onTap: _importImages,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppConstants.fabPaddingH, vertical: AppConstants.fabPaddingV),
                child: Icon(Icons.photo_library, color: Colors.white, size: AppConstants.fabIconSize),
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
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppConstants.fabRadius)),
              onTap: _openScanner,
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

  void _openScanner() async {
    final result = await Navigator.of(context).push<List<String>>(MaterialPageRoute(builder: (_) => ScannerPage()));
    if (result != null && result.isNotEmpty) {
      final title = await _askRename(context, 'Document_${DateTime.now().millisecondsSinceEpoch}');
      if (title == null) return;
      final created = await widget.db.createDocumentFromImages(title.trim(), result);
      _loadDocs();
      final doc = await widget.db.getDocumentById(created);
      if (doc != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewerPage(pdfPath: doc.filePath)));
      }
    }
  }

  void _importImages() async {
    // TODO: image picker import flow
  }

  void _showMoreMenu(Document doc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit), title: const Text('Rename'), onTap: () async {
              Navigator.pop(ctx);
              final newTitle = await _askRename(context, doc.title);
              if (newTitle != null && newTitle.trim().isNotEmpty) {
                await widget.db.renameDocument(doc.id, newTitle.trim());
                _loadDocs();
              }
            }),
            ListTile(leading: const Icon(Icons.star_outline), title: const Text('Favourite'), onTap: () {
              Navigator.pop(ctx);
            }),
            ListTile(leading: const Icon(Icons.print), title: const Text('Print'), onTap: () {
              Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    );
  }

  Future<String?> _askRename(BuildContext context, String current) {
    final ctr = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Document name'),
        content: TextField(controller: ctr, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctr.text), child: const Text('Save')),
        ],
      ),
    );
  }
}
