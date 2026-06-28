class AppConstants {
  AppConstants._();

  // Document card
  static const double cardThumbnailWidth = 80.0;
  static const double cardThumbnailHeight = 90.0;
  static const double cardBorderRadius = 12.0;
  static const double cardThumbnailRadius = 8.0;
  static const double cardPaddingH = 12.0;
  static const double cardPaddingV = 10.0;
  static const double cardMarginH = 16.0;
  static const double cardMarginV = 6.0;
  static const double cardElevation = 2.0;
  static const double cardGap = 12.0;

  // Typography
  static const double fontTitle = 15.0;
  static const double fontSubtitle = 12.0;

  // Action icons
  static const double actionIconSize = 20.0;
  static const double actionIconSpacing = 14.0;
  static const double actionIconPadding = 5.0;

  // FAB
  static const double fabRadius = 30.0;
  static const double fabIconSize = 24.0;
  static const double fabPaddingH = 18.0;
  static const double fabPaddingV = 12.0;
  static const double fabDividerWidth = 1.0;
  static const double fabDividerHeight = 28.0;

  // General
  static const double listBottomPadding = 100.0;
  static const double listTopPadding = 8.0;
  static const double emptyIconSize = 64.0;

  // Date format
  static const String dateFormat = 'dd-MMM-yy H:mm';

  // Scanner page
  static const double scannerPageViewFraction = 0.85;
  static const double scannerCardBorderRadius = 4.0;
  static const double scannerCardShadowBlur = 12.0;
  static const double scannerCardShadowAlpha = 0.12;
  static const double scannerPageItemShadowY = 4.0;
  static const double scannerPageItemPaddingH = 8.0;
  static const double scannerPageItemPaddingV = 16.0;
  static const double scannerBottomBarHeight = 64.0;
  static const double scannerBottomBarPaddingTop = 12.0;
  static const double scannerBottomBarPaddingBottom = 8.0;
  static const double scannerBottomBarItemWidth = 76.0;
  static const double scannerBottomBarItemPaddingH = 8.0;
  static const double scannerBottomBarIconSize = 26.0;
  static const double scannerBottomBarFontSize = 11.0;
  static const double scannerBottomBarIconGap = 4.0;
  static const double scannerIndicatorPaddingH = 14.0;
  static const double scannerIndicatorPaddingV = 6.0;
  static const double scannerIndicatorRadius = 16.0;
  static const double scannerIndicatorFontSize = 13.0;
  static const double scannerTitleFontSize = 16.0;
  static const double scannerTitlePaddingH = 32.0;
  static const double scannerTitlePaddingBottom = 8.0;
  static const double scannerTitleEditIconSize = 18.0;
  static const double scannerTitleEditIconGap = 6.0;
  static const double scannerTitleDashedLineWidth = 200.0;
  static const double scannerTitleDashedLineHeight = 2.0;
  static const double scannerDashWidth = 4.0;
  static const double scannerDashSpace = 3.0;
  static const int scannerCompressQuality = 82;
  static const int scannerCompressMinDimension = 1200;
  static const int scannerRotateAngle = 90;
  static const int scannerPageNavDuration = 300;
  static const double scannerShutterSize = 70.0;
  static const double scannerShutterBorderWidth = 4.0;
  static const double scannerShutterIconPadding = 18.0;
  static const double scannerShutterIconStrokeWidth = 3.0;
  static const double scannerCloseIconSize = 30.0;
  static const double scannerShutterBottom = 24.0;

  // Color filter sheet
  static const double filterSheetHeight = 120.0;
  static const double filterSheetItemWidth = 80.0;
  static const double filterSheetItemHeight = 90.0;
  static const double filterSheetItemRadius = 4.0;
  static const double filterSheetItemBorderWidth = 1.0;
  static const double filterSheetSelectedBorderWidth = 2.5;
  static const double filterSheetLabelFontSize = 12.0;
  static const double filterSheetLabelGap = 6.0;
  static const double filterSheetSeparatorWidth = 12.0;
  static const double filterSheetPaddingH = 16.0;
  static const double filterSheetTogglePaddingH = 24.0;
  static const double filterSheetToggleFontSize = 15.0;
  static const double filterSheetToggleGap = 16.0;
  static const double filterSheetApplyGap = 12.0;
  static const int filterBw2Threshold = 140;
  static const int filterBw2White = 255;

  // Crop page
  static const double cropPad = 20.0;
  static const double cropHandleCornerSize = 28.0;
  static const double cropHandleCornerRadius = 14.0;
  static const double cropHandleMidSize = 18.0;
  static const double cropHandleMidRadius = 9.0;
  static const double cropHandleTapThreshold = 40.0;
  static const double cropHandleBorderWidth = 2.0;
  static const double cropBorderWidth = 2.5;
  static const double cropDimAlpha = 0.50;
  static const double cropGridAlpha = 0.4;
  static const double cropGridStrokeWidth = 0.8;
  static const double cropAppBarPaddingH = 4.0;
  static const double cropAppBarPaddingV = 4.0;
  static const double cropAppBarTitleFontSize = 18.0;
  static const double cropAppBarTitleFontWeight = 600; // unused at runtime, doc only
  static const double cropPreviewBadgePaddingH = 10.0;
  static const double cropPreviewBadgePaddingV = 4.0;
  static const double cropPreviewBadgeRadius = 12.0;
  static const double cropPreviewBadgeFontSize = 11.0;
  static const double cropPreviewLabelPaddingH = 14.0;
  static const double cropPreviewLabelPaddingV = 6.0;
  static const double cropPreviewLabelRadius = 16.0;
  static const double cropPreviewLabelFontSize = 12.0;
  static const double cropPreviewLabelBottom = 12.0;
  static const double cropIndicatorPaddingH = 14.0;
  static const double cropIndicatorPaddingV = 5.0;
  static const double cropIndicatorRadius = 16.0;
  static const double cropIndicatorFontSize = 12.0;
  static const double cropIndicatorMarginV = 6.0;
  static const double cropBottomBarPaddingV = 10.0;
  static const double cropBtnWidth = 64.0;
  static const double cropBtnIconSize = 24.0;
  static const double cropBtnIconGap = 3.0;
  static const double cropBtnFontSize = 10.0;
  static const int cropPreviewJpgQuality = 88;
  static const int cropDoneJpgQuality = 90;
  static const int cropDisplayJpgQuality = 85;
  static const double cropAutoDetectLumThresh = 0.10;
  static const double cropAutoDetectMargin = 0.008;
  static const double cropAutoDetectMinCoverage = 0.20;
  static const double cropAutoDetectEdgeFrac = 0.03;
  static const double cropGradFallbackThresh = 0.30;
  static const int cropAutoDetectDownscale = 4;

  // Reorder page
  static const double reorderGridPadding = 8.0;
  static const double reorderGridSpacing = 8.0;
  static const double reorderGridRunSpacing = 12.0;
  static const double reorderCellAspect = 0.72;
  static const double reorderCardRadius = 6.0;
  static const double reorderCardBorderWidth = 2.5;
  static const double reorderCardBorderAlpha = 0.4;
  static const double reorderCardFeedbackScale = 0.9;
  static const double reorderCardElevationNormal = 2.0;
  static const double reorderCardElevationFeedback = 8.0;
  static const double reorderLabelFontSize = 14.0;
  static const double reorderLabelGap = 6.0;
  static const int reorderDragDelayMs = 300;
  static const int reorderAnimDurationMs = 150;
  static const double reorderAppBarIconSize = 28.0;

  // Viewer page
  static const double viewerPdfPadding = 4.0;
  static const double viewerShareFallbackSize = 100.0;
}
