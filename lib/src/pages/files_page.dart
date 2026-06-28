import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
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

  Future<void> _browseMoreFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    for (final file in result.files) {
      if (file.path == null) continue;
      await widget.db.importPdfFile(file.path!);
    }
    await widget.notifier.reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _searchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(hintText: l10n.homeSearchHint, border: InputBorder.none),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(l10n.filesTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          _buildMenuRow(Icons.folder_outlined, l10n.filesBrowseMore, _browseMoreFiles),
          const Divider(height: 1),
          _buildMenuRow(Icons.add_to_drive_outlined, l10n.filesSyncDrive, () {}),
          const Divider(height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.notifier,
              builder: (context, _) {
                final allDocs = widget.notifier.all;
                final docs = (allDocs.where((d) => d.isImported).toList())
                    .where((d) => _searchQuery.isEmpty || d.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 80, color: Colors.blue[100]),
                        const SizedBox(height: 16),
                        Text(l10n.filesEmpty, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(l10n.filesEmptySubtitle,
                            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
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
                      onEdit: null,
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
