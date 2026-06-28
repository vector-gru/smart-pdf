import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import '../constants/app_constants.dart';

class ColorFilterSheet extends StatefulWidget {
  final String imagePath;
  final String originalPath;
  final void Function(String filterName, bool applyToAll) onApply;
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
  bool _applyToAll = false;

  static const _filters = [
    ('default', 'Default'),
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
        padding: const EdgeInsets.symmetric(vertical: AppConstants.filterSheetToggleGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: AppConstants.filterSheetHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.filterSheetPaddingH),
                separatorBuilder: (_, __) => SizedBox(width: AppConstants.filterSheetSeparatorWidth),
                itemCount: _filters.length,
                itemBuilder: (context, i) {
                  final (id, label) = _filters[i];
                  final isSelected = _selected == id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = id),
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
                            borderRadius: BorderRadius.circular(AppConstants.filterSheetItemRadius),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.filterSheetItemRadius - 1),
                            child: ColorFiltered(
                              colorFilter: colorFilterFor(id) ??
                                  const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                              child: Image.file(File(widget.originalPath), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        SizedBox(height: AppConstants.filterSheetLabelGap),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: AppConstants.filterSheetLabelFontSize,
                            color: isSelected ? Colors.blue : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppConstants.filterSheetToggleGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.filterSheetTogglePaddingH),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.filterApplyToAll,
                    style: TextStyle(fontSize: AppConstants.filterSheetToggleFontSize),
                  ),
                  Switch(value: _applyToAll, onChanged: (v) => setState(() => _applyToAll = v)),
                ],
              ),
            ),
            SizedBox(height: AppConstants.filterSheetApplyGap),
            ElevatedButton(
              onPressed: () => widget.onApply(_selected, _applyToAll),
              child: Text(AppLocalizations.of(context)!.filterApply),
            ),
          ],
        ),
      ),
    );
  }
}

ColorFilter? colorFilterFor(String id) {
  switch (id) {
    case 'magic1':
      return const ColorFilter.matrix([
        1.9, 0, 0, 0, -50,
        0, 1.9, 0, 0, -50,
        0, 0, 1.9, 0, -50,
        0, 0, 0, 1, 0,
      ]);
    case 'magic2':
      return const ColorFilter.matrix([
        0.77, 0.63, 0.24, 0, -40,
        0.07, 1.53, 0.06, 0, -40,
        0.02, 0.18, 1.44, 0, -40,
        0, 0, 0, 1, 0,
      ]);
    case 'bw1':
      return const ColorFilter.matrix([
        0.299, 0.587, 0.114, 0, 60,
        0.299, 0.587, 0.114, 0, 60,
        0.299, 0.587, 0.114, 0, 60,
        0, 0, 0, 1, 0,
      ]);
    case 'bw2':
      return const ColorFilter.matrix([
        1.5, 1.5, 1.5, 0, -200,
        1.5, 1.5, 1.5, 0, -200,
        1.5, 1.5, 1.5, 0, -200,
        0, 0, 0, 1, 0,
      ]);
    case 'gray':
      return const ColorFilter.matrix([
        0.299, 0.587, 0.114, 0, 0,
        0.299, 0.587, 0.114, 0, 0,
        0.299, 0.587, 0.114, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    default:
      return null;
  }
}
