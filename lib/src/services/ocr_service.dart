import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

/// A single recognised word.
class OcrWord {
  final String text;

  /// Bounding box in image-pixel coordinates (original image size).
  final Rect rect;

  /// Cap-height font size estimated from the actual ink extent in the box.
  final double fontSize;

  /// Dominant ink colour sampled from within the word region.
  final Color textColor;

  /// Paper/background colour sampled from a border ring outside the word.
  final Color backgroundColor;

  const OcrWord({
    required this.text,
    required this.rect,
    required this.fontSize,
    required this.textColor,
    required this.backgroundColor,
  });
}

class OcrResult {
  final List<OcrWord> words;
  final String imagePath;
  final int imageWidth;
  final int imageHeight;

  const OcrResult({
    required this.words,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
  });
}

class OcrService {
  OcrService._();

  static const double _renderScale = 3.0;

  // ── Public entry points ───────────────────────────────────────────────────

  /// OCR a raw image file — primary path for the scanner/edit flow.
  ///
  /// Runs two passes: once on the original image, once on a contrast-enhanced
  /// version that helps with faint handwriting.  Results are merged so missed
  /// words from either pass are recovered.
  static Future<OcrResult> recognizeImage({required String imagePath}) async {
    debugPrint('[OcrService] recognizeImage: $imagePath');

    final bytes = await File(imagePath).readAsBytes();
    final source = img.decodeImage(bytes);
    if (source == null) throw Exception('OcrService: cannot decode $imagePath');

    debugPrint('[OcrService] Image: ${source.width}x${source.height}');

    // ── Build an enhanced copy for handwriting ─────────────────────────────
    final tmpDir = await getTemporaryDirectory();
    final enhancedPath = p.join(
      tmpDir.path,
      'ocr_enh_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final enhanced = _enhanceContrast(source);
    await File(enhancedPath).writeAsBytes(img.encodeJpg(enhanced, quality: 95));

    // ── Run both passes ────────────────────────────────────────────────────
    final passA = await _runMlKit(imagePath, 'pass-A');
    final passB = await _runMlKit(enhancedPath, 'pass-B (enhanced)');

    // Cleanup temp file
    try {
      await File(enhancedPath).delete();
    } catch (_) {}

    // ── Merge: prefer longer text for overlapping regions ─────────────────
    final merged = _merge(passA, passB);
    debugPrint('[OcrService] Merged result: ${merged.length} words');

    // ── Build OcrWords with sampled colours ────────────────────────────────
    final words = _buildWords(merged, source, source.width, source.height);

    return OcrResult(
      words: words,
      imagePath: imagePath,
      imageWidth: source.width,
      imageHeight: source.height,
    );
  }

  /// OCR a specific PDF page (kept for potential future use).
  static Future<OcrResult> recognizePage({
    required String pdfPath,
    required int pageIndex,
  }) async {
    final document = await pdfrx.PdfDocument.openFile(pdfPath);
    try {
      final page = await document.pages[pageIndex];
      final width = (page.width * _renderScale).round();
      final height = (page.height * _renderScale).round();

      final pdfImage = await page.render(
        fullWidth: width.toDouble(),
        fullHeight: height.toDouble(),
        backgroundColor: 0xffffffff,
      );
      if (pdfImage == null) throw Exception('OcrService: page.render() null');

      final uiImage = await pdfImage.createImage();
      final byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      pdfImage.dispose();
      uiImage.dispose();
      if (byteData == null) throw Exception('OcrService: no byte data');

      final rgba = byteData.buffer.asUint8List();
      final imgImage = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rgba.buffer,
        order: img.ChannelOrder.rgba,
        numChannels: 4,
      );

      final tmpDir = await getTemporaryDirectory();
      final tmpPath = p.join(
        tmpDir.path,
        'ocr_page_${pageIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(tmpPath).writeAsBytes(img.encodeJpg(imgImage, quality: 92));

      final enhancedPath = p.join(
        tmpDir.path,
        'ocr_enh_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(
        enhancedPath,
      ).writeAsBytes(img.encodeJpg(_enhanceContrast(imgImage), quality: 95));

      final passA = await _runMlKit(tmpPath, 'pdf-pass-A');
      final passB = await _runMlKit(enhancedPath, 'pdf-pass-B');
      try {
        await File(enhancedPath).delete();
      } catch (_) {}

      final merged = _merge(passA, passB);
      final words = _buildWords(merged, imgImage, width, height);

      return OcrResult(
        words: words,
        imagePath: tmpPath,
        imageWidth: width,
        imageHeight: height,
      );
    } finally {
      await document.dispose();
    }
  }

  // ── ML Kit pass ───────────────────────────────────────────────────────────

  static Future<List<_Raw>> _runMlKit(String imagePath, String tag) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(input);
      final words = <_Raw>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            final bb = element.boundingBox;
            if (bb.width <= 0 || bb.height <= 0) continue;
            final text = element.text.trim();
            if (text.isEmpty) continue;
            words.add(
              _Raw(text: text, rect: bb, confidence: element.confidence ?? 0.5),
            );
          }
        }
      }
      debugPrint('[OcrService] $tag: ${words.length} words');
      return words;
    } finally {
      await recognizer.close();
    }
  }

  // ── Image enhancement for handwriting ────────────────────────────────────

  /// Adaptive contrast stretching + mild sharpening.
  /// Makes faint pencil/ink handwriting much more visible to ML Kit.
  static img.Image _enhanceContrast(img.Image src) {
    // Convert to greyscale, compute histogram
    final grey = img.grayscale(
      img.copyResize(src, width: src.width, height: src.height),
    );

    // Find 5th and 95th percentile luminance values
    final hist = List<int>.filled(256, 0);
    for (final px in grey) {
      hist[px.r.toInt().clamp(0, 255)]++;
    }
    final total = grey.width * grey.height;
    int lo = 0, hi = 255;
    int cumLo = 0, cumHi = 0;
    for (var i = 0; i < 256; i++) {
      cumLo += hist[i];
      if (cumLo < total * 0.05) lo = i;
    }
    for (var i = 255; i >= 0; i--) {
      cumHi += hist[i];
      if (cumHi < total * 0.05) hi = i;
    }
    final range = (hi - lo).clamp(1, 255).toDouble();

    // Stretch contrast on original colour image
    final out = img.Image(width: src.width, height: src.height);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final px = src.getPixel(x, y);
        final r = (((px.r.toDouble() - lo) / range) * 255).round().clamp(
          0,
          255,
        );
        final g = (((px.g.toDouble() - lo) / range) * 255).round().clamp(
          0,
          255,
        );
        final b = (((px.b.toDouble() - lo) / range) * 255).round().clamp(
          0,
          255,
        );
        out.setPixelRgb(x, y, r, g, b);
      }
    }

    // Mild unsharp mask — improves text edge clarity
    return img.convolution(
      out,
      filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
      div: 1,
      offset: 0,
    );
  }

  // ── Merge two passes ─────────────────────────────────────────────────────

  static List<_Raw> _merge(List<_Raw> primary, List<_Raw> secondary) {
    final result = List<_Raw>.from(primary);
    for (final cand in secondary) {
      bool dominated = false;
      for (var i = 0; i < result.length; i++) {
        final existing = result[i];
        if (_iou(cand.rect, existing.rect) > 0.35) {
          // Same region — keep the one with higher confidence or longer text
          if (cand.confidence > existing.confidence ||
              cand.text.length > existing.text.length) {
            result[i] = cand;
          }
          dominated = true;
          break;
        }
      }
      if (!dominated) result.add(cand);
    }
    return result;
  }

  static double _iou(Rect a, Rect b) {
    final ix = a.intersect(b);
    if (ix.isEmpty) return 0.0;
    final iA = ix.width * ix.height;
    final uA = a.width * a.height + b.width * b.height - iA;
    return uA <= 0 ? 0 : iA / uA;
  }

  // ── Build OcrWord list with colour sampling ───────────────────────────────

  static List<OcrWord> _buildWords(
    List<_Raw> rawWords,
    img.Image image,
    int imgW,
    int imgH,
  ) {
    final words = <OcrWord>[];
    for (final raw in rawWords) {
      final rect = Rect.fromLTRB(
        raw.rect.left.clamp(0.0, imgW.toDouble()),
        raw.rect.top.clamp(0.0, imgH.toDouble()),
        raw.rect.right.clamp(0.0, imgW.toDouble()),
        raw.rect.bottom.clamp(0.0, imgH.toDouble()),
      );
      if (rect.width <= 0 || rect.height <= 0) continue;

      final bgColor = _sampleBackground(image, rect);
      final textColor = _sampleInk(image, rect, bgColor);
      final fontSize = _estimateFontSize(image, rect, bgColor);

      words.add(
        OcrWord(
          text: raw.text,
          rect: rect,
          fontSize: fontSize,
          textColor: textColor,
          backgroundColor: bgColor,
        ),
      );
    }
    return words;
  }

  // ── Colour sampling ───────────────────────────────────────────────────────

  /// Sample background colour from a ring of real pixels around the word box.
  ///
  /// Works for both light-on-dark and dark-on-light text by:
  ///   1. Collecting the ring WITHOUT a luminance filter.
  ///   2. Taking the MEDIAN — which lands on the paper/background cluster
  ///      regardless of whether it's light or dark, because ink pixels are
  ///      a minority in the ring.
  static Color _sampleBackground(img.Image image, Rect rect) {
    final ringW = math.max(8, (rect.width * 0.15).round()).clamp(6, 24);
    final ringH = math.max(8, (rect.height * 0.30).round()).clamp(6, 24);

    final ox0 = (rect.left.toInt() - ringW).clamp(0, image.width - 1);
    final oy0 = (rect.top.toInt() - ringH).clamp(0, image.height - 1);
    final ox1 = (rect.right.toInt() + ringW).clamp(0, image.width - 1);
    final oy1 = (rect.bottom.toInt() + ringH).clamp(0, image.height - 1);

    // Inner word box to exclude
    final ix0 = rect.left.toInt().clamp(0, image.width - 1);
    final iy0 = rect.top.toInt().clamp(0, image.height - 1);
    final ix1 = rect.right.toInt().clamp(0, image.width - 1);
    final iy1 = rect.bottom.toInt().clamp(0, image.height - 1);

    final rs = <int>[], gs = <int>[], bs = <int>[];
    final step = math.max(1, ((ox1 - ox0) * (oy1 - oy0) / 800).ceil());

    for (var y = oy0; y <= oy1; y += step) {
      for (var x = ox0; x <= ox1; x += step) {
        if (x >= ix0 && x <= ix1 && y >= iy0 && y <= iy1) continue;
        final px = image.getPixel(x, y);
        rs.add(px.r.toInt());
        gs.add(px.g.toInt());
        bs.add(px.b.toInt());
      }
    }

    if (rs.length < 6) {
      // Near an edge — sample the entire outer+inner zone
      for (var y = oy0; y <= oy1; y += step) {
        for (var x = ox0; x <= ox1; x += step) {
          final px = image.getPixel(x, y);
          rs.add(px.r.toInt());
          gs.add(px.g.toInt());
          bs.add(px.b.toInt());
        }
      }
    }

    if (rs.isEmpty) return Colors.white;

    // Median of the ring — ink pixels are a minority so median == background
    rs.sort();
    gs.sort();
    bs.sort();
    final mid = rs.length ~/ 2;
    return Color.fromARGB(255, rs[mid], gs[mid], bs[mid]);
  }

  /// Sample ink colour from within the word box.
  ///
  /// Determines whether this is dark-on-light or light-on-dark text by
  /// comparing box interior median to the background luminance, then picks
  /// the pixels that are most different from background.
  ///
  /// After averaging, snaps the result toward the nearest pure colour
  /// (black, white, common ink colours) when it's close, to counteract JPEG
  /// compression artifacts that grey-ify pure colours.
  static Color _sampleInk(img.Image image, Rect rect, Color bg) {
    final bgLum = _lum(bg.r * 255, bg.g * 255, bg.b * 255);
    final all = _collectBox(image, rect);
    if (all.isEmpty) return bgLum > 0.5 ? Colors.black : Colors.white;

    // Ink is on the opposite side of the background
    final darkOnLight = bgLum > 0.5;

    List<(int, int, int, double)> ink;
    if (darkOnLight) {
      // Ink pixels are darker than background
      final thresh = bgLum - 0.15;
      ink = all.where((e) => e.$4 < thresh).toList();
    } else {
      // Light ink on dark background
      final thresh = bgLum + 0.15;
      ink = all.where((e) => e.$4 > thresh).toList();
    }

    // If nothing passes the threshold, take the 15% most different pixels
    if (ink.isEmpty) {
      if (darkOnLight) {
        all.sort((a, b) => a.$4.compareTo(b.$4)); // darkest first
      } else {
        all.sort((a, b) => b.$4.compareTo(a.$4)); // lightest first
      }
      final take = (all.length * 0.15).ceil().clamp(1, 30);
      ink = all.take(take).toList();
    }

    int sumR = 0, sumG = 0, sumB = 0;
    for (final e in ink) {
      sumR += e.$1;
      sumG += e.$2;
      sumB += e.$3;
    }
    final avgR = sumR ~/ ink.length;
    final avgG = sumG ~/ ink.length;
    final avgB = sumB ~/ ink.length;

    // Snap toward pure anchors to fix JPEG compression greyification
    return _snapToAnchor(avgR, avgG, avgB, darkOnLight);
  }

  /// Snap a colour toward the nearest perceptually-pure anchor if it's close.
  /// Thresholds tuned for typical JPEG compression artifacts on text:
  ///   - Near-black (each channel < 60) → pure black
  ///   - Near-white (each channel > 200) → pure white
  ///   - Clearly coloured → keep as-is (blue ink, red stamps, etc.)
  static Color _snapToAnchor(int r, int g, int b, bool darkOnLight) {
    final lum = _lum(r.toDouble(), g.toDouble(), b.toDouble());

    // Near-black: snap to pure black
    if (lum < 0.22 && r < 70 && g < 70 && b < 70) {
      return const Color(0xFF000000);
    }

    // Near-white: snap to pure white
    if (lum > 0.82 && r > 190 && g > 190 && b > 190) {
      return const Color(0xFFFFFFFF);
    }

    // Dark-grey that should be black (JPEG artefact on black text)
    if (darkOnLight && lum < 0.35) {
      // Check if it's neutral (not coloured)
      final maxC = math.max(r, math.max(g, b));
      final minC = math.min(r, math.min(g, b));
      if (maxC - minC < 40) {
        // Neutral dark — snap toward black
        final snap = (lum * 0.4 * 255).round().clamp(0, 80);
        return Color.fromARGB(255, snap, snap, snap);
      }
    }

    // Light-grey that should be white (JPEG artefact on white text)
    if (!darkOnLight && lum > 0.65) {
      final maxC = math.max(r, math.max(g, b));
      final minC = math.min(r, math.min(g, b));
      if (maxC - minC < 40) {
        final snap = (lum * 1.5 * 255).round().clamp(200, 255);
        return Color.fromARGB(255, snap, snap, snap);
      }
    }

    return Color.fromARGB(255, r, g, b);
  }

  // ── Font size estimation ──────────────────────────────────────────────────

  /// Scan rows of the bounding box to find the actual ink extent vertically.
  /// ML Kit boxes often include leading/descender space — this trims that off.
  static double _estimateFontSize(img.Image image, Rect rect, Color bg) {
    final x0 = rect.left.toInt().clamp(0, image.width - 1);
    final y0 = rect.top.toInt().clamp(0, image.height - 1);
    final x1 = rect.right.toInt().clamp(0, image.width - 1);
    final y1 = rect.bottom.toInt().clamp(0, image.height - 1);
    final rowLen = (x1 - x0 + 1).clamp(1, 9999);

    final bgLum = _lum(bg.r * 255, bg.g * 255, bg.b * 255);

    // A row is "ink" if ≥7% of its pixels deviate from background lum by > 0.10
    const minInkFraction = 0.07;
    const lumDelta = 0.10;

    int firstInk = y1, lastInk = y0;
    for (var y = y0; y <= y1; y++) {
      int inkCount = 0;
      final step = math.max(1, rowLen ~/ 20);
      for (var x = x0; x <= x1; x += step) {
        final px = image.getPixel(x, y);
        final lum = _lum(px.r.toDouble(), px.g.toDouble(), px.b.toDouble());
        if ((lum - bgLum).abs() > lumDelta) inkCount++;
      }
      if (inkCount / (rowLen / step) >= minInkFraction) {
        if (y < firstInk) firstInk = y;
        if (y > lastInk) lastInk = y;
      }
    }

    final inkH = (lastInk - firstInk + 1).toDouble();
    // Flutter's TextPainter renders glyphs at ~72% of the fontSize value.
    // Divide by 0.72 so the rendered text actually fills the measured ink height.
    final fallback = rect.height * 1.0; // use full box height as fallback
    return (inkH > 4) ? (inkH / 0.72).clamp(6.0, rect.height * 1.4) : fallback;
  }

  // ── Pixel helpers ─────────────────────────────────────────────────────────

  static double _lum(double r, double g, double b) =>
      (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

  /// Collect sampled pixels from a bounding box as (r, g, b, luminance).
  static List<(int, int, int, double)> _collectBox(img.Image image, Rect rect) {
    final x0 = rect.left.toInt().clamp(0, image.width - 1);
    final y0 = rect.top.toInt().clamp(0, image.height - 1);
    final x1 = rect.right.toInt().clamp(0, image.width - 1);
    final y1 = rect.bottom.toInt().clamp(0, image.height - 1);
    final area = (x1 - x0 + 1) * (y1 - y0 + 1);
    final step = math.max(1, (area / 300).ceil());
    final result = <(int, int, int, double)>[];
    for (var y = y0; y <= y1; y += step) {
      for (var x = x0; x <= x1; x += step) {
        final px = image.getPixel(x, y);
        final r = px.r.toInt();
        final g = px.g.toInt();
        final b = px.b.toInt();
        result.add((r, g, b, _lum(r.toDouble(), g.toDouble(), b.toDouble())));
      }
    }
    return result;
  }
}

class _Raw {
  final String text;
  final Rect rect;
  final double confidence;
  const _Raw({
    required this.text,
    required this.rect,
    required this.confidence,
  });
}
