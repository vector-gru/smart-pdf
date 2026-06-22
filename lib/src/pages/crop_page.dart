import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// [workingPath]  — the file shown in the scanner (will be overwritten by Done).
/// [originalPath] — immutable backup; crop always reads from here so re-cropping
///                  always starts from the full original image.
class CropPage extends StatefulWidget {
  final String workingPath;
  final String originalPath;
  final int currentPage;
  final int totalPages;
  const CropPage({
    super.key,
    required this.workingPath,
    required this.originalPath,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  // Handles as fractions (0..1) of the image display rect
  late Offset _tl, _tr, _bl, _br;

  // Intrinsic size of the *original* image
  double _imgW = 1, _imgH = 1;
  bool _ready = false;

  // Which handle is being dragged (-1 = none)
  int _activeHandle = -1;

  // Version bump forces Image widget key change → cache eviction on Android
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _resetHandles();
    _loadIntrinsicSize();
  }

  void _resetHandles() {
    _tl = const Offset(0.05, 0.05);
    _tr = const Offset(0.95, 0.05);
    _bl = const Offset(0.05, 0.95);
    _br = const Offset(0.95, 0.95);
  }

  Future<void> _loadIntrinsicSize() async {
    // Always measure from the original so dimensions stay stable across re-crops
    final bytes = await File(widget.originalPath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null || !mounted) return;
    setState(() {
      _imgW = decoded.width.toDouble();
      _imgH = decoded.height.toDouble();
      _ready = true;
    });
  }

  /// The BoxFit.contain rect for the image inside the given container.
  Rect _imgRect(Size container) {
    final scale = (_imgW / container.width > _imgH / container.height)
        ? container.width / _imgW
        : container.height / _imgH;
    final dw = _imgW * scale;
    final dh = _imgH * scale;
    return Rect.fromLTWH(
      (container.width - dw) / 2,
      (container.height - dh) / 2,
      dw,
      dh,
    );
  }

  // --- Handle positions (absolute pixels) ---
  List<Offset> _handles(Rect r) {
    final tl = Offset(r.left + _tl.dx * r.width, r.top + _tl.dy * r.height);
    final tr = Offset(r.left + _tr.dx * r.width, r.top + _tr.dy * r.height);
    final bl = Offset(r.left + _bl.dx * r.width, r.top + _bl.dy * r.height);
    final br = Offset(r.left + _br.dx * r.width, r.top + _br.dy * r.height);
    return [
      tl, tr, bl, br,                               // 0–3 corners
      Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2), // 4 top-center
      Offset((bl.dx + br.dx) / 2, (bl.dy + br.dy) / 2), // 5 bottom-center
      Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2), // 6 mid-left
      Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2), // 7 mid-right
    ];
  }

  int _nearestHandle(Offset pos, List<Offset> handles) {
    const threshold = 36.0;
    int best = -1;
    double bestDist = double.infinity;
    for (int i = 0; i < handles.length; i++) {
      final d = (handles[i] - pos).distance;
      if (d < bestDist) { bestDist = d; best = i; }
    }
    return bestDist <= threshold ? best : -1;
  }

  void _applyDrag(int index, Offset delta, Rect r) {
    final dx = delta.dx / r.width;
    final dy = delta.dy / r.height;
    Offset c(Offset o) => Offset(o.dx.clamp(0.0, 1.0), o.dy.clamp(0.0, 1.0));
    setState(() {
      switch (index) {
        case 0: _tl = c(_tl + Offset(dx, dy)); break;
        case 1: _tr = c(_tr + Offset(dx, dy)); break;
        case 2: _bl = c(_bl + Offset(dx, dy)); break;
        case 3: _br = c(_br + Offset(dx, dy)); break;
        case 4: _tl = c(_tl + Offset(0, dy)); _tr = c(_tr + Offset(0, dy)); break;
        case 5: _bl = c(_bl + Offset(0, dy)); _br = c(_br + Offset(0, dy)); break;
        case 6: _tl = c(_tl + Offset(dx, 0)); _bl = c(_bl + Offset(dx, 0)); break;
        case 7: _tr = c(_tr + Offset(dx, 0)); _br = c(_br + Offset(dx, 0)); break;
      }
    });
  }

  // --- Rotate (reads working file, writes working file) ---
  Future<void> _rotate() async {
    final file = File(widget.workingPath);
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;
    final rotated = img.copyRotate(decoded, angle: 90);
    await file.writeAsBytes(img.encodeJpg(rotated, quality: 90));
    await FileImage(file).evict();
    setState(() {
      final tmp = _imgW; _imgW = _imgH; _imgH = tmp;
      _resetHandles();
      _version++;
    });
  }

  // --- Done: crop original → write working ---
  Future<void> _done() async {
    final origFile = File(widget.originalPath);
    final bytes = await origFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) { if (mounted) Navigator.pop(context, true); return; }

    final w = decoded.width, h = decoded.height;
    final l = ([_tl.dx, _bl.dx].reduce((a, b) => a < b ? a : b) * w).round().clamp(0, w - 1);
    final t = ([_tl.dy, _tr.dy].reduce((a, b) => a < b ? a : b) * h).round().clamp(0, h - 1);
    final r = ([_tr.dx, _br.dx].reduce((a, b) => a > b ? a : b) * w).round().clamp(l + 1, w);
    final b = ([_bl.dy, _br.dy].reduce((a, b) => a > b ? a : b) * h).round().clamp(t + 1, h);

    final cropped = img.copyCrop(decoded, x: l, y: t, width: r - l, height: b - t);
    final workingFile = File(widget.workingPath);
    await workingFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));
    await FileImage(workingFile).evict();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _ready ? _buildCropArea() : const Center(child: CircularProgressIndicator())),
            _buildPageIndicator(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close, size: 28), onPressed: () => Navigator.pop(context, false)),
          const SizedBox(width: 8),
          const Text('Adjust borders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCropArea() {
    return LayoutBuilder(builder: (context, constraints) {
      final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
      final imgRect = _imgRect(containerSize);
      final handles = _handles(imgRect);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          _activeHandle = _nearestHandle(d.localPosition, handles);
        },
        onPanUpdate: (d) {
          if (_activeHandle >= 0) _applyDrag(_activeHandle, d.delta, imgRect);
        },
        onPanEnd: (_) => _activeHandle = -1,
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: Image.file(
                File(widget.workingPath),
                key: ValueKey('${widget.workingPath}-$_version'),
                fit: BoxFit.contain,
              ),
            ),
            // Overlay + border + guide lines
            Positioned.fill(
              child: CustomPaint(
                painter: _CropPainter(
                  tl: handles[0], tr: handles[1], bl: handles[2], br: handles[3],
                  imgRect: imgRect,
                ),
              ),
            ),
            // Handle dots (visual only — gestures handled above)
            for (final h in handles)
              Positioned(
                left: h.dx - 12,
                top: h.dy - 12,
                child: IgnorePointer(
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2.5),
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(16)),
        child: Text(
          'Page ${widget.currentPage + 1} of ${widget.totalPages}',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _btn(Icons.document_scanner_outlined, 'Auto-detect', () => setState(() {
            _tl = const Offset(0.02, 0.02); _tr = const Offset(0.98, 0.02);
            _bl = const Offset(0.02, 0.98); _br = const Offset(0.98, 0.98);
          })),
          _btn(Icons.crop_free, 'No crop', () => setState(_resetHandles)),
          _btn(Icons.rotate_right, 'Rotate', _rotate),
          _btn(Icons.check, 'Done', _done, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Colors.grey[700]!;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: c),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: c,
                fontWeight: color != null ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final Offset tl, tr, bl, br;
  final Rect imgRect;
  _CropPainter({required this.tl, required this.tr, required this.bl, required this.br, required this.imgRect});

  @override
  void paint(Canvas canvas, Size size) {
    final cropPath = Path()
      ..moveTo(tl.dx, tl.dy)..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)..lineTo(bl.dx, bl.dy)..close();

    // Grey outside image rect
    canvas.drawPath(
      Path.combine(PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(imgRect)),
      Paint()..color = const Color(0xFFE0E0E0),
    );

    // Semi-transparent white outside crop, inside image
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(imgRect), cropPath),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Crop border
    canvas.drawPath(cropPath, Paint()
      ..color = Colors.blue..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Rule-of-thirds grid
    final g = Paint()..color = Colors.blue.withValues(alpha: 0.35)..strokeWidth = 0.8;
    for (int i = 1; i <= 2; i++) {
      final t = i / 3.0;
      canvas.drawLine(
        Offset(tl.dx + (tr.dx - tl.dx) * t, tl.dy + (tr.dy - tl.dy) * t),
        Offset(bl.dx + (br.dx - bl.dx) * t, bl.dy + (br.dy - bl.dy) * t), g);
      canvas.drawLine(
        Offset(tl.dx + (bl.dx - tl.dx) * t, tl.dy + (bl.dy - tl.dy) * t),
        Offset(tr.dx + (br.dx - tr.dx) * t, tr.dy + (br.dy - tr.dy) * t), g);
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => true;
}
