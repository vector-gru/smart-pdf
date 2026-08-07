import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Composites two ID card images (front + back) into a single image that fits
/// naturally as one PDF page.
///
/// Horizontal layout (side-by-side, A4 landscape @ 200 dpi ≈ 2338 × 1654 px):
///
///   ┌────────────────────────────────────────────────────────┐
///   │ pad │    front (scaled)    │ gap │    back (scaled)    │ pad │
///   └────────────────────────────────────────────────────────┘
///
/// Vertical layout (stacked, A4 portrait @ 200 dpi ≈ 1654 × 2338 px):
///
///   ┌──────────────────┐
///   │ pad              │
///   │   front (scaled) │
///   │ gap              │
///   │   back  (scaled) │
///   │ pad              │
///   └──────────────────┘
///
/// Returns the absolute path of the composed JPEG temp file.
class IdCardComposer {
  // A4 @ 200 dpi
  static const int _a4Long = 2338;
  static const int _a4Short = 1654;

  static const int _padding = 80; // outer padding (px)
  static const int _gap = 60; // gap between front and back

  /// Composites [frontPath] and [backPath].
  ///
  /// [horizontal] = true  → side-by-side on a landscape canvas (default).
  /// [horizontal] = false → stacked on a portrait canvas.
  static Future<String> compose(
    String frontPath,
    String backPath, {
    bool horizontal = true,
  }) async {
    final frontBytes = await File(frontPath).readAsBytes();
    final backBytes = await File(backPath).readAsBytes();

    img.Image? front = img.decodeImage(frontBytes);
    img.Image? back = img.decodeImage(backBytes);

    if (front == null || back == null) {
      throw Exception('IdCardComposer: could not decode one or both images.');
    }

    // Normalise EXIF orientation
    front = img.bakeOrientation(front);
    back = img.bakeOrientation(back);

    final img.Image canvas;
    final int frontX, frontY, backX, backY;

    if (horizontal) {
      // ── landscape, side-by-side ──────────────────────────────────────────
      final canvasW = _a4Long;
      final canvasH = _a4Short;
      final slotW = (canvasW - _padding * 2 - _gap) ~/ 2;
      final slotH = canvasH - _padding * 2;

      final scaledFront = _fitInSlot(front, slotW, slotH);
      final scaledBack = _fitInSlot(back, slotW, slotH);

      canvas = img.Image(width: canvasW, height: canvasH, numChannels: 3);
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

      frontX = _padding + (slotW - scaledFront.width) ~/ 2;
      frontY = _padding + (slotH - scaledFront.height) ~/ 2;
      backX = _padding + slotW + _gap + (slotW - scaledBack.width) ~/ 2;
      backY = _padding + (slotH - scaledBack.height) ~/ 2;

      img.compositeImage(canvas, scaledFront, dstX: frontX, dstY: frontY);
      img.compositeImage(canvas, scaledBack, dstX: backX, dstY: backY);
    } else {
      // ── portrait, stacked ────────────────────────────────────────────────
      final canvasW = _a4Short;
      final canvasH = _a4Long;
      final slotW = canvasW - _padding * 2;
      final slotH = (canvasH - _padding * 2 - _gap) ~/ 2;

      final scaledFront = _fitInSlot(front, slotW, slotH);
      final scaledBack = _fitInSlot(back, slotW, slotH);

      canvas = img.Image(width: canvasW, height: canvasH, numChannels: 3);
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

      frontX = _padding + (slotW - scaledFront.width) ~/ 2;
      frontY = _padding + (slotH - scaledFront.height) ~/ 2;
      backX = _padding + (slotW - scaledBack.width) ~/ 2;
      backY = _padding + slotH + _gap + (slotH - scaledBack.height) ~/ 2;

      img.compositeImage(canvas, scaledFront, dstX: frontX, dstY: frontY);
      img.compositeImage(canvas, scaledBack, dstX: backX, dstY: backY);
    }

    // Save to temp
    final tmpDir = await getTemporaryDirectory();
    final destDir = Directory(p.join(tmpDir.path, 'smart_pdf_temp'));
    await destDir.create(recursive: true);
    final outPath = p.join(
      destDir.path,
      'idcard_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(outPath).writeAsBytes(img.encodeJpg(canvas, quality: 90));
    return outPath;
  }

  /// Scales [src] so it fits within [maxW] × [maxH], preserving aspect ratio.
  static img.Image _fitInSlot(img.Image src, int maxW, int maxH) {
    final scaleW = maxW / src.width;
    final scaleH = maxH / src.height;
    final scale = scaleW < scaleH ? scaleW : scaleH;
    if (scale >= 1.0) return src;
    return img.copyResize(
      src,
      width: (src.width * scale).round(),
      height: (src.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }
}
