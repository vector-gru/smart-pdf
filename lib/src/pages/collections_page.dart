import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';
import '../db/collections_notifier.dart';
import '../db/docs_notifier.dart';
import '../widgets/bottom_sheet_handle.dart';
import 'collection_detail_page.dart';

// ── Colour / icon palettes ────────────────────────────────────────────────────

const _kPaletteColors = <Color>[
  Color(0xFF9E8A4F), // default gold
  Color(0xFF2196F3), // blue
  Color(0xFF4CAF50), // green
  Color(0xFFE91E63), // pink
  Color(0xFF9C27B0), // purple
  Color(0xFFFF9800), // orange
  Color(0xFF00BCD4), // teal
  Color(0xFFF44336), // red
  Color(0xFF607D8B), // blue-grey
  Color(0xFF795548), // brown
];

const _kPaletteIcons = <(String, IconData)>[
  ('folder', Icons.folder_rounded),
  ('work', Icons.work_rounded),
  ('school', Icons.school_rounded),
  ('receipt', Icons.receipt_long_rounded),
  ('health', Icons.local_hospital_rounded),
  ('home', Icons.home_rounded),
  ('travel', Icons.flight_rounded),
  ('star', Icons.star_rounded),
  ('lock', Icons.lock_rounded),
  ('book', Icons.menu_book_rounded),
];

// ── Helpers ───────────────────────────────────────────────────────────────────

IconData iconForCollectionName(String name) => _kPaletteIcons
    .firstWhere((e) => e.$1 == name, orElse: () => _kPaletteIcons.first)
    .$2;

Color colorForCollectionHex(String hex) {
  try {
    final v = hex.replaceFirst('#', '');
    return Color(int.parse('FF$v', radix: 16));
  } catch (_) {
    return AppColors.primaryMuted;
  }
}

String _colorToHex(Color c) {
  final rgb = c.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

// ── Page ──────────────────────────────────────────────────────────────────────

class CollectionsPage extends StatefulWidget {
  final AppDatabase db;
  final CollectionsNotifier collectionsNotifier;
  final DocsNotifier docsNotifier;

  const CollectionsPage({
    super.key,
    required this.db,
    required this.collectionsNotifier,
    required this.docsNotifier,
  });

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.collectionsNotifier.reload(),
    );
  }

  // ── Create / edit dialog ───────────────────────────────────────────────────

  Future<void> _showCreateEditDialog({Collection? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    Color pickedColor = existing != null
        ? colorForCollectionHex(existing.colorHex)
        : _kPaletteColors.first;
    String pickedIcon = existing?.iconName ?? _kPaletteIcons.first.$1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.collectionDialogRadius,
            ),
          ),
          title: Text(
            existing == null
                ? l10n.collectionsNewCollection
                : l10n.collectionsEditCollection,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.collectionsNameLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppConstants.collectionEmptySubtitleGap),

                // Colour picker
                _PickerSectionLabel(l10n.collectionsColourLabel),
                const SizedBox(height: AppConstants.collectionPickerSpacing),
                Wrap(
                  spacing: AppConstants.collectionPickerSpacing,
                  runSpacing: AppConstants.collectionPickerSpacing,
                  children: _kPaletteColors.map((c) {
                    final selected = c.toARGB32() == pickedColor.toARGB32();
                    return _ColorSwatch(
                      color: c,
                      selected: selected,
                      onTap: () => setS(() => pickedColor = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.collectionEmptySubtitleGap),

                // Icon picker
                _PickerSectionLabel(l10n.collectionsIconLabel),
                const SizedBox(height: AppConstants.collectionPickerSpacing),
                Wrap(
                  spacing: AppConstants.collectionPickerSpacing,
                  runSpacing: AppConstants.collectionPickerSpacing,
                  children: _kPaletteIcons.map((e) {
                    final selected = e.$1 == pickedIcon;
                    return _IconSwatch(
                      iconData: e.$2,
                      selected: selected,
                      accentColor: pickedColor,
                      onTap: () => setS(() => pickedIcon = e.$1),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.docActionCancel),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryMuted,
              ),
              child: Text(l10n.docActionSave),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final name = nameCtrl.text.trim();
    final hex = _colorToHex(pickedColor);

    if (existing == null) {
      await widget.db.createCollection(
        name: name,
        colorHex: hex,
        iconName: pickedIcon,
      );
    } else {
      await widget.db.renameCollection(existing.id, name);
      await widget.db.updateCollectionAppearance(
        existing.id,
        colorHex: hex,
        iconName: pickedIcon,
      );
    }
    await widget.collectionsNotifier.reload();
  }

  // ── Delete confirmation ────────────────────────────────────────────────────

  Future<void> _confirmDelete(CollectionSummary summary) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.collectionDialogRadius,
          ),
        ),
        title: Text(l10n.collectionsDeleteTitle),
        content: Text(l10n.collectionsDeleteContent(summary.collection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.docActionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.docActionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.db.deleteCollection(summary.collection.id);
    await widget.collectionsNotifier.reload();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.collectionsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.collectionsNewCollection,
            onPressed: _showCreateEditDialog,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.collectionsNotifier,
        builder: (context, _) {
          if (widget.collectionsNotifier.loading &&
              widget.collectionsNotifier.summaries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final summaries = widget.collectionsNotifier.summaries;
          if (summaries.isEmpty) {
            return _CollectionsEmptyState(onCreateTap: _showCreateEditDialog);
          }
          return _CollectionsGrid(
            summaries: summaries,
            onTap: (s) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CollectionDetailPage(
                  db: widget.db,
                  collection: s.collection,
                  docsNotifier: widget.docsNotifier,
                  collectionsNotifier: widget.collectionsNotifier,
                ),
              ),
            ),
            onEdit: (s) => _showCreateEditDialog(existing: s.collection),
            onDelete: _confirmDelete,
          );
        },
      ),
    );
  }
}

// ── Grid ──────────────────────────────────────────────────────────────────────

class _CollectionsGrid extends StatelessWidget {
  final List<CollectionSummary> summaries;
  final void Function(CollectionSummary) onTap;
  final void Function(CollectionSummary) onEdit;
  final void Function(CollectionSummary) onDelete;

  const _CollectionsGrid({
    required this.summaries,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        AppConstants.collectionGridPaddingH,
        AppConstants.collectionGridPaddingTop,
        AppConstants.collectionGridPaddingH,
        AppConstants.collectionGridPaddingBottom,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.collectionGridCrossAxisCount,
        crossAxisSpacing: AppConstants.collectionGridSpacing,
        mainAxisSpacing: AppConstants.collectionGridSpacing,
        childAspectRatio: AppConstants.collectionGridChildAspectRatio,
      ),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final s = summaries[index];
        return _CollectionCard(
          summary: s,
          onTap: () => onTap(s),
          onEdit: () => onEdit(s),
          onDelete: () => onDelete(s),
        );
      },
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _CollectionCard extends StatelessWidget {
  final CollectionSummary summary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CollectionCard({
    required this.summary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = summary.collection;
    final color = colorForCollectionHex(c.colorHex);
    final icon = iconForCollectionName(c.iconName);

    return Card(
      elevation: AppConstants.collectionCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.collectionCardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context, l10n),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Coloured header with thumbnail + icon ──────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (summary.coverThumbnailPath != null)
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        color.withValues(alpha: 0.30),
                        BlendMode.srcOver,
                      ),
                      child: Image.file(
                        File(summary.coverThumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _CollectionGradientBg(color: color),
                      ),
                    )
                  else
                    _CollectionGradientBg(color: color),

                  // Centre icon bubble
                  Center(
                    child: Container(
                      width: AppConstants.collectionCardIconBubbleSize,
                      height: AppConstants.collectionCardIconBubbleSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: AppConstants.collectionCardIconSize,
                      ),
                    ),
                  ),

                  // Three-dot menu button
                  Positioned(
                    top: AppConstants.collectionCardMenuInset,
                    right: AppConstants.collectionCardMenuInset,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppConstants.collectionCardMenuTapRadius,
                        ),
                        onTap: () => _showContextMenu(context, l10n),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppConstants.collectionCardMenuPadding,
                          ),
                          child: Icon(
                            Icons.more_vert,
                            size: AppConstants.collectionCardMenuIconSize,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer: name + doc count ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.collectionCardFooterPaddingH,
                AppConstants.collectionCardFooterPaddingTop,
                AppConstants.collectionCardFooterPaddingH,
                AppConstants.collectionCardFooterPaddingBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: TextStyle(
                      fontSize: AppConstants.collectionCardNameFontSize,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.collectionsDocCount(summary.docCount),
                    style: TextStyle(
                      fontSize: AppConstants.collectionCardCountFontSize,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.sheetRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.collectionsEdit),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                l10n.collectionsDelete,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: AppConstants.collectionPickerSpacing),
          ],
        ),
      ),
    );
  }
}

// ── Gradient background ───────────────────────────────────────────────────────

class _CollectionGradientBg extends StatelessWidget {
  final Color color;
  const _CollectionGradientBg({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.70)],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _CollectionsEmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _CollectionsEmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.collectionEmptyPaddingH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppConstants.collectionEmptyIconCircleSize,
              height: AppConstants.collectionEmptyIconCircleSize,
              decoration: BoxDecoration(
                color: AppColors.primaryMuted.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_copy_outlined,
                size: AppConstants.collectionEmptyIconSize,
                color: AppColors.primaryMuted,
              ),
            ),
            const SizedBox(height: AppConstants.collectionEmptyTitleGap),
            Text(
              l10n.collectionsEmpty,
              style: const TextStyle(
                fontSize: AppConstants.collectionEmptyTitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.collectionEmptySubtitleGap),
            Text(
              l10n.collectionsEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppConstants.collectionEmptySubtitleFontSize,
                color: AppColors.textSecondary,
                height: AppConstants.collectionEmptySubtitleLineHeight,
              ),
            ),
            const SizedBox(height: AppConstants.collectionEmptyButtonGap),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: Text(l10n.collectionsNewCollection),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryMuted,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.collectionEmptyButtonPaddingH,
                  vertical: AppConstants.collectionEmptyButtonPaddingV,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small reusable picker helpers ─────────────────────────────────────────────

class _PickerSectionLabel extends StatelessWidget {
  final String text;
  const _PickerSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppConstants.collectionPickerLabelFontSize,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: AppConstants.collectionPickerAnimMs),
        width: AppConstants.collectionColorSwatchSize,
        height: AppConstants.collectionColorSwatchSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Colors.black87,
                  width: AppConstants.collectionColorSwatchBorderWidth,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: AppConstants.collectionColorSwatchShadowBlur,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: AppConstants.collectionColorSwatchCheckSize,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

class _IconSwatch extends StatelessWidget {
  final IconData iconData;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _IconSwatch({
    required this.iconData,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: AppConstants.collectionPickerAnimMs),
        width: AppConstants.collectionIconSwatchSize,
        height: AppConstants.collectionIconSwatchSize,
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            AppConstants.collectionIconSwatchRadius,
          ),
          border: selected
              ? Border.all(
                  color: accentColor,
                  width: AppConstants.collectionIconSwatchBorderWidth,
                )
              : null,
        ),
        child: Icon(
          iconData,
          size: AppConstants.collectionIconSwatchIconSize,
          color: selected ? accentColor : AppColors.textSecondary,
        ),
      ),
    );
  }
}
