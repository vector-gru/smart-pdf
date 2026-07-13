import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:share_plus/share_plus.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../db/app_db.dart';

class ViewerPage extends StatefulWidget {
  final String pdfPath;
  final String? title;
  const ViewerPage({Key? key, required this.pdfPath, this.title})
    : super(key: key);

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final _controller = pdfrx.PdfViewerController();
  pdfrx.PdfTextSearcher? _searcher;
  final _shareKey = GlobalKey();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchVisible = false;
  String? _resolvedPath;

  @override
  void initState() {
    super.initState();
    _resolveAndLoad();
  }

  Future<void> _resolveAndLoad() async {
    final raw = widget.pdfPath;
    String path;
    if (raw.startsWith('content://')) {
      path = await _copyContentUriToTemp(raw);
    } else {
      path = await resolveDocPath(raw);
    }
    if (mounted) setState(() => _resolvedPath = path);
  }

  /// Copies a content:// URI to a temp file so pdfrx can open it as a regular file.
  Future<String> _copyContentUriToTemp(String contentUri) async {
    const channel = MethodChannel('smart_pdf/content_resolver');
    final bytes = await channel.invokeMethod<Uint8List>('readContentUri', {
      'uri': contentUri,
    });
    if (bytes == null || bytes.isEmpty)
      throw Exception('Failed to read content URI');
    final tmp = await getTemporaryDirectory();
    final dest = p.join(
      tmp.path,
      'shared_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await File(dest).writeAsBytes(bytes);
    return dest;
  }

  void _onViewerReady(pdfrx.PdfDocument doc, pdfrx.PdfViewerController ctrl) {
    final searcher = pdfrx.PdfTextSearcher(ctrl);
    searcher.addListener(_onSearchChanged);
    setState(() => _searcher = searcher);
  }

  void _onSearchChanged() => setState(() {});

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (_searchVisible) {
        _searchFocus.requestFocus();
      } else {
        _searchController.clear();
        _searcher?.resetTextSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searcher?.resetTextSearch();
    setState(() {});
  }

  Future<void> _share() async {
    final path = _resolvedPath;
    if (path == null) return;
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromLTWH(
            0,
            0,
            AppConstants.viewerShareFallbackSize,
            AppConstants.viewerShareFallbackSize,
          );
    Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      subject: widget.title,
      sharePositionOrigin: origin,
    );
  }

  @override
  void dispose() {
    _searcher?.removeListener(_onSearchChanged);
    _searcher?.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searcher = _searcher;
    final hasMatches = searcher != null && searcher.matches.isNotEmpty;
    final currentIdx = searcher?.currentIndex;
    final total = searcher?.matches.length ?? 0;
    final hasText = _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _searchVisible
            ? Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      hint: l10n.viewerSearchHint,
                      onChanged: (q) => searcher?.startTextSearch(q),
                    ),
                  ),
                  if (hasText)
                    _CompactIconButton(
                      icon: Icons.close,
                      onPressed: _clearSearch,
                    ),
                  if (hasMatches) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.viewerSearchActionPaddingH,
                      ),
                      child: Text(
                        l10n.viewerSearchOf((currentIdx ?? 0) + 1, total),
                        style: const TextStyle(
                          fontSize: AppConstants.viewerSearchCountFontSize,
                        ),
                      ),
                    ),
                    _CompactIconButton(
                      icon: Icons.keyboard_arrow_up,
                      onPressed: () => searcher.goToPrevMatch(),
                      tooltip: 'Previous',
                    ),
                    _CompactIconButton(
                      icon: Icons.keyboard_arrow_down,
                      onPressed: () => searcher.goToNextMatch(),
                      tooltip: 'Next',
                    ),
                  ],
                  if (searcher?.isSearching ?? false)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.viewerSearchActionPaddingH,
                      ),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  _CompactIconButton(
                    icon: Icons.search_off,
                    onPressed: _toggleSearch,
                    tooltip: 'Close search',
                  ),
                  IconButton(
                    key: _shareKey,
                    icon: const Icon(
                      Icons.share,
                      size: AppConstants.viewerSearchActionIconSize,
                    ),
                    onPressed: _share,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.viewerTitle),
                  if (widget.title != null)
                    Text(
                      widget.title!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
        actions: _searchVisible
            ? null
            : [
                _CompactIconButton(
                  icon: Icons.search,
                  onPressed: _toggleSearch,
                  tooltip: 'Search',
                ),
                IconButton(
                  key: _shareKey,
                  icon: const Icon(
                    Icons.share,
                    size: AppConstants.viewerSearchActionIconSize,
                  ),
                  onPressed: _share,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
      ),
      body: _resolvedPath == null
          ? const Center(child: CircularProgressIndicator())
          : pdfrx.PdfViewer.file(
              _resolvedPath!,
              controller: _controller,
              params: pdfrx.PdfViewerParams(
                margin: AppConstants.viewerPdfPadding,
                backgroundColor: Colors.grey.shade200,
                matchTextColor: Colors.yellow.withAlpha(160),
                activeMatchTextColor: Colors.orange.withAlpha(200),
                onViewerReady: _onViewerReady,
                pagePaintCallbacks: [
                  if (searcher != null) searcher.pageTextMatchPaintCallback,
                ],
              ),
            ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _CompactIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: AppConstants.viewerSearchActionIconSize),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: InputBorder.none,
      ),
    );
  }
}
