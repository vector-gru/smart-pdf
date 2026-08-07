import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import 'package:image/image.dart' as img;
import '../constants/app_colors.dart';
import '../utils/id_card_composer.dart';

/// Result returned from [IdCardEditPage].
class IdCardEditResult {
  /// Path to the final composited image file (temp directory).
  final String compositePath;
  IdCardEditResult(this.compositePath);
}

/// Interactive editor shown after the user picks the two ID card images.
/// Allows:
///   - Toggling between horizontal (side-by-side) and vertical (stacked) layout.
///   - Rotating the front image independently (90° CW each tap).
///   - Rotating the back image independently (90° CW each tap).
///
/// Tapping "Done" composites the images (with current rotations + layout) and
/// pops [IdCardEditResult] back to the caller.
class IdCardEditPage extends StatefulWidget {
  final String frontPath;
  final String backPath;

  const IdCardEditPage({
    super.key,
    required this.frontPath,
    required this.backPath,
  });

  @override
  State<IdCardEditPage> createState() => _IdCardEditPageState();
}

class _IdCardEditPageState extends State<IdCardEditPage> {
  /// Rotation in 90° steps for each side (0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°).
  int _frontRotation = 0; // steps × 90°
  int _backRotation = 0;

  /// true = side-by-side (landscape); false = stacked (portrait).
  bool _horizontal = true;

  bool _compositing = false;

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Rotates [steps] by +1 (90° CW), wrapping at 4.
  int _rotateStep(int steps) => (steps + 1) % 4;

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.scannerScanTypeIdCard,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _compositing ? null : _finish,
            child: _compositing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.scannerIdCardDone,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── preview area ──────────────────────────────────────────────
            Expanded(child: _buildPreview()),
            // ── controls ─────────────────────────────────────────────────
            _buildControls(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_horizontal) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildSide(widget.frontPath, _frontRotation)),
            const SizedBox(width: 12),
            Expanded(child: _buildSide(widget.backPath, _backRotation)),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(child: _buildSide(widget.frontPath, _frontRotation)),
            const SizedBox(height: 12),
            Expanded(child: _buildSide(widget.backPath, _backRotation)),
          ],
        ),
      );
    }
  }

  Widget _buildSide(String path, int rotationSteps) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: RotatedBox(
          quarterTurns: rotationSteps,
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildControls(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layout toggle row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.scannerIdCardLayoutTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              _LayoutToggleButton(
                icon: Icons.view_column_outlined,
                label: l10n.scannerIdCardLayoutHorizontal,
                selected: _horizontal,
                onTap: () => setState(() => _horizontal = true),
              ),
              const SizedBox(width: 8),
              _LayoutToggleButton(
                icon: Icons.table_rows_outlined,
                label: l10n.scannerIdCardLayoutVertical,
                selected: !_horizontal,
                onTap: () => setState(() => _horizontal = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rotation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RotateButton(
                label: l10n.scannerIdCardRotateFront,
                onTap: () => setState(
                  () => _frontRotation = _rotateStep(_frontRotation),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.grey[200]),
              _RotateButton(
                label: l10n.scannerIdCardRotateBack,
                onTap: () =>
                    setState(() => _backRotation = _rotateStep(_backRotation)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── finish ────────────────────────────────────────────────────────────────

  Future<void> _finish() async {
    setState(() => _compositing = true);
    try {
      // Apply pixel-level rotations before handing to the composer.
      final frontPath = await _applyRotation(
        widget.frontPath,
        _frontRotation,
        'idcard_front',
      );
      final backPath = await _applyRotation(
        widget.backPath,
        _backRotation,
        'idcard_back',
      );

      final compositePath = await IdCardComposer.compose(
        frontPath,
        backPath,
        horizontal: _horizontal,
      );
      if (mounted) {
        Navigator.of(context).pop(IdCardEditResult(compositePath));
      }
    } catch (_) {
      setState(() => _compositing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not compose ID card images.')),
        );
      }
    }
  }

  /// Rotates the image at [sourcePath] by [steps]×90° and saves to a temp
  /// file.  Returns [sourcePath] unchanged if [steps] == 0.
  Future<String> _applyRotation(
    String sourcePath,
    int steps,
    String prefix,
  ) async {
    if (steps == 0) return sourcePath;
    final bytes = await File(sourcePath).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return sourcePath;
    decoded = img.bakeOrientation(decoded);
    final rotated = img.copyRotate(decoded, angle: steps * 90.0);
    final tmpDir = Directory('${Directory.systemTemp.path}/smart_pdf_temp');
    await tmpDir.create(recursive: true);
    final outPath =
        '${tmpDir.path}/${prefix}_rot_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(rotated, quality: 92));
    return outPath;
  }
}

// ── small reusable widgets ────────────────────────────────────────────────────

class _LayoutToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LayoutToggleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryMuted.withValues(alpha: 0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryMuted : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primaryMuted : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.primaryMuted : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RotateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rotate_right, size: 22, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
