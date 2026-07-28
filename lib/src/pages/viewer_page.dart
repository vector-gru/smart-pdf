import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../db/app_db.dart';

class ViewerPage extends StatefulWidget {
  final String pdfPath;
  final String? title;
  final bool isExternal;
  const ViewerPage({
    Key? key,
    required this.pdfPath,
    this.title,
    this.isExternal = false,
  }) : super(key: key);

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> with WidgetsBindingObserver {
  final _controller = pdfrx.PdfViewerController();
  pdfrx.PdfTextSearcher? _searcher;
  final _shareKey = GlobalKey();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchVisible = false;
  bool _chromeVisible = true;
  String? _resolvedPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolveAndLoad();
    SystemChrome.setSystemUIChangeCallback(_onSystemUIChange);
  }

  /// Called by the OS when system bars are shown/hidden (e.g. immersiveSticky
  /// edge-swipe). If we're supposed to be hidden, re-hide after the brief peek.
  Future<void> _onSystemUIChange(bool systemOverlaysAreVisible) async {
    if (!_chromeVisible && systemOverlaysAreVisible) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !_chromeVisible) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applySystemUI();
  }

  void _applySystemUI() {
    if (_chromeVisible) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _toggleChrome() {
    if (_searchVisible) return;
    setState(() => _chromeVisible = !_chromeVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applySystemUI());
  }

  void _showChrome() {
    if (_chromeVisible) return;
    setState(() => _chromeVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applySystemUI());
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
        _showChrome();
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

  Future<void> _print() async {
    final path = _resolvedPath;
    if (path == null) return;
    await Printing.layoutPdf(
      name: widget.title ?? p.basename(path),
      onLayout: (_) => File(path).readAsBytes(),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIChangeCallback(null);
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
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
      extendBodyBehindAppBar: true,
      appBar: _chromeVisible
          ? AppBar(
              titleSpacing: 0,
              leading: widget.isExternal
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: SystemNavigator.pop,
                    )
                  : null,
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
                              horizontal:
                                  AppConstants.viewerSearchActionPaddingH,
                            ),
                            child: Text(
                              l10n.viewerSearchOf((currentIdx ?? 0) + 1, total),
                              style: const TextStyle(
                                fontSize:
                                    AppConstants.viewerSearchCountFontSize,
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
                              horizontal:
                                  AppConstants.viewerSearchActionPaddingH,
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
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: AppConstants.viewerSearchActionIconSize,
                          ),
                          onSelected: (value) {
                            if (value == 'print') _print();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'print',
                              child: Row(
                                children: [
                                  Icon(Icons.print),
                                  SizedBox(width: 8),
                                  Text('Print'),
                                ],
                              ),
                            ),
                          ],
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
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: AppConstants.viewerSearchActionIconSize,
                        ),
                        onSelected: (value) {
                          if (value == 'print') _print();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'print',
                            child: Row(
                              children: [
                                Icon(Icons.print),
                                SizedBox(width: 8),
                                Text('Print'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
            )
          : null,
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
                viewerOverlayBuilder: (context, size, handleLinkTap) => [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      handleLinkTap(Offset(size.width / 2, size.height / 2));
                      _toggleChrome();
                    },
                    child: SizedBox(width: size.width, height: size.height),
                  ),
                ],
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
