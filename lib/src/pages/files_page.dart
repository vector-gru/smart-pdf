import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';
import '../db/docs_notifier.dart';
import '../widgets/document_card.dart';
import 'doc_actions.dart';
import 'viewer_page.dart';

class FilesPage extends StatefulWidget {
  final AppDatabase db;
  final DocsNotifier notifier;
  const FilesPage({Key? key, required this.db, required this.notifier}) : super(key: key);

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> with DocActionsMixin {
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
            : const Text('Files', style: TextStyle(fontWeight: FontWeight.w600)),
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
      body: Column(
        children: [
          _buildMenuRow(Icons.folder_outlined, 'Browse more files', () {}),
          const Divider(height: 1),
          _buildMenuRow(Icons.add_to_drive_outlined, 'Sync with Google Drive', () {}),
          const Divider(height: 1),
          Expanded(
            child: ListenableBuilder(
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
                        Icon(Icons.inbox_outlined, size: 80, color: Colors.blue[100]),
                        const SizedBox(height: 16),
                        const Text('No files yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Start adding PDF files to build your digital library!',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 26, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
