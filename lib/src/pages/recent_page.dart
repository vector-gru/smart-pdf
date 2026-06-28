import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';
import '../db/docs_notifier.dart';
import '../widgets/document_card.dart';
import 'doc_actions.dart';
import 'viewer_page.dart';

class RecentPage extends StatefulWidget {
  final DocsNotifier notifier;
  const RecentPage({Key? key, required this.notifier}) : super(key: key);

  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage> with DocActionsMixin {
  @override
  AppDatabase get db => widget.notifier.db;
  @override
  DocsNotifier get notifier => widget.notifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListenableBuilder(
        listenable: widget.notifier,
        builder: (context, _) {
          final docs = widget.notifier.recent.where((d) => !d.isImported).toList();
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: AppConstants.emptyIconSize, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No recent documents', style: TextStyle(fontSize: 18)),
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
}
