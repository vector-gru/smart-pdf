import 'dart:io';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/image_text_editor.dart';
import '../services/ocr_service.dart';

/// Full-screen editor that runs OCR on a single scan [imagePath], overlays
/// detected word bounding boxes, and lets the user long-press words to edit
/// them in-place.
///
/// Returns `true` via `Navigator.pop` if the image was modified, so the
/// caller (ScannerPage) knows to refresh.
class SmartEditPage extends StatefulWidget {
  /// Absolute path to the JPEG image to edit.
  final String imagePath;

  /// 1-based page number shown in the header (e.g. "Page 2 of 5").
  final int pageNumber;
  final int totalPages;

  const SmartEditPage({
    super.key,
    required this.imagePath,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  State<SmartEditPage> createState() => _SmartEditPageState();
}

// ── States ────────────────────────────────────────────────────────────────────

enum _PageState { loading, ready, editing, saving }

class _SmartEditPageState extends State<SmartEditPage> {
  _PageState _state = _PageState.loading;
  String? _errorMessage;

  OcrResult? _ocr;

  // Selected word indices
  final Set<int> _selectedIndices = {};

  final _editController = TextEditingController();
  final _editFocus = FocusNode();

  // Tracks whether any edits were saved (so we can pop(true))
  bool _wasModified = false;

  // Version counter — incremented after each save to force Image.file refresh
  int _imageVersion = 0;

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  // ── OCR ────────────────────────────────────────────────────────────────────

  Future<void> _runOcr() async {
    setState(() {
      _state = _PageState.loading;
      _errorMessage = null;
    });
    try {
      final result = await OcrService.recognizeImage(
        imagePath: widget.imagePath,
      );
      if (mounted) {
        setState(() {
          _ocr = result;
          _state = _PageState.ready;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _state = _PageState.ready;
        });
      }
    }
  }

  // ── Coordinate mapping ─────────────────────────────────────────────────────

  /// Map a rect in OCR image-pixel space to the widget's render space.
  Rect _toDisplay(Rect imageRect, Size renderSize) {
    final ocr = _ocr!;
    final scaleX = renderSize.width / ocr.imageWidth;
    final scaleY = renderSize.height / ocr.imageHeight;
    return Rect.fromLTWH(
      imageRect.left * scaleX,
      imageRect.top * scaleY,
      imageRect.width * scaleX,
      imageRect.height * scaleY,
    );
  }

  // ── Interaction ────────────────────────────────────────────────────────────

  void _onWordLongPress(int index) {
    setState(() {
      _selectedIndices
        ..clear()
        ..add(index);
      _state = _PageState.editing;
      _editController.text = _ocr!.words[index].text;
      _editController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editController.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _editFocus.requestFocus(),
    );
  }

  void _onWordTap(int index) {
    if (_state != _PageState.editing) return;
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _state = _PageState.ready;
      } else {
        _selectedIndices.add(index);
        final combined = (_selectedIndices.toList()..sort())
            .map((i) => _ocr!.words[i].text)
            .join(' ');
        _editController.text = combined;
        _editController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: combined.length,
        );
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _selectedIndices.clear();
      _state = _PageState.ready;
      _editController.clear();
    });
    _editFocus.unfocus();
  }

  Future<void> _confirmEdit() async {
    final newText = _editController.text.trim();
    if (newText.isEmpty || _ocr == null) {
      _cancelEdit();
      return;
    }
    _editFocus.unfocus();
    setState(() => _state = _PageState.saving);

    try {
      final ocr = _ocr!;
      final selected = _selectedIndices.toList()..sort();

      if (selected.length == 1) {
        final word = ocr.words[selected.first];
        await ImageTextEditor.replaceWordInImage(
          imagePath: widget.imagePath,
          wordRect: word.rect,
          newText: newText,
          fontSize: word.fontSize,
          textColor: word.textColor,
          backgroundColor: word.backgroundColor,
          imageWidth: ocr.imageWidth,
          imageHeight: ocr.imageHeight,
        );
      } else {
        final rects = selected.map((i) => ocr.words[i].rect).toList();
        final merged = rects.fold<Rect>(
          rects.first,
          (acc, r) => acc.expandToInclude(r),
        );
        final styleWord = ocr.words[selected.first];
        await ImageTextEditor.replaceWordInImage(
          imagePath: widget.imagePath,
          wordRect: merged,
          newText: newText,
          fontSize: styleWord.fontSize,
          textColor: styleWord.textColor,
          backgroundColor: styleWord.backgroundColor,
          imageWidth: ocr.imageWidth,
          imageHeight: ocr.imageHeight,
        );
      }

      _wasModified = true;

      // Evict image cache so Image.file picks up the new pixels
      await FileImage(File(widget.imagePath)).evict();

      // Re-run OCR to keep bounding boxes accurate after edit
      await _runOcr();

      if (mounted) {
        setState(() => _imageVersion++);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Save failed: $e';
        _state = _PageState.ready;
        _selectedIndices.clear();
      });
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _done() => Navigator.of(context).pop(_wasModified);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Smart Edit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'Page ${widget.pageNumber} of ${widget.totalPages}  •  Long-press a word to edit',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_state == _PageState.ready || _state == _PageState.editing)
            TextButton(
              onPressed: _done,
              child: Text(
                _wasModified ? 'Done' : 'Close',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final renderSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              // ── Full-screen image ──────────────────────────────────────────
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.file(
                    File(widget.imagePath),
                    key: ValueKey(_imageVersion),
                    fit: BoxFit.contain,
                    width: renderSize.width,
                    height: renderSize.height,
                  ),
                ),
              ),

              // ── Word hit-areas ─────────────────────────────────────────────
              if (_ocr != null &&
                  _state != _PageState.loading &&
                  _state != _PageState.saving)
                Positioned.fill(
                  child: _WordOverlay(
                    ocr: _ocr!,
                    renderSize: renderSize,
                    selectedIndices: _selectedIndices,
                    toDisplay: _toDisplay,
                    onLongPress: _onWordLongPress,
                    onTap: _onWordTap,
                  ),
                ),

              // ── Loading / saving spinner ────────────────────────────────────
              if (_state == _PageState.loading || _state == _PageState.saving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: AppConstants.smartEditLoadingDimAlpha,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          _state == _PageState.saving
                              ? 'Applying changes…'
                              : 'Recognising text…',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppConstants.smartEditLoadingFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Edit popup ─────────────────────────────────────────────────
              if (_state == _PageState.editing && _selectedIndices.isNotEmpty)
                _EditPopup(
                  ocr: _ocr!,
                  selectedIndices: _selectedIndices,
                  editController: _editController,
                  editFocus: _editFocus,
                  renderSize: renderSize,
                  toDisplay: _toDisplay,
                  onCancel: _cancelEdit,
                  onConfirm: _confirmEdit,
                ),

              // ── Error banner ───────────────────────────────────────────────
              if (_errorMessage != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                ),

              // ── No-text hint ───────────────────────────────────────────────
              if (_state == _PageState.ready &&
                  _ocr != null &&
                  _ocr!.words.isEmpty &&
                  _errorMessage == null)
                const Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(child: _NoTextBadge()),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Extracted sub-widgets ──────────────────────────────────────────────────────

class _WordOverlay extends StatelessWidget {
  final OcrResult ocr;
  final Size renderSize;
  final Set<int> selectedIndices;
  final Rect Function(Rect, Size) toDisplay;
  final void Function(int) onLongPress;
  final void Function(int) onTap;

  const _WordOverlay({
    required this.ocr,
    required this.renderSize,
    required this.selectedIndices,
    required this.toDisplay,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(ocr.words.length, (index) {
        final displayRect = toDisplay(ocr.words[index].rect, renderSize);
        final isSelected = selectedIndices.contains(index);
        return Positioned(
          left: displayRect.left,
          top: displayRect.top,
          width: displayRect.width.clamp(
            AppConstants.smartEditMinHitWidth,
            double.infinity,
          ),
          height: displayRect.height.clamp(
            AppConstants.smartEditMinHitHeight,
            double.infinity,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => onLongPress(index),
            onTap: () => onTap(index),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.smartEditSelection
                    : AppColors.smartEditHover,
                borderRadius: BorderRadius.circular(
                  AppConstants.smartEditHitRadius,
                ),
                border: isSelected
                    ? Border.all(
                        color: AppColors.smartEditSelectionBorder,
                        width: AppConstants.smartEditSelectionBorderWidth,
                      )
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EditPopup extends StatelessWidget {
  final OcrResult ocr;
  final Set<int> selectedIndices;
  final TextEditingController editController;
  final FocusNode editFocus;
  final Size renderSize;
  final Rect Function(Rect, Size) toDisplay;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _EditPopup({
    required this.ocr,
    required this.selectedIndices,
    required this.editController,
    required this.editFocus,
    required this.renderSize,
    required this.toDisplay,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndices.toList()..sort();
    final anchorRect = toDisplay(ocr.words[selected.first].rect, renderSize);

    final popupTop = (anchorRect.top - AppConstants.smartEditPopupHeight - 8)
        .clamp(0.0, renderSize.height - AppConstants.smartEditPopupHeight);
    final popupLeft = anchorRect.left.clamp(
      0.0,
      (renderSize.width - AppConstants.smartEditPopupWidth).clamp(
        0.0,
        renderSize.width,
      ),
    );

    return Positioned(
      left: popupLeft,
      top: popupTop,
      width: AppConstants.smartEditPopupWidth,
      child: Material(
        elevation: AppConstants.smartEditPopupElevation,
        borderRadius: BorderRadius.circular(AppConstants.smartEditPopupRadius),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.smartEditPopupPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: AppConstants.smartEditPopupHeaderIconSize,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Replace text',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppConstants.smartEditPopupHeaderFontSize,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancel,
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Original: "${selected.map((i) => ocr.words[i].text).join(' ')}"',
                style: TextStyle(
                  fontSize: AppConstants.smartEditPopupHintFontSize,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: editController,
                focusNode: editFocus,
                decoration: InputDecoration(
                  hintText: 'Type replacement…',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
                onSubmitted: (_) => onConfirm(),
                style: const TextStyle(
                  fontSize: AppConstants.smartEditPopupFieldFontSize,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(
                      Icons.check,
                      size: AppConstants.smartEditPopupActionIconSize,
                    ),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

class _NoTextBadge extends StatelessWidget {
  const _NoTextBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'No text detected on this page',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
