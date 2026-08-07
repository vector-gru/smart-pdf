import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';
import '../widgets/camera_capture_page.dart'
    show CameraCapturePage, IdCardCameraPage, IdCardCameraResult;
import '../widgets/color_filter_sheet.dart'
    show ColorFilterSheet, colorMatrixForStrength;
import 'crop_page.dart';
import 'id_card_edit_page.dart';
import 'reorder_page.dart';
import 'smart_edit_page.dart';

class ScannerResult {
  final String title;
  final List<String> images;

  /// Maps each working image path to its original (unfiltered) image path.
  /// Used by the persistence layer to save a permanent original alongside
  /// each working copy so colour filters can always be reverted.
  final Map<String, String> originals;
  ScannerResult({
    required this.title,
    required this.images,
    this.originals = const {},
  });
}

class ScannerPage extends StatefulWidget {
  final List<String> initialImages;
  final String? initialTitle;
  final bool autoCrop;
  const ScannerPage({
    super.key,
    this.initialImages = const [],
    this.initialTitle,
    this.autoCrop = true,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final List<String> _images = [];
  late PageController _pageController;
  int _currentPage = 0;
  late String _title;
  final _picker = ImagePicker();
  bool _editingTitle = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocus = FocusNode();
  final Map<String, int> _imageVersions = {};
  final Map<String, String> _originals = {};

  /// Maps each working image path to a snapshot taken immediately after the
  /// last crop (but before any colour filter).  Colour-filter operations read
  /// from this baseline so they always apply on top of the cropped image
  /// rather than on the pristine original.  When no crop has been done the
  /// map has no entry and _originals is used as the fallback.
  final Map<String, String> _cropBaselines = {};

  @override
  void initState() {
    super.initState();
    _images.addAll(widget.initialImages);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final path in List.of(_images)) {
        if (!_originals.containsKey(path)) {
          // When re-editing a saved document, a permanent original lives next
          // to the working copy as `page_N_orig<ext>`.  Use that directly so
          // "Default" always restores to the true unfiltered image.
          final permanentOrig = _permanentOrigFor(path);
          if (permanentOrig != null && await File(permanentOrig).exists()) {
            // Copy the permanent original into a temp file so ScannerPage can
            // safely overwrite it without touching the permanent backup.
            _originals[path] = await _saveToTemp(
              permanentOrig,
              prefix: '_orig_',
            );
          } else {
            // First-time open: the image itself is the original.
            _originals[path] = await _saveToTemp(path, prefix: '_orig_');
          }
        }
      }
    });
    _pageController = PageController(
      viewportFraction: AppConstants.scannerPageViewFraction,
    );
    _title = widget.initialTitle?.isNotEmpty == true
        ? widget.initialTitle!
        : _defaultTitle();
    _titleController = TextEditingController(text: _title);
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus && _editingTitle) _commitTitle();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  String _defaultTitle() {
    final now = DateTime.now();
    return 'SmartPDF ${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year.toString().substring(2)} '
        '${now.hour}.${now.minute.toString().padLeft(2, '0')}.${now.second.toString().padLeft(2, '0')}';
  }

  void _commitTitle() {
    final t = _titleController.text.trim();
    setState(() {
      _editingTitle = false;
      if (t.isNotEmpty) _title = t;
      _titleController.text = _title;
    });
  }

  int _versionOf(String path) => _imageVersions[path] ?? 0;

  void _bumpVersion(String path) =>
      _imageVersions[path] = (_imageVersions[path] ?? 0) + 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_editingTitle) _commitTitle();
          },
          child: Column(
            children: [
              _buildTopBar(),
              _buildTitle(),
              if (_images.isNotEmpty) _buildPageIndicator(),
              Expanded(child: _buildPageView()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            onPressed: _saveAndReturn,
            child: Text(
              l10n.scannerSave,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppConstants.scannerTitlePaddingBottom,
        left: AppConstants.scannerTitlePaddingH,
        right: AppConstants.scannerTitlePaddingH,
      ),
      child: _editingTitle
          ? TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppConstants.scannerTitleFontSize,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: UnderlineInputBorder(),
              ),
              onSubmitted: (_) => _commitTitle(),
            )
          : GestureDetector(
              onTap: () {
                setState(() => _editingTitle = true);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _titleFocus.requestFocus();
                  _titleController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _titleController.text.length,
                  );
                });
              },
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _title,
                          style: const TextStyle(
                            fontSize: AppConstants.scannerTitleFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(
                        width: AppConstants.scannerTitleEditIconGap,
                      ),
                      const Icon(
                        Icons.edit,
                        size: AppConstants.scannerTitleEditIconSize,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomPaint(
                    size: const Size(
                      AppConstants.scannerTitleDashedLineWidth,
                      AppConstants.scannerTitleDashedLineHeight,
                    ),
                    painter: _DashedLinePainter(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPageIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.scannerIndicatorPaddingH,
          vertical: AppConstants.scannerIndicatorPaddingV,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(
            AppConstants.scannerIndicatorRadius,
          ),
        ),
        child: Text(
          l10n.scannerPageOf(_currentPage + 1, _images.length),
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppConstants.scannerIndicatorFontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    final l10n = AppLocalizations.of(context)!;
    if (_images.isEmpty) {
      return Center(
        child: Text(l10n.scannerNoPages, textAlign: TextAlign.center),
      );
    }
    return PageView.builder(
      controller: _pageController,
      itemCount: _images.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, index) {
        final path = _images[index];
        final version = _versionOf(path);
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.scannerPageItemPaddingH,
            vertical: AppConstants.scannerPageItemPaddingV,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                AppConstants.scannerCardBorderRadius,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppConstants.scannerCardShadowAlpha,
                  ),
                  blurRadius: AppConstants.scannerCardShadowBlur,
                  offset: const Offset(0, AppConstants.scannerPageItemShadowY),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppConstants.scannerCardBorderRadius,
              ),
              child: Image.file(
                File(path),
                key: ValueKey('$path-$version'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context)!;
    final actions = <_ActionItem>[
      _ActionItem(
        icon: Icons.document_scanner_outlined,
        label: l10n.scannerAddPage,
        onTap: _showAddPageSheet,
      ),
      _ActionItem(
        icon: Icons.crop,
        label: l10n.scannerCrop,
        onTap: _cropCurrent,
      ),
      _ActionItem(
        icon: Icons.lens_blur,
        label: l10n.scannerColor,
        onTap: _showColorSheet,
      ),
      _ActionItem(
        icon: Icons.rotate_right,
        label: l10n.scannerRotate,
        onTap: _rotateCurrent,
      ),
      _ActionItem(
        icon: Icons.reorder,
        label: l10n.scannerReorder,
        onTap: _reorderPages,
      ),
      _ActionItem(
        icon: Icons.edit_note,
        label: 'Smart Edit',
        onTap: _smartEditCurrent,
      ),
      _ActionItem(
        icon: Icons.delete_outline,
        label: l10n.scannerDelete,
        onTap: _deleteCurrent,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.only(
        top: AppConstants.scannerBottomBarPaddingTop,
        bottom: AppConstants.scannerBottomBarPaddingBottom,
      ),
      child: SizedBox(
        height: AppConstants.scannerBottomBarHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.scannerBottomBarItemPaddingH,
          ),
          itemCount: actions.length,
          itemBuilder: (context, i) {
            final a = actions[i];
            return SizedBox(
              width: AppConstants.scannerBottomBarItemWidth,
              child: InkWell(
                onTap: a.onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      a.icon,
                      size: AppConstants.scannerBottomBarIconSize,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(
                      height: AppConstants.scannerBottomBarIconGap,
                    ),
                    Text(
                      a.label,
                      style: TextStyle(
                        fontSize: AppConstants.scannerBottomBarFontSize,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _saveAndReturn() {
    if (_editingTitle) _commitTitle();
    if (_images.isEmpty) return;
    Navigator.of(context).pop(
      ScannerResult(
        title: _title,
        images: _images,
        originals: Map.unmodifiable(_originals),
      ),
    );
  }

  void _showAddPageSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Standard – camera
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.scannerTakePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              // Standard – gallery
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.image_outlined),
                title: Text(l10n.scannerSelectPhotos),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 4),
              // ID Card – camera
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.credit_card),
                title: Text(l10n.scannerScanTypeIdCard),
                subtitle: Text(
                  l10n.scannerIdCardInstructions,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIdCardFromCamera();
                },
              ),
              // ID Card – gallery
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.scannerAddIdCard),
                subtitle: Text(
                  l10n.scannerIdCardGalleryInstructions,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIdCardFromGallery();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Standard pick helpers ────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      if (!mounted) return;
      final path = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => CameraCapturePage(camera: rear)),
      );
      if (path == null) return;
      final saved = await _saveToTemp(path);
      _originals[saved] = await _saveToTemp(path, prefix: '_orig_');
      setState(() {
        _images.add(saved);
        _currentPage = _images.length - 1;
      });
      _animateToCurrentPage();
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    final list = await _picker.pickMultiImage(imageQuality: 100);
    if (list.isEmpty) return;
    for (final x in list) {
      final saved = await _saveToTemp(x.path);
      _originals[saved] = await _saveToTemp(x.path, prefix: '_orig_');
      _images.add(saved);
    }
    setState(() => _currentPage = _images.length - 1);
    _animateToCurrentPage();
  }

  // ─── ID Card pick helpers ─────────────────────────────────────────────────

  /// Camera flow: single session that captures front then back, then opens
  /// the ID card editor for layout + rotation tweaks.
  Future<void> _pickIdCardFromCamera() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      if (!mounted) return;

      final result = await Navigator.of(context).push<IdCardCameraResult>(
        MaterialPageRoute(
          builder: (_) => IdCardCameraPage(
            camera: rear,
            frontLabel: l10n.scannerIdCardFront,
            backLabel: l10n.scannerIdCardBack,
          ),
        ),
      );
      if (result == null || !mounted) return;

      await _openIdCardEditor(result.frontPath, result.backPath);
    } catch (_) {}
  }

  /// Gallery flow: lets the user select 1 or 2 images.
  ///   - 2 selected at once → treat as front + back immediately.
  ///   - 1 selected         → prompt for the second image separately.
  Future<void> _pickIdCardFromGallery() async {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;

    // Ask for up to 2 images at once
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.scannerIdCardGalleryInstructions),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 400));

    final picked = await _picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty || !mounted) return;

    String frontPath = picked.first.path;
    String backPath;

    if (picked.length >= 2) {
      // User selected both at once — use first as front, second as back
      backPath = picked[1].path;
    } else {
      // Only one selected — ask for the second
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scannerIdCardSelectBack),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 400));
      final backFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (backFile == null || !mounted) return;
      backPath = backFile.path;
    }

    await _openIdCardEditor(frontPath, backPath);
  }

  /// Opens the ID card editor for layout + rotation adjustments, then
  /// adds the resulting composite as a new page.
  Future<void> _openIdCardEditor(String frontPath, String backPath) async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<IdCardEditResult>(
      MaterialPageRoute(
        builder: (_) =>
            IdCardEditPage(frontPath: frontPath, backPath: backPath),
      ),
    );
    if (result == null || !mounted) return;
    await _addIdCardComposite(result.compositePath);
  }

  /// Saves a composited ID card image as a new scanner page.
  Future<void> _addIdCardComposite(String compositePath) async {
    try {
      final saved = await _saveToTemp(compositePath);
      _originals[saved] = await _saveToTemp(compositePath, prefix: '_orig_');
      setState(() {
        _images.add(saved);
        _currentPage = _images.length - 1;
      });
      _animateToCurrentPage();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add ID card page.')),
        );
      }
    }
  }

  void _animateToCurrentPage() {
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(
        milliseconds: AppConstants.scannerPageNavDuration,
      ),
      curve: Curves.easeInOut,
    );
  }

  /// Returns the path of the permanent original file stored alongside a
  /// working page image, e.g. `page_1.jpg` → `page_1_orig.jpg`.
  /// Returns null if the naming convention doesn't apply.
  static String? _permanentOrigFor(String workingPath) {
    final ext = p.extension(workingPath);
    final withoutExt = workingPath.substring(
      0,
      workingPath.length - ext.length,
    );
    // Only treat files matching `page_N<ext>` as having a permanent original.
    if (!p.basename(workingPath).startsWith('page_')) return null;
    return '${withoutExt}_orig$ext';
  }

  Future<String> _saveToTemp(String sourcePath, {String prefix = ''}) async {
    final docs = await getTemporaryDirectory();
    final dest = p.join(docs.path, 'smart_pdf_temp');
    await Directory(dest).create(recursive: true);
    final outPath = p.join(
      dest,
      '$prefix${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      outPath,
      quality: AppConstants.scannerCompressQuality,
      minWidth: AppConstants.scannerCompressMinDimension,
      minHeight: AppConstants.scannerCompressMinDimension,
      keepExif: false,
    );
    return compressed?.path ?? (await File(sourcePath).copy(outPath)).path;
  }

  void _cropCurrent() async {
    if (_images.isEmpty) return;
    final workingPath = _images[_currentPage];
    if (!_originals.containsKey(workingPath)) {
      _originals[workingPath] = await _saveToTemp(
        workingPath,
        prefix: '_orig_',
      );
    }
    if (!mounted) return;

    // CropPage warps from originalPath.  We always pass the current working
    // file so that any previously-applied colour filter is baked into the
    // crop output — the user sees and keeps what they already edited.
    // The true pristine original (_originals) is unaffected and is still used
    // by _applyColorFilter for re-applying colour on top of subsequent crops.
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CropPage(
          workingPath: workingPath,
          originalPath: workingPath,
          currentPage: _currentPage,
          totalPages: _images.length,
        ),
      ),
    );
    if (result == true) {
      // Snapshot the freshly-cropped working file as the new colour baseline.
      // Subsequent colour-filter applications will read from this snapshot so
      // they always compose on top of the current crop.
      _cropBaselines[workingPath] = await _saveToTemp(
        workingPath,
        prefix: '_crop_',
      );
      _bumpVersion(workingPath);
      setState(() {});
    }
  }

  void _showColorSheet() {
    if (_images.isEmpty) return;
    final path = _images[_currentPage];
    // The sheet's originalPath drives both the live preview and the filter
    // thumbnails.  When a crop has already been applied in this session we use
    // the crop baseline (post-crop, pre-colour snapshot) so the previews show
    // the cropped image.  Without a crop baseline we fall back to the true
    // pristine original as before.
    final sheetOriginalPath = _cropBaselines[path] ?? _originals[path] ?? path;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ColorFilterSheet(
        imagePath: path,
        originalPath: sheetOriginalPath,
        onApply: (filterName, strength, applyToAll) {
          Navigator.pop(ctx);
          _applyColorFilter(filterName, strength, applyToAll);
        },
      ),
    );
  }

  void _applyColorFilter(
    String filterName,
    double strength,
    bool applyToAll,
  ) async {
    final indices = applyToAll
        ? List.generate(_images.length, (i) => i)
        : [_currentPage];

    for (final idx in indices) {
      final path = _images[idx];
      if (!_originals.containsKey(path)) {
        _originals[path] = await _saveToTemp(path, prefix: '_orig_');
      }
      final file = File(path);

      // The colour baseline is the post-crop snapshot when a crop has been
      // performed, otherwise the pristine original.  This ensures:
      //   • colour is always applied on top of any existing crop, and
      //   • "Default" restores to the cropped (but uncoloured) state.
      final baselinePath = _cropBaselines[path] ?? _originals[path]!;

      if (filterName == 'default' || strength == 0.0) {
        await File(baselinePath).copy(path);
        await FileImage(file).evict();
        _bumpVersion(path);
        continue;
      }

      final bytes = await File(baselinePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      // Apply the identical 5×4 color matrix that the Flutter ColorFilter
      // preview uses, scaled by [strength].
      // Result channel = m[0]*R + m[1]*G + m[2]*B + m[3]*A + m[4]  (clamped 0-255)
      final matrix = colorMatrixForStrength(filterName, strength);
      final processed = img.Image(width: decoded.width, height: decoded.height);

      for (int y = 0; y < decoded.height; y++) {
        for (int x = 0; x < decoded.width; x++) {
          final px = decoded.getPixel(x, y);
          final r = px.r.toDouble();
          final g = px.g.toDouble();
          final b = px.b.toDouble();
          final a = px.a.toDouble();

          int nr =
              (matrix[0] * r +
                      matrix[1] * g +
                      matrix[2] * b +
                      matrix[3] * a +
                      matrix[4])
                  .round()
                  .clamp(0, 255);
          int ng =
              (matrix[5] * r +
                      matrix[6] * g +
                      matrix[7] * b +
                      matrix[8] * a +
                      matrix[9])
                  .round()
                  .clamp(0, 255);
          int nb =
              (matrix[10] * r +
                      matrix[11] * g +
                      matrix[12] * b +
                      matrix[13] * a +
                      matrix[14])
                  .round()
                  .clamp(0, 255);
          int na =
              (matrix[15] * r +
                      matrix[16] * g +
                      matrix[17] * b +
                      matrix[18] * a +
                      matrix[19])
                  .round()
                  .clamp(0, 255);

          processed.setPixelRgba(x, y, nr, ng, nb, na);
        }
      }

      await file.writeAsBytes(img.encodeJpg(processed, quality: 90));
      await FileImage(file).evict();
      _bumpVersion(path);
    }
    setState(() {});
  }

  void _rotateCurrent() async {
    if (_images.isEmpty) return;
    final path = _images[_currentPage];
    final file = File(path);
    final decoded = img.decodeImage(await file.readAsBytes());
    if (decoded == null) return;
    final rotated = img.copyRotate(
      decoded,
      angle: AppConstants.scannerRotateAngle,
    );
    await file.writeAsBytes(img.encodeJpg(rotated, quality: 90));
    await FileImage(file).evict();
    _bumpVersion(path);
    setState(() {});
  }

  void _reorderPages() async {
    if (_images.length < 2) return;
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => ReorderPage(images: List.of(_images))),
    );
    if (result != null) {
      setState(
        () => _images
          ..clear()
          ..addAll(result),
      );
    }
  }

  void _smartEditCurrent() async {
    if (_images.isEmpty) return;
    final path = _images[_currentPage];
    final modified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SmartEditPage(
          imagePath: path,
          pageNumber: _currentPage + 1,
          totalPages: _images.length,
        ),
      ),
    );
    if (modified == true) {
      // Evict the cached image so ScannerPage's PageView shows the new pixels
      await FileImage(File(path)).evict();
      _bumpVersion(path);
      setState(() {});
    }
  }

  void _deleteCurrent() async {
    if (_images.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.scannerDeletePageTitle),
        content: Text(l10n.scannerDeletePageContent(_currentPage + 1)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.docActionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.docActionDelete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _images.removeAt(_currentPage);
      if (_currentPage >= _images.length && _images.isNotEmpty) {
        _currentPage = _images.length - 1;
      }
    });
    if (_images.isNotEmpty) _pageController.jumpToPage(_currentPage);
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ActionItem({required this.icon, required this.label, required this.onTap});
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + AppConstants.scannerDashWidth, 0),
        paint,
      );
      x += AppConstants.scannerDashWidth + AppConstants.scannerDashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
