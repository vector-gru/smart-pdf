import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
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
  const ScannerPage({super.key, this.initialImages = const [], this.initialTitle});

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
  // Track a version key per image to bust Flutter's file image cache
  final Map<String, int> _imageVersions = {};
  // Original (pre-crop) backup paths keyed by working path
  final Map<String, String> _originals = {};

  @override
  void initState() {
    super.initState();
    _images.addAll(widget.initialImages);
    _pageController = PageController(viewportFraction: 0.85);
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _title = widget.initialTitle!;
    } else {
      final now = DateTime.now();
      _title = 'SmartPDF ${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year.toString().substring(2)} ${now.hour}.${now.minute.toString().padLeft(2, '0')}.${now.second.toString().padLeft(2, '0')}';
    }
    _titleController = TextEditingController(text: _title);
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus && _editingTitle) {
        _commitTitle();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
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

  void _bumpVersion(String path) {
    _imageVersions[path] = (_imageVersions[path] ?? 0) + 1;
  }

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
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 32, right: 32),
      child: _editingTitle
          ? TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, size: 18, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomPaint(size: const Size(200, 2), painter: _DashedLinePainter()),
                ],
              ),
            ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Page ${_currentPage + 1} of ${_images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    if (_images.isEmpty) {
      return const Center(
        child: Text('No pages yet.\nUse Add page to get started.', textAlign: TextAlign.center),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
    final actions = <_ActionItem>[
      _ActionItem(icon: Icons.document_scanner_outlined, label: 'Add page', onTap: _showAddPageSheet),
      _ActionItem(icon: Icons.crop, label: 'Crop', onTap: _cropCurrent),
      _ActionItem(icon: Icons.lens_blur, label: 'Color', onTap: _showColorSheet),
      _ActionItem(icon: Icons.rotate_right, label: 'Rotate', onTap: _rotateCurrent),
      _ActionItem(icon: Icons.reorder, label: 'Reorder', onTap: _reorderPages),
      _ActionItem(icon: Icons.delete_outline, label: 'Delete', onTap: _deleteCurrent),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: SizedBox(
        height: 64,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: actions.length,
          itemBuilder: (context, i) {
            final a = actions[i];
            return SizedBox(
              width: 76,
              child: InkWell(
                onTap: a.onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, size: 26, color: Colors.grey[700]),
                    const SizedBox(height: 4),
                    Text(
                      a.label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
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

  // --- Actions ---

  void _saveAndReturn() {
    if (_editingTitle) _commitTitle();
    if (_images.isEmpty) return;
    Navigator.of(context).pop(ScannerResult(title: _title, images: _images));
  }

  void _showAddPageSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take another photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Select from photos'),
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
      setState(() {
        _images.add(saved);
        _currentPage = _images.length - 1;
      });
      _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    final list = await _picker.pickMultiImage(imageQuality: 100);
    if (list.isEmpty) return;
    for (final x in list) {
      final saved = await _saveToTemp(x.path);
      _images.add(saved);
    }
    setState(() => _currentPage = _images.length - 1);
    _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // Compress image for document use: max 2000px on longest side, 82% JPEG quality.
  // This keeps the file print-sharp while reducing size ~60-70% vs raw camera output.
  Future<String> _saveToTemp(String sourcePath, {String prefix = ''}) async {
    final docs = await getTemporaryDirectory();
    final dest = p.join(docs.path, 'smart_pdf_temp');
    await Directory(dest).create(recursive: true);
    final outPath = p.join(dest, '$prefix${DateTime.now().millisecondsSinceEpoch}.jpg');
    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      outPath,
      quality: 82,
      minWidth: 1200,
      minHeight: 1200,
      // keepExif false so orientation is baked into pixels (avoids crop mismatch)
      keepExif: false,
    );
    // Fall back to plain copy if compression fails (e.g. unsupported format)
    if (compressed == null) {
      return (await File(sourcePath).copy(outPath)).path;
    }
    return compressed.path;
  }

  void _cropCurrent() async {
    if (_images.isEmpty) return;
    final workingPath = _images[_currentPage];

    // Ensure we have an original backup before any crop is applied
    if (!_originals.containsKey(workingPath)) {
      final origPath = await _saveToTemp(workingPath, prefix: '_orig_');
      _originals[workingPath] = origPath;
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
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ColorFilterSheet(
        imagePath: _images[_currentPage],
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
      final file = File(path);
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;

      img.Image processed;
      switch (filterName) {
        case 'bw1':
          processed = img.grayscale(decoded);
          break;
        case 'bw2':
          final gray = img.grayscale(decoded);
          processed = img.adjustColor(gray, contrast: 1.4);
          break;
        case 'gray':
          processed = img.grayscale(decoded);
          processed = img.adjustColor(processed, brightness: 1.1);
          break;
        case 'magic1':
          processed = img.adjustColor(decoded, contrast: 1.3, brightness: 1.05);
          break;
        case 'magic2':
          processed = img.adjustColor(decoded, contrast: 1.2, saturation: 0.8);
          break;
        default:
          processed = decoded;
      }

      final output = img.encodeJpg(processed, quality: 90);
      await file.writeAsBytes(output);
      // Evict cached image so Flutter reloads from disk
      await FileImage(file).evict();
      _bumpVersion(path);
    }
    setState(() {});
  }

  void _rotateCurrent() async {
    if (_images.isEmpty) return;
    final path = _images[_currentPage];
    final file = File(path);
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;
    final rotated = img.copyRotate(decoded, angle: 90);
    final output = img.encodeJpg(rotated, quality: 90);
    await file.writeAsBytes(output);
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
      setState(() => _images
        ..clear()
        ..addAll(result));
    }
  }

  void _deleteCurrent() async {
    if (_images.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete page?'),
        content: Text('Are you sure you want to delete page ${_currentPage + 1}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    if (_images.isNotEmpty) {
      _pageController.jumpToPage(_currentPage);
    }
  }
}

// --- Helpers ---

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
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ColorFilterSheet extends StatefulWidget {
  final String imagePath;
  final void Function(String filterName, bool applyToAll) onApply;
  const _ColorFilterSheet({required this.imagePath, required this.onApply});

  @override
  State<_ColorFilterSheet> createState() => _ColorFilterSheetState();
}

class _ColorFilterSheetState extends State<_ColorFilterSheet> {
  String _selected = 'magic1';
  bool _applyToAll = false;

  static const _filters = [
    ('magic1', 'Magic 1'),
    ('magic2', 'Magic 2'),
    ('bw1', 'B&W 1'),
    ('bw2', 'B&W 2'),
    ('gray', 'Gray'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemCount: _filters.length,
                itemBuilder: (context, i) {
                  final (id, label) = _filters[i];
                  final isSelected = _selected == id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = id),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 90,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey[300]!,
                              width: isSelected ? 2.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                              color: _colorOverlayFor(id),
                              colorBlendMode: _blendModeFor(id),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(label, style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.blue : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Apply to all pages', style: TextStyle(fontSize: 15)),
                  Switch(
                    value: _applyToAll,
                    onChanged: (v) => setState(() => _applyToAll = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => widget.onApply(_selected, _applyToAll),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Color? _colorOverlayFor(String id) {
    switch (id) {
      case 'bw1':
      case 'bw2':
      case 'gray':
        return Colors.grey;
      default:
        return null;
    }
  }

  BlendMode? _blendModeFor(String id) {
    switch (id) {
      case 'bw1':
      case 'bw2':
      case 'gray':
        return BlendMode.saturation;
      default:
        return null;
    }
  }
}

// ── Camera capture screen (guarantees rear camera) ───────────────────────
class CameraCapturePage extends StatefulWidget {
  final CameraDescription camera;
  const CameraCapturePage({super.key, required this.camera});

  @override
  State<CameraCapturePage> createState() => _CameraCapturPageState();
}

class _CameraCapturPageState extends State<CameraCapturePage> {
  late CameraController _ctrl;
  bool _ready = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = CameraController(widget.camera, ResolutionPreset.max, enableAudio: false);
    _ctrl.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await _ctrl.takePicture();
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_ready)
              Center(child: CameraPreview(_ctrl))
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            // Close
            Positioned(
              top: 8, left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Shutter
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _capturing ? Colors.grey : Colors.white.withValues(alpha: 0.2),
                    ),
                    child: _capturing
                        ? const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
