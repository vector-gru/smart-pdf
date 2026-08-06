import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import '../constants/app_constants.dart';

class ColorFilterSheet extends StatefulWidget {
  final String imagePath;
  final String originalPath;

  /// Called with the chosen filter name, strength (0.0–2.0, 1.0 = default),
  /// and whether to apply to all pages.
  final void Function(String filterName, double strength, bool applyToAll)
  onApply;
  const ColorFilterSheet({
    super.key,
    required this.imagePath,
    required this.originalPath,
    required this.onApply,
  });

  @override
  State<ColorFilterSheet> createState() => _ColorFilterSheetState();
}

class _ColorFilterSheetState extends State<ColorFilterSheet> {
  String _selected = 'default';
  double _strength = 1.0;
  bool _applyToAll = false;

  static const _filters = [
    ('default', 'Default'),
    ('magic1', 'Magic 1'),
    ('magic2', 'Magic 2'),
    ('bw1', 'B&W 1'),
    ('bw2', 'B&W 2'),
    ('gray', 'Gray'),
  ];

  void _selectFilter(String id) {
    setState(() {
      _selected = id;
      // Reset strength to full when switching filters so the preview
      // immediately shows the canonical effect.
      _strength = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final hasSlider = _selected != 'default';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Live full-image preview ──────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.filterSheetItemRadius),
            ),
            child: ColorFiltered(
              colorFilter:
                  colorFilterForStrength(_selected, _strength) ??
                  const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.file(
                File(widget.originalPath),
                height:
                    screenHeight *
                    AppConstants.filterSheetPreviewHeightFraction,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Strength slider (hidden for Default) ─────────────────────────
          if (hasSlider)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.filterSheetTogglePaddingH,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: _strength,
                        min: 0.0,
                        max: 2.0,
                        divisions: 40,
                        onChanged: (v) => setState(() => _strength = v),
                      ),
                    ),
                  ),
                  const Icon(Icons.wb_sunny, size: 20, color: Colors.grey),
                ],
              ),
            ),

          if (hasSlider) const SizedBox(height: 4),

          // ── Thumbnail selector row ───────────────────────────────────────
          SizedBox(
            height: AppConstants.filterSheetHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.filterSheetPaddingH,
              ),
              separatorBuilder: (_, __) =>
                  SizedBox(width: AppConstants.filterSheetSeparatorWidth),
              itemCount: _filters.length,
              itemBuilder: (context, i) {
                final (id, label) = _filters[i];
                final isSelected = _selected == id;
                return GestureDetector(
                  onTap: () => _selectFilter(id),
                  child: Column(
                    children: [
                      Container(
                        width: AppConstants.filterSheetItemWidth,
                        height: AppConstants.filterSheetItemHeight,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: isSelected
                                ? AppConstants.filterSheetSelectedBorderWidth
                                : AppConstants.filterSheetItemBorderWidth,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.filterSheetItemRadius,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppConstants.filterSheetItemRadius - 1,
                          ),
                          child: ColorFiltered(
                            // Thumbnails always show the canonical (strength=1) effect.
                            colorFilter:
                                colorFilterForStrength(id, 1.0) ??
                                const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                            child: Image.file(
                              File(widget.originalPath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppConstants.filterSheetLabelGap),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: AppConstants.filterSheetLabelFontSize,
                          color: isSelected ? Colors.blue : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: AppConstants.filterSheetToggleGap),

          // ── Apply-to-all toggle ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.filterSheetTogglePaddingH,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.filterApplyToAll,
                  style: TextStyle(
                    fontSize: AppConstants.filterSheetToggleFontSize,
                  ),
                ),
                Switch(
                  value: _applyToAll,
                  onChanged: (v) => setState(() => _applyToAll = v),
                ),
              ],
            ),
          ),

          SizedBox(height: AppConstants.filterSheetApplyGap),

          // ── Apply button ─────────────────────────────────────────────────
          ElevatedButton(
            onPressed: () => widget.onApply(_selected, _strength, _applyToAll),
            child: Text(AppLocalizations.of(context)!.filterApply),
          ),

          SizedBox(height: AppConstants.filterSheetToggleGap),
        ],
      ),
    );
  }
}

// ── Matrix helpers ────────────────────────────────────────────────────────────

/// Identity 5×4 matrix (no change).
const List<double> _kIdentity = [
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// Canonical matrices at strength = 1.0.
const Map<String, List<double>> _kBaseMatrices = {
  'magic1': [
    1.9,
    0,
    0,
    0,
    -50,
    0,
    1.9,
    0,
    0,
    -50,
    0,
    0,
    1.9,
    0,
    -50,
    0,
    0,
    0,
    1,
    0,
  ],
  'magic2': [
    0.77,
    0.63,
    0.24,
    0,
    -40,
    0.07,
    1.53,
    0.06,
    0,
    -40,
    0.02,
    0.18,
    1.44,
    0,
    -40,
    0,
    0,
    0,
    1,
    0,
  ],
  'bw1': [
    0.299,
    0.587,
    0.114,
    0,
    60,
    0.299,
    0.587,
    0.114,
    0,
    60,
    0.299,
    0.587,
    0.114,
    0,
    60,
    0,
    0,
    0,
    1,
    0,
  ],
  'bw2': [
    1.5,
    1.5,
    1.5,
    0,
    -200,
    1.5,
    1.5,
    1.5,
    0,
    -200,
    1.5,
    1.5,
    1.5,
    0,
    -200,
    0,
    0,
    0,
    1,
    0,
  ],
  'gray': [
    0.299,
    0.587,
    0.114,
    0,
    0,
    0.299,
    0.587,
    0.114,
    0,
    0,
    0.299,
    0.587,
    0.114,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ],
};

/// Returns a [ColorFilter] for [id] scaled to [strength].
///
/// Strength semantics:
///   0.0  → identity (no effect)
///   1.0  → canonical filter as designed
///   2.0  → double the deviation from identity (maximum extreme)
///
/// Returns null for 'default' (caller should use no-op filter).
ColorFilter? colorFilterForStrength(String id, double strength) {
  final base = _kBaseMatrices[id];
  if (base == null) return null; // 'default'

  // Lerp/extrapolate each element between identity and the base matrix.
  final result = List<double>.generate(20, (i) {
    return _kIdentity[i] + (_kIdentity[i] - base[i]) * -strength;
    // Equivalent to: identity[i] + (base[i] - identity[i]) * strength
  });

  return ColorFilter.matrix(result);
}

/// Convenience alias used by scanner_page.dart (always canonical strength).
ColorFilter? colorFilterFor(String id) => colorFilterForStrength(id, 1.0);

/// Returns the scaled matrix as a plain [List<double>] for pixel-level
/// processing (used by scanner_page._applyColorFilter).
List<double> colorMatrixForStrength(String id, double strength) {
  final base = _kBaseMatrices[id];
  if (base == null) {
    return List<double>.from(_kIdentity);
  }
  return List<double>.generate(20, (i) {
    return _kIdentity[i] + (base[i] - _kIdentity[i]) * strength;
  });
}
