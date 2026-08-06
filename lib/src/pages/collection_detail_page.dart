import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';
import '../db/collections_notifier.dart';
import '../db/docs_notifier.dart';
import '../widgets/bottom_sheet_handle.dart';
import '../widgets/doc_thumbnail.dart';
import '../widgets/document_card.dart';
import 'collections_page.dart'
    show colorForCollectionHex, iconForCollectionName;
import 'doc_actions.dart';
import 'viewer_page.dart';

// ── Detail page ───────────────────────────────────────────────────────────────

class CollectionDetailPage extends StatefulWidget {
  final AppDatabase db;
  final Collection collection;
  final DocsNotifier docsNotifier;
  final CollectionsNotifier collectionsNotifier;

  const CollectionDetailPage({
    super.key,
    required this.db,
    required this.collection,
    required this.docsNotifier,
    required this.collectionsNotifier,
  });

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage>
    with DocActionsMixin {
  @override
  AppDatabase get db => widget.db;

  @override
  DocsNotifier get notifier => widget.docsNotifier;

  List<Document> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() => _loading = true);
    final docs = await widget.db.getDocumentsInCollection(widget.collection.id);
    if (mounted)
      setState(() {
        _docs = docs;
        _loading = false;
      });
  }

  // ── Remove from collection ────────────────────────────────────────────────

  Future<void> _removeFromCollection(Document doc) async {
    await widget.db.removeDocumentFromCollection(
      collectionId: widget.collection.id,
      documentId: doc.id,
    );
    await Future.wait([_loadDocs(), widget.collectionsNotifier.reload()]);
  }

  // ── Add documents sheet ───────────────────────────────────────────────────

  Future<void> _showAddDocumentsSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final alreadyIn = await widget.db.getDocumentIdsInCollection(
      widget.collection.id,
    );
    final available = widget.docsNotifier.all
        .where((d) => !alreadyIn.contains(d.id))
        .toList();

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.collectionsAddNoneAvailable)));
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.sheetRadiusLarge),
        ),
      ),
      builder: (ctx) => _AddDocumentsSheet(
        available: available,
        db: widget.db,
        collectionId: widget.collection.id,
        onDone: () async {
          await Future.wait([_loadDocs(), widget.collectionsNotifier.reload()]);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = colorForCollectionHex(widget.collection.colorHex);
    final icon = iconForCollectionName(widget.collection.iconName);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: AppConstants.collectionDetailExpandedHeight,
            floating: false,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(
                AppConstants.collectionDetailHeaderPaddingL,
                0,
                AppConstants.collectionDetailHeaderPaddingR,
                AppConstants.collectionDetailHeaderPaddingB,
              ),
              title: Text(
                widget.collection.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppConstants.collectionDetailTitleFontSize,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.70)],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      icon,
                      size: AppConstants.collectionDetailBgIconSize,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.playlist_add),
                tooltip: l10n.collectionsAddDocuments,
                onPressed: _showAddDocumentsSheet,
              ),
            ],
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _docs.isEmpty
            ? _EmptyCollectionBody(onAddTap: _showAddDocumentsSheet)
            : ListView.builder(
                padding: const EdgeInsets.only(
                  top: AppConstants.listTopPadding,
                  bottom:
                      AppConstants.listBottomPadding +
                      AppConstants.collectionDetailFabBottomPad,
                ),
                itemCount: _docs.length,
                itemBuilder: (context, index) {
                  final d = _docs[index];
                  return Dismissible(
                    key: ValueKey(d.id),
                    direction: DismissDirection.endToStart,
                    background: _SwipeRemoveBackground(l10n: l10n),
                    confirmDismiss: (_) async {
                      await _removeFromCollection(d);
                      return false;
                    },
                    child: DocumentCard(
                      document: d,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ViewerPage(pdfPath: d.filePath, title: d.title),
                        ),
                      ),
                      onShare: (rect) => shareDoc(d, rect),
                      onDelete: () => deleteDoc(d).then((_) => _loadDocs()),
                      onEdit: () => editDoc(d).then((_) => _loadDocs()),
                      onFavourite: () => toggleFavourite(d),
                      onRename: () => renameDoc(d).then((_) => _loadDocs()),
                      onPrint: () => printDoc(d),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: _docs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showAddDocumentsSheet,
              icon: const Icon(Icons.add),
              label: Text(l10n.collectionsAddDocuments),
              backgroundColor: color,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

// ── Swipe-to-remove background ────────────────────────────────────────────────

class _SwipeRemoveBackground extends StatelessWidget {
  final AppLocalizations l10n;
  const _SwipeRemoveBackground({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(
        right: AppConstants.collectionSwipePaddingR,
      ),
      color: Colors.red.shade400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.remove_circle_outline,
            color: Colors.white,
            size: AppConstants.collectionSwipeIconSize,
          ),
          const SizedBox(height: AppConstants.collectionSwipeLabelGap),
          Text(
            l10n.collectionsSwipeToRemove,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppConstants.collectionSwipeLabelFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty body ────────────────────────────────────────────────────────────────

class _EmptyCollectionBody extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyCollectionBody({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.collectionDetailEmptyPaddingH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: AppConstants.collectionDetailEmptyIconSize,
              color: Colors.grey[350],
            ),
            const SizedBox(height: AppConstants.collectionDetailEmptyIconGap),
            Text(
              l10n.collectionsDetailEmpty,
              style: const TextStyle(
                fontSize: AppConstants.collectionDetailEmptyTitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.collectionDetailEmptyTitleGap),
            Text(
              l10n.collectionsDetailEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppConstants.collectionDetailEmptySubtitleFontSize,
                color: AppColors.textSecondary,
                height: AppConstants.collectionDetailEmptySubtitleLineHeight,
              ),
            ),
            const SizedBox(height: AppConstants.collectionDetailEmptyButtonGap),
            FilledButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add),
              label: Text(l10n.collectionsAddDocuments),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add-documents bottom sheet ────────────────────────────────────────────────

class _AddDocumentsSheet extends StatefulWidget {
  final List<Document> available;
  final AppDatabase db;
  final String collectionId;
  final Future<void> Function() onDone;

  const _AddDocumentsSheet({
    required this.available,
    required this.db,
    required this.collectionId,
    required this.onDone,
  });

  @override
  State<_AddDocumentsSheet> createState() => _AddDocumentsSheetState();
}

class _AddDocumentsSheetState extends State<_AddDocumentsSheet> {
  final Set<String> _selected = {};
  bool _saving = false;

  Future<void> _save() async {
    if (_selected.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    for (final id in _selected) {
      await widget.db.addDocumentToCollection(
        collectionId: widget.collectionId,
        documentId: id,
      );
    }
    await widget.onDone();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: AppConstants.collectionSheetInitialSize,
      minChildSize: AppConstants.collectionSheetMinSize,
      maxChildSize: AppConstants.collectionSheetMaxSize,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const BottomSheetHandle(),

          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.collectionSheetHeaderPaddingL,
              0,
              AppConstants.collectionSheetHeaderPaddingR,
              AppConstants.collectionSheetHeaderPaddingB,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.collectionsAddDocuments,
                        style: const TextStyle(
                          fontSize: AppConstants.collectionSheetTitleFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_selected.isNotEmpty)
                        Text(
                          l10n.collectionsSelectedCount(_selected.length),
                          style: const TextStyle(
                            fontSize: AppConstants
                                .collectionSheetSelectedCountFontSize,
                            color: AppColors.primaryMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                _saving
                    ? const SizedBox(
                        width: AppConstants.collectionSheetSpinnerSize,
                        height: AppConstants.collectionSheetSpinnerSize,
                        child: CircularProgressIndicator(
                          strokeWidth:
                              AppConstants.collectionSheetSpinnerStrokeWidth,
                        ),
                      )
                    : FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryMuted,
                          padding: const EdgeInsets.symmetric(
                            horizontal:
                                AppConstants.collectionSheetSaveButtonPaddingH,
                            vertical:
                                AppConstants.collectionSheetSaveButtonPaddingV,
                          ),
                        ),
                        child: Text(l10n.collectionsAddButton),
                      ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Document list with checkboxes
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: widget.available.length,
              itemBuilder: (context, index) {
                final doc = widget.available[index];
                final selected = _selected.contains(doc.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (_) => setState(() {
                    selected ? _selected.remove(doc.id) : _selected.add(doc.id);
                  }),
                  activeColor: AppColors.primaryMuted,
                  secondary: DocThumbnail(thumbnailPath: doc.thumbnailPath),
                  title: Text(
                    doc.title,
                    style: const TextStyle(
                      fontSize: AppConstants.collectionSheetDocTitleFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    doc.isImported
                        ? l10n.collectionsDocTypeImported
                        : l10n.collectionsDocTypeScanned,
                    style: const TextStyle(
                      fontSize: AppConstants.collectionSheetDocSubtitleFontSize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
