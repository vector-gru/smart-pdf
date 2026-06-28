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
import '../widgets/camera_capture_page.dart';
import '../widgets/color_filter_sheet.dart';
import 'crop_page.dart';
import 'reorder_page.dart';

class ScannerResult {
  final String title;
  final List<String> images;
  ScannerResult({required this.title, required this.images});
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

  @override
  void initState() {
    super.initState();
    _images.addAll(widget.initialImages);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final path in List.of(_images)) {
        if (!_originals.containsKey(path)) {
          _originals[path] = await _saveToTemp(path, prefix: '_orig_');
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
    Navigator.of(context).pop(ScannerResult(title: _title, images: _images));
  }

  void _showAddPageSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.scannerTakePhoto),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.scannerSelectPhotos),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

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

  void _animateToCurrentPage() {
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(
        milliseconds: AppConstants.scannerPageNavDuration,
      ),
      curve: Curves.easeInOut,
    );
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
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CropPage(
          workingPath: workingPath,
          originalPath: _originals[workingPath]!,
          currentPage: _currentPage,
          totalPages: _images.length,
        ),
      ),
    );
    if (result == true) {
      _bumpVersion(workingPath);
      setState(() {});
    }
  }

  void _showColorSheet() {
    if (_images.isEmpty) return;
    final path = _images[_currentPage];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ColorFilterSheet(
        imagePath: path,
        originalPath: _originals[path] ?? path,
        onApply: (filterName, applyToAll) {
          Navigator.pop(ctx);
          _applyColorFilter(filterName, applyToAll);
        },
      ),
    );
  }

  void _applyColorFilter(String filterName, bool applyToAll) async {
    final indices = applyToAll
        ? List.generate(_images.length, (i) => i)
        : [_currentPage];

    for (final idx in indices) {
      final path = _images[idx];
      if (!_originals.containsKey(path)) {
        _originals[path] = await _saveToTemp(path, prefix: '_orig_');
      }
      final file = File(path);

      if (filterName == 'default') {
        await File(_originals[path]!).copy(path);
        await FileImage(file).evict();
        _bumpVersion(path);
        continue;
      }

      final bytes = await File(_originals[path]!).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      img.Image processed;
      switch (filterName) {
        case 'bw1':
          processed = img.adjustColor(img.grayscale(decoded), contrast: 2.5);
          break;
        case 'bw2':
          final gray = img.grayscale(decoded);
          processed = img.Image(width: gray.width, height: gray.height);
          for (int y = 0; y < gray.height; y++) {
            for (int x = 0; x < gray.width; x++) {
              final lum = img.getLuminance(gray.getPixel(x, y));
              final v = lum > AppConstants.filterBw2Threshold
                  ? AppConstants.filterBw2White
                  : 0;
              processed.setPixelRgb(x, y, v, v, v);
            }
          }
          break;
        case 'gray':
          processed = img.grayscale(decoded);
          break;
        case 'magic1':
          processed = img.adjustColor(decoded, contrast: 1.9, brightness: 1.15);
          break;
        case 'magic2':
          processed = img.adjustColor(
            decoded,
            contrast: 2.4,
            saturation: 0.3,
            brightness: 1.1,
          );
          break;
        default:
          processed = decoded;
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
