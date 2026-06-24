import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// [workingPath]  — written by Done (may equal originalPath on first crop).
/// [originalPath] — never mutated; all crops start from here.
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
  // Corner handles as fractions (0..1) of the *original* image
  late Offset _tl, _tr, _bl, _br;

  // Original image (loaded once, never mutated)
  img.Image? _origImage;
  // Accumulated rotation applied on top of original for display/warp
  int _rotateDeg = 0; // 0, 90, 180, 270

  // Which handle is being dragged
  int _activeHandle = -1;

  // Preview mode: show warped result before committing
  bool _previewing = false;
  Uint8List? _previewBytes;

  bool get _ready => _origImage != null && _displayBytes != null;

  // Effective width/height after rotation
  double get _imgW => (_rotateDeg == 90 || _rotateDeg == 270)
      ? _origImage!.height.toDouble()
      : _origImage!.width.toDouble();
  double get _imgH => (_rotateDeg == 90 || _rotateDeg == 270)
      ? _origImage!.width.toDouble()
      : _origImage!.height.toDouble();

  @override
  void initState() {
    super.initState();
    _resetHandles();
    _loadOriginal();
  }

  void _resetHandles() {
    _tl = const Offset(0.05, 0.05);
    _tr = const Offset(0.95, 0.05);
    _bl = const Offset(0.05, 0.95);
    _br = const Offset(0.95, 0.95);
  }

  // Bytes of the original image rendered in the widget (no EXIF correction).
  // We keep these so Image.memory and _computeWarp both see the exact same pixels.
  Uint8List? _displayBytes;

  Future<void> _loadOriginal() async {
    final bytes = await File(widget.originalPath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null || !mounted) return;
    // Re-encode to strip EXIF rotation so Flutter's Image widget and
    // _computeWarp both operate on the same pixel grid (no auto-rotate).
    final stripped = img.encodeJpg(
      img.bakeOrientation(decoded),
      quality: 95,
    );
    final baked = img.decodeImage(stripped)!;
    setState(() {
      _origImage = baked;          // orientation-baked, EXIF-free
      _displayBytes = Uint8List.fromList(stripped);
    });
    _autoDetect();
  }

  // ── Auto edge detection ────────────────────────────────────────────────────
  // Strategy: find the page boundary by looking for the large bright rectangle
  // that contrasts against a darker background (desk/hand/shadow).
  // 1. Downsample for speed.
  // 2. Build a luminance map.
  // 3. Scan each edge inward: find the first row/column whose average luminance
  //    is significantly brighter than the outermost strip (background).
  // 4. Fall back to gradient bounding-box if the luminance scan fails.
  void _autoDetect() {
    final src = _effectiveImage();
    if (src == null) return;

    const ds = 4;
    final sw = src.width ~/ ds, sh = src.height ~/ ds;
    if (sw < 8 || sh < 8) return;

    final small = img.copyResize(src, width: sw, height: sh);

    // Build luminance grid (0..1)
    final lum = List.generate(sh, (y) => List.generate(sw, (x) {
      final p = small.getPixel(x, y);
      return (p.r * 0.299 + p.g * 0.587 + p.b * 0.114) / 255.0;
    }));

    double rowAvg(int y) {
      double s = 0;
      for (int x = 0; x < sw; x++) { s += lum[y][x]; }
      return s / sw;
    }
    double colAvg(int x) {
      double s = 0;
      for (int y = 0; y < sh; y++) { s += lum[y][x]; }
      return s / sh;
    }

    // Sample background luminance from the outermost 3% strip on each side
    final edgePx = math.max(1, (sh * 0.03).round());
    final edgePxW = math.max(1, (sw * 0.03).round());
    double bgTop = 0, bgBot = 0, bgL = 0, bgR = 0;
    for (int i = 0; i < edgePx; i++) { bgTop += rowAvg(i); bgBot += rowAvg(sh - 1 - i); }
    for (int i = 0; i < edgePxW; i++) { bgL += colAvg(i); bgR += colAvg(sw - 1 - i); }
    bgTop /= edgePx; bgBot /= edgePx; bgL /= edgePxW; bgR /= edgePxW;

    // A row/col is "page" when its avg luminance exceeds background by threshold
    const lumThresh = 0.10; // page must be ≥10% brighter than background strip

    // Scan from each edge inward to find where the page starts
    int top = 0, bottom = sh - 1, left = 0, right = sw - 1;
    for (int y = 0; y < sh; y++) {
      if (rowAvg(y) > bgTop + lumThresh) { top = y; break; }
    }
    for (int y = sh - 1; y >= 0; y--) {
      if (rowAvg(y) > bgBot + lumThresh) { bottom = y; break; }
    }
    for (int x = 0; x < sw; x++) {
      if (colAvg(x) > bgL + lumThresh) { left = x; break; }
    }
    for (int x = sw - 1; x >= 0; x--) {
      if (colAvg(x) > bgR + lumThresh) { right = x; break; }
    }

    // If luminance scan found almost nothing, fall back to gradient bbox
    final lumOk = (right - left) > sw * 0.20 && (bottom - top) > sh * 0.20;
    if (!lumOk) {
      // Gradient fallback
      final grad = List.generate(sh, (_) => List.filled(sw, 0.0));
      for (int y = 1; y < sh - 1; y++) {
        for (int x = 1; x < sw - 1; x++) {
          final gx = lum[y][x + 1] - lum[y][x - 1];
          final gy = lum[y + 1][x] - lum[y - 1][x];
          grad[y][x] = math.sqrt(gx * gx + gy * gy);
        }
      }
      double maxG = 0;
      for (final row in grad) { for (final v in row) { if (v > maxG) maxG = v; } }
      final thresh = maxG * 0.30;
      left = sw; right = 0; top = sh; bottom = 0;
      for (int y = 0; y < sh; y++) {
        for (int x = 0; x < sw; x++) {
          if (grad[y][x] >= thresh) {
            if (x < left)   left   = x;
            if (x > right)  right  = x;
            if (y < top)    top    = y;
            if (y > bottom) bottom = y;
          }
        }
      }
      if ((right - left) < sw * 0.20 || (bottom - top) < sh * 0.20) return;
    }

    // Tiny inward margin so handles sit just inside the detected boundary
    const margin = 0.008;
    final l = (left   / sw).clamp(0.0, 1.0) + margin;
    final r = (right  / sw).clamp(0.0, 1.0) - margin;
    final t = (top    / sh).clamp(0.0, 1.0) + margin;
    final b = (bottom / sh).clamp(0.0, 1.0) - margin;

    if (r <= l || b <= t || !mounted) return;
    setState(() {
      _tl = Offset(l, t);
      _tr = Offset(r, t);
      _bl = Offset(l, b);
      _br = Offset(r, b);
    });
  }

  // ── Rotation ───────────────────────────────────────────────────────────────
  void _rotate() {
    setState(() {
      _rotateDeg = (_rotateDeg + 90) % 360;
      _resetHandles();
      _previewing = false;
      _previewBytes = null;
    });
    // Re-run auto-detect in the new orientation
    _autoDetect();
  }

  // ── Returns the original image rotated by _rotateDeg ──────────────────────
  img.Image? _effectiveImage() {
    if (_origImage == null) return null;
    if (_rotateDeg == 0) return _origImage;
    return img.copyRotate(_origImage!, angle: _rotateDeg);
  }

  // ── Preview ────────────────────────────────────────────────────────────────
  Future<void> _togglePreview() async {
    if (_previewing) {
      setState(() { _previewing = false; _previewBytes = null; });
      return;
    }
    final warped = await _computeWarp();
    if (warped == null || !mounted) return;
    setState(() {
      _previewBytes = Uint8List.fromList(img.encodeJpg(warped, quality: 88));
      _previewing = true;
    });
  }

  // ── Warp computation (shared by preview + done) ───────────────────────────
  Future<img.Image?> _computeWarp() async {
    final source = _effectiveImage();
    if (source == null) return null;

    final iw = source.width.toDouble(), ih = source.height.toDouble();

    // Source quad corners in image pixels: TL, TR, BR, BL
    final tl = Offset(_tl.dx * iw, _tl.dy * ih);
    final tr = Offset(_tr.dx * iw, _tr.dy * ih);
    final br = Offset(_br.dx * iw, _br.dy * ih);
    final bl = Offset(_bl.dx * iw, _bl.dy * ih);

    // ignore: avoid_print
    print('WARP: src=${source.width}x${source.height} tl=$tl tr=$tr bl=$bl br=$br');

    // Output size: max of opposite edge lengths to preserve document aspect ratio.
    double len(Offset a, Offset b) => (b - a).distance;
    final outW = math.max(len(tl, tr), len(bl, br)).round().clamp(1, 8000);
    final outH = math.max(len(tl, bl), len(tr, br)).round().clamp(1, 8000);

    // Perspective homography: maps output rect corners → source quad corners.
    //   (0,0)       → tl
    //   (outW,0)    → tr
    //   (outW,outH) → br
    //   (0,outH)    → bl
    // Solved as 8×8 linear system via Gaussian elimination.
    final dstPts = [
      Offset(0, 0), Offset(outW.toDouble(), 0),
      Offset(outW.toDouble(), outH.toDouble()), Offset(0, outH.toDouble()),
    ];
    final srcPts = [tl, tr, br, bl];

    // Build A (8×8) and b (8×1)
    final A = List.generate(8, (_) => List<double>.filled(8, 0));
    final bv = List<double>.filled(8, 0);
    for (int i = 0; i < 4; i++) {
      final dx = dstPts[i].dx, dy = dstPts[i].dy;
      final sx = srcPts[i].dx, sy = srcPts[i].dy;
      A[2*i]   = [dx, dy, 1, 0, 0, 0, -sx*dx, -sx*dy];
      bv[2*i]  = sx;
      A[2*i+1] = [0, 0, 0, dx, dy, 1, -sy*dx, -sy*dy];
      bv[2*i+1]= sy;
    }

    // Gaussian elimination with partial pivoting
    final aug = List.generate(8, (i) => [...A[i], bv[i]]);
    for (int col = 0; col < 8; col++) {
      int pivot = col;
      for (int row = col + 1; row < 8; row++) {
        if (aug[row][col].abs() > aug[pivot][col].abs()) pivot = row;
      }
      final tmp = aug[col]; aug[col] = aug[pivot]; aug[pivot] = tmp;
      final p = aug[col][col];
      if (p.abs() < 1e-12) continue;
      for (int j = col; j <= 8; j++) aug[col][j] /= p;
      for (int row = 0; row < 8; row++) {
        if (row == col) continue;
        final f = aug[row][col];
        for (int j = col; j <= 8; j++) aug[row][j] -= f * aug[col][j];
      }
    }
    final h = List.generate(8, (i) => aug[i][8]);
    // h = [h0,h1,h2,h3,h4,h5,h6,h7], h8=1

    final warped = img.Image(width: outW, height: outH);

    for (int dy = 0; dy < outH; dy++) {
      for (int dx = 0; dx < outW; dx++) {
        final ddx = dx.toDouble(), ddy = dy.toDouble();
        final denom = h[6]*ddx + h[7]*ddy + 1.0;
        final sx = (h[0]*ddx + h[1]*ddy + h[2]) / denom;
        final sy = (h[3]*ddx + h[4]*ddy + h[5]) / denom;

        final x0 = sx.floor().clamp(0, source.width  - 1);
        final y0 = sy.floor().clamp(0, source.height - 1);
        final x1 = (x0 + 1).clamp(0, source.width  - 1);
        final y1 = (y0 + 1).clamp(0, source.height - 1);
        final fx = sx - x0, fy = sy - y0;

        final c00 = source.getPixel(x0, y0);
        final c10 = source.getPixel(x1, y0);
        final c01 = source.getPixel(x0, y1);
        final c11 = source.getPixel(x1, y1);

        int bl2(num a, num b, num c, num d) =>
            (a*(1-fx)*(1-fy) + b*fx*(1-fy) + c*(1-fx)*fy + d*fx*fy)
            .round().clamp(0, 255);

        warped.setPixelRgba(dx, dy,
          bl2(c00.r, c10.r, c01.r, c11.r),
          bl2(c00.g, c10.g, c01.g, c11.g),
          bl2(c00.b, c10.b, c01.b, c11.b),
          255,
        );
      }
    }
    return warped;
  }

  // ── Done ───────────────────────────────────────────────────────────────────
  Future<void> _done() async {
    final warped = await _computeWarp();
    if (warped == null) { if (mounted) Navigator.pop(context, true); return; }
    final workingFile = File(widget.workingPath);
    await workingFile.writeAsBytes(img.encodeJpg(warped, quality: 90));
    await FileImage(workingFile).evict();
    if (mounted) Navigator.pop(context, true);
  }

  // ── Rect of image inside its container (BoxFit.contain + padding) ──────────
  static const _kPad = 20.0; // px breathing room on each side
  Rect _imgRect(Size container) {
    final avW = container.width  - _kPad * 2;
    final avH = container.height - _kPad * 2;
    final scale = (_imgW / avW > _imgH / avH) ? avW / _imgW : avH / _imgH;
    final dw = _imgW * scale, dh = _imgH * scale;
    return Rect.fromLTWH(
      (container.width  - dw) / 2,
      (container.height - dh) / 2,
      dw, dh,
    );
  }

  // ── Handle absolute positions ──────────────────────────────────────────────
  List<Offset> _handles(Rect r) {
    final tl = Offset(r.left + _tl.dx * r.width, r.top + _tl.dy * r.height);
    final tr = Offset(r.left + _tr.dx * r.width, r.top + _tr.dy * r.height);
    final bl = Offset(r.left + _bl.dx * r.width, r.top + _bl.dy * r.height);
    final br = Offset(r.left + _br.dx * r.width, r.top + _br.dy * r.height);
    return [
      tl, tr, bl, br,
      Offset((tl.dx+tr.dx)/2, (tl.dy+tr.dy)/2), // 4 top-mid
      Offset((bl.dx+br.dx)/2, (bl.dy+br.dy)/2), // 5 bot-mid
      Offset((tl.dx+bl.dx)/2, (tl.dy+bl.dy)/2), // 6 left-mid
      Offset((tr.dx+br.dx)/2, (tr.dy+br.dy)/2), // 7 right-mid
    ];
  }

  int _nearestHandle(Offset pos, List<Offset> handles) {
    const threshold = 40.0;
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
        case 0: _tl = c(_tl + Offset(dx, dy));
        case 1: _tr = c(_tr + Offset(dx, dy));
        case 2: _bl = c(_bl + Offset(dx, dy));
        case 3: _br = c(_br + Offset(dx, dy));
        case 4: _tl = c(_tl + Offset(0, dy)); _tr = c(_tr + Offset(0, dy));
        case 5: _bl = c(_bl + Offset(0, dy)); _br = c(_br + Offset(0, dy));
        case 6: _tl = c(_tl + Offset(dx, 0)); _bl = c(_bl + Offset(dx, 0));
        case 7: _tr = c(_tr + Offset(dx, 0)); _br = c(_br + Offset(dx, 0));
      }
      // Leaving preview on drag would be confusing
      _previewing = false;
      _previewBytes = null;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
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
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 28, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(width: 4),
          const Text('Adjust borders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const Spacer(),
          if (_previewing)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('PREVIEW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildCropArea() {
    // Preview mode: show the warped result full-area
    if (_previewing && _previewBytes != null) {
      return Stack(
        children: [
          Center(
            child: Image.memory(
              _previewBytes!,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('This is what will be saved',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
      final imgRect = _imgRect(containerSize);
      final handles = _handles(imgRect);

      // Always render from in-memory bytes (EXIF stripped) so the displayed
      // pixels are identical to what _computeWarp reads — no silent auto-rotation.
      Widget imageWidget;
      if (_rotateDeg == 0) {
        imageWidget = Image.memory(
          _displayBytes!,
          key: const ValueKey('orig'),
          fit: BoxFit.contain,
        );
      } else {
        final rotated = _effectiveImage()!;
        final bytes = Uint8List.fromList(img.encodeJpg(rotated, quality: 85));
        imageWidget = Image.memory(
          bytes,
          key: ValueKey('rot$_rotateDeg'),
          fit: BoxFit.contain,
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _activeHandle = _nearestHandle(d.localPosition, handles),
        onPanUpdate: (d) { if (_activeHandle >= 0) _applyDrag(_activeHandle, d.delta, imgRect); },
        onPanEnd:   (_) => _activeHandle = -1,
        child: Stack(
          children: [
            Positioned(
              left: imgRect.left, top: imgRect.top,
              width: imgRect.width, height: imgRect.height,
              child: FittedBox(fit: BoxFit.fill, child: imageWidget),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CropPainter(
                  tl: handles[0], tr: handles[1], bl: handles[2], br: handles[3],
                  imgRect: imgRect,
                ),
              ),
            ),
            // Corner handles (larger tap targets)
            for (int i = 0; i < 4; i++)
              Positioned(
                left: handles[i].dx - 14,
                top:  handles[i].dy - 14,
                child: IgnorePointer(
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            // Mid-edge handles (smaller)
            for (int i = 4; i < 8; i++)
              Positioned(
                left: handles[i].dx - 9,
                top:  handles[i].dy - 9,
                child: IgnorePointer(
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                      border: Border.all(color: Colors.blue, width: 2),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(16)),
        child: Text(
          'Page ${widget.currentPage + 1} of ${widget.totalPages}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _btn(Icons.document_scanner_outlined, 'Auto', _autoDetect),
          _btn(Icons.crop_free, 'Reset', _resetHandles),
          _btn(Icons.rotate_right, 'Rotate', _rotate),
          _btn(
            _previewing ? Icons.edit : Icons.preview,
            _previewing ? 'Edit' : 'Preview',
            _togglePreview,
            color: Colors.orange,
          ),
          _btn(Icons.check, 'Done', _done, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Colors.grey[400]!;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: c),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: c,
                fontWeight: color != null ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────
class _CropPainter extends CustomPainter {
  final Offset tl, tr, bl, br;
  final Rect imgRect;

  const _CropPainter({
    required this.tl, required this.tr,
    required this.bl, required this.br,
    required this.imgRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cropPath = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    // Darken area outside image
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(imgRect),
      ),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // Dim area outside crop quad but inside image
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(imgRect), cropPath),
      Paint()..color = Colors.black.withValues(alpha: 0.50),
    );

    // Crop border
    canvas.drawPath(cropPath, Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke);

    // Rule-of-thirds grid inside quad
    final g = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
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
  bool shouldRepaint(covariant _CropPainter old) =>
      old.tl != tl || old.tr != tr || old.bl != bl || old.br != br;
}
