import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// A small pill-shaped drag handle shown at the top of modal bottom sheets.
///
/// Drop it as the first child in a sheet's Column to give users a clear
/// affordance for dragging the sheet up or down.
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.sheetHandleWidth,
      height: AppConstants.sheetHandleHeight,
      margin: const EdgeInsets.symmetric(
        vertical: AppConstants.sheetHandleMarginV,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppConstants.sheetHandleRadius),
      ),
    );
  }
}
