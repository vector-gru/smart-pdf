import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' as pdfrx;

import 'ocr_service.dart';

/// Patches a scanned image in-place:
///   1. Fills the word bounding box with the Gemini-supplied background colour.
///   2. Renders the replacement text with the Gemini-supplied ink colour and
///      font size, scaled to exactly fill the available width.
class ImageTextEditor {
  ImageTextEditor._();

  // ── Primary entry point (scanner flow) ────────────────────────────────────

  static Future<String> replaceWordInImage({
    required String imagePath,
    required Rect wordRect,
    required String newText,
    required double fontSize,
    required Color textColor,
    required Color backgroundColor,
    required int imageWidth,
    required int imageHeight,
  }) => replaceWord(
    imagePath: imagePath,
    wordRect: wordRect,
    newText: newText,
    fontSize: fontSize,
    textColor: textColor,
    backgroundColor: backgroundColor,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
  );

  // ── Core replacement ───────────────────────────────────────────────────────

  static Future<String> replaceWord({
    required String imagePath,
    required Rect wordRect,
    required String newText,
    required double fontSize,
    required Color textColor,
    required Color backgroundColor,
    required int imageWidth,
    required int imageHeight,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final source = img.decodeImage(bytes);
    if (source == null) throw Exception('ImageTextEditor: cannot decode image');

    // Expand the erase box slightly to cover anti-aliased ink edges
    const pad = 2;
    final x0 = (wordRect.left.toInt() - pad).clamp(0, source.width - 1);
    final y0 = (wordRect.top.toInt() - pad).clamp(0, source.height - 1);
    final x1 = (wordRect.right.toInt() + pad).clamp(0, source.width - 1);
    final y1 = (wordRect.bottom.toInt() + pad).clamp(0, source.height - 1);

    // ── 1. Fill with background colour ────────────────────────────────────
    _fillRect(source, x0, y0, x1, y1, backgroundColor);

    // ── 2. Render replacement text and composite ──────────────────────────
    final boxW = (x1 - x0).toDouble();
    final boxH = (y1 - y0).toDouble();

    final textRgba = await _renderText(
      text: newText,
      fontSize: fontSize,
      textColor: textColor,
      boxWidth: boxW,
      boxHeight: boxH,
    );

    if (textRgba != null) {
      _compositeRgba(
        dst: source,
        src: textRgba,
        srcWidth: x1 - x0,
        srcHeight: y1 - y0,
        dstX: x0,
        dstY: y0,
      );
    }

    await File(imagePath).writeAsBytes(img.encodeJpg(source, quality: 93));
    return imagePath;
  }

  /// Replace multiple words in one image-load/save cycle.
  static Future<String> replaceWords({
    required String imagePath,
    required List<OcrWord> originalWords,
    required List<String> replacements,
    required int imageWidth,
    required int imageHeight,
  }) async {
    assert(originalWords.length == replacements.length);

    final bytes = await File(imagePath).readAsBytes();
    final source = img.decodeImage(bytes);
    if (source == null) throw Exception('ImageTextEditor: cannot decode image');

    for (var i = 0; i < originalWords.length; i++) {
      final word = originalWords[i];
      final newText = replacements[i];
      if (newText == word.text) continue;

      const pad = 2;
      final x0 = (word.rect.left.toInt() - pad).clamp(0, source.width - 1);
      final y0 = (word.rect.top.toInt() - pad).clamp(0, source.height - 1);
      final x1 = (word.rect.right.toInt() + pad).clamp(0, source.width - 1);
      final y1 = (word.rect.bottom.toInt() + pad).clamp(0, source.height - 1);

      _fillRect(source, x0, y0, x1, y1, word.backgroundColor);

      final textRgba = await _renderText(
        text: newText,
        fontSize: word.fontSize,
        textColor: word.textColor,
        boxWidth: (x1 - x0).toDouble(),
        boxHeight: (y1 - y0).toDouble(),
      );
      if (textRgba != null) {
        _compositeRgba(
          dst: source,
          src: textRgba,
          srcWidth: x1 - x0,
          srcHeight: y1 - y0,
          dstX: x0,
          dstY: y0,
        );
      }
    }

    await File(imagePath).writeAsBytes(img.encodeJpg(source, quality: 93));
    return imagePath;
  }

  // ── PDF rebuild ────────────────────────────────────────────────────────────

  static Future<void> rebuildPdfPage({
    required String pdfPath,
    required int pageIndex,
    required String patchedImagePath,
  }) async {
    final document = await pdfrx.PdfDocument.openFile(pdfPath);
    final pageCount = document.pages.length;
    final pdf = pw.Document();

    for (var i = 0; i < pageCount; i++) {
      if (i == pageIndex) {
        final imgBytes = await File(patchedImagePath).readAsBytes();
        final pwImage = pw.MemoryImage(imgBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (_) =>
                pw.Center(child: pw.Image(pwImage, fit: pw.BoxFit.contain)),
          ),
        );
      } else {
        final page = await document.pages[i];
        const scale = 2.0;
        final w = (page.width * scale).round();
        final h = (page.height * scale).round();
        final rendered = await page.render(
          fullWidth: w.toDouble(),
          fullHeight: h.toDouble(),
          backgroundColor: 0xffffffff,
        );
        if (rendered == null) continue;
        final uiImage = await rendered.createImage();
        final byteData = await uiImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        rendered.dispose();
        uiImage.dispose();
        if (byteData != null) {
          final rgba = byteData.buffer.asUint8List();
          final imgObj = img.Image.fromBytes(
            width: w,
            height: h,
            bytes: rgba.buffer,
            order: img.ChannelOrder.rgba,
            numChannels: 4,
          );
          final jpegBytes = img.encodeJpg(imgObj, quality: 90);
          final pwImage = pw.MemoryImage(Uint8List.fromList(jpegBytes));
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (_) =>
                  pw.Center(child: pw.Image(pwImage, fit: pw.BoxFit.contain)),
            ),
          );
        }
      }
    }

    await document.dispose();
    final tmpDir = await getTemporaryDirectory();
    final tmpPath = p.join(
      tmpDir.path,
      'rebuilt_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await File(tmpPath).writeAsBytes(await pdf.save());
    await File(tmpPath).copy(pdfPath);
    await File(tmpPath).delete();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Flat fill — Gemini already gave us the correct background colour.
  static void _fillRect(
    img.Image image,
    int x0,
    int y0,
    int x1,
    int y1,
    Color color,
  ) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }

  /// Render [text] on a transparent canvas scaled to fill [boxWidth]×[boxHeight].
  ///
  /// Fixes vs previous version:
  ///   - NO vertical centering offset — text is painted at y=0 so it sits at
  ///     the top of the box, matching where ML Kit reports the glyph starts.
  ///   - Horizontal scale only applied when text would overflow; it never
  ///     stretches wider than the box.
  ///   - Rendered at 2× for sharper sub-pixel edges, then downscaled.
  static Future<Uint8List?> _renderText({
    required String text,
    required double fontSize,
    required Color textColor,
    required double boxWidth,
    required double boxHeight,
  }) async {
    if (boxWidth <= 0 || boxHeight <= 0 || text.isEmpty) return null;

    const ss = 2.0;
    final rW = (boxWidth * ss).ceil();
    final rH = (boxHeight * ss).ceil();
    final scaledFs = (fontSize * ss).clamp(8.0, rH * 0.95);

    final style = TextStyle(
      color: textColor,
      fontSize: scaledFs,
      fontWeight: FontWeight.normal,
      letterSpacing: 0,
      decoration: TextDecoration.none,
      height: 1.0,
    );

    // Measure at natural width (don't artificially constrain)
    final measurer = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    measurer.layout();

    // Only scale horizontally if the text is wider than the box.
    // Never stretch — only compress, and cap compression at 50% so tiny
    // fonts don't become unreadable.
    final naturalW = measurer.width.clamp(1.0, double.infinity);
    final hScale = naturalW > rW ? (rW / naturalW).clamp(0.5, 1.0) : 1.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.save();
    canvas.scale(hScale, 1.0);
    // Paint at (0, 0) — no vertical offset — so the glyph top matches the
    // top of the bounding box as reported by ML Kit.
    measurer.paint(canvas, Offset.zero);
    canvas.restore();

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(rW, rH);
    final byteData = await uiImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    uiImage.dispose();
    picture.dispose();
    if (byteData == null) return null;

    return _downscale(
      byteData.buffer.asUint8List(),
      srcW: rW,
      srcH: rH,
      dstW: boxWidth.ceil(),
      dstH: boxHeight.ceil(),
    );
  }

  static Uint8List _downscale(
    Uint8List src, {
    required int srcW,
    required int srcH,
    required int dstW,
    required int dstH,
  }) {
    final dst = Uint8List(dstW * dstH * 4);
    final scaleX = srcW / dstW;
    final scaleY = srcH / dstH;

    for (var dy = 0; dy < dstH; dy++) {
      for (var dx = 0; dx < dstW; dx++) {
        final sx0 = (dx * scaleX).floor().clamp(0, srcW - 1);
        final sy0 = (dy * scaleY).floor().clamp(0, srcH - 1);
        final sx1 = ((dx + 1) * scaleX).floor().clamp(0, srcW - 1);
        final sy1 = ((dy + 1) * scaleY).floor().clamp(0, srcH - 1);

        int sR = 0, sG = 0, sB = 0, sA = 0, n = 0;
        for (var sy = sy0; sy <= sy1; sy++) {
          for (var sx = sx0; sx <= sx1; sx++) {
            final o = (sy * srcW + sx) * 4;
            sR += src[o];
            sG += src[o + 1];
            sB += src[o + 2];
            sA += src[o + 3];
            n++;
          }
        }
        if (n == 0) n = 1;
        final o = (dy * dstW + dx) * 4;
        dst[o] = sR ~/ n;
        dst[o + 1] = sG ~/ n;
        dst[o + 2] = sB ~/ n;
        dst[o + 3] = sA ~/ n;
      }
    }
    return dst;
  }

  static void _compositeRgba({
    required img.Image dst,
    required Uint8List src,
    required int srcWidth,
    required int srcHeight,
    required int dstX,
    required int dstY,
  }) {
    for (var y = 0; y < srcHeight; y++) {
      final absY = dstY + y;
      if (absY < 0 || absY >= dst.height) continue;
      for (var x = 0; x < srcWidth; x++) {
        final absX = dstX + x;
        if (absX < 0 || absX >= dst.width) continue;
        final o = (y * srcWidth + x) * 4;
        if (o + 3 >= src.length) continue;
        final a = src[o + 3] / 255.0;
        if (a < 0.02) continue;

        final px = dst.getPixel(absX, absY);
        dst.setPixelRgb(
          absX,
          absY,
          (src[o] * a + px.r * (1 - a)).round().clamp(0, 255),
          (src[o + 1] * a + px.g * (1 - a)).round().clamp(0, 255),
          (src[o + 2] * a + px.b * (1 - a)).round().clamp(0, 255),
        );
      }
    }
  }
}
