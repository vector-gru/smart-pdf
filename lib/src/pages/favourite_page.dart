import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';
import '../db/docs_notifier.dart';
import '../widgets/document_card.dart';
import 'doc_actions.dart';
import 'viewer_page.dart';

class FavouritePage extends StatefulWidget {
  final DocsNotifier notifier;
  const FavouritePage({Key? key, required this.notifier}) : super(key: key);

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> with DocActionsMixin {
  @override
  AppDatabase get db => widget.notifier.db;
  @override
  DocsNotifier get notifier => widget.notifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListenableBuilder(
        listenable: widget.notifier,
        builder: (context, _) {
          final docs = widget.notifier.favourites;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline, size: AppConstants.emptyIconSize, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No favourites yet', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Star a document to see it here', style: TextStyle(color: AppColors.textSecondary)),
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
    );
  }
}
