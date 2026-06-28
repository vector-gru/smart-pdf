import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_pdf/l10n/app_localizations.dart';
import '../constants/app_constants.dart';

/// Returns the reordered list of image paths, or null if cancelled.
class ReorderPage extends StatefulWidget {
  final List<String> images;
  const ReorderPage({super.key, required this.images});

  @override
  State<ReorderPage> createState() => _ReorderPageState();
}

class _ReorderPageState extends State<ReorderPage> {
  late List<String> _images;
  int? _draggingIndex;   // index currently being dragged
  int? _hoverIndex;      // index of the slot being hovered over

  @override
  void initState() {
    super.initState();
    _images = List.of(widget.images);
  }

  void _onDragStarted(int index) {
    setState(() {
      _draggingIndex = index;
      _hoverIndex = index;
    });
  }

  void _onDragEnd(int fromIndex) {
    if (_hoverIndex != null && _hoverIndex != fromIndex) {
      setState(() {
        final item = _images.removeAt(fromIndex);
        _images.insert(_hoverIndex!, item);
      });
    }
    setState(() {
      _draggingIndex = null;
      _hoverIndex = null;
    });
  }

  void _onHover(int index) {
    if (_hoverIndex != index) {
      setState(() => _hoverIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.cropAppBarPaddingH, vertical: AppConstants.cropAppBarPaddingV),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, size: AppConstants.reorderAppBarIconSize),
            onPressed: () => Navigator.pop(context, null),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.reorderPageTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: Icon(Icons.check, size: AppConstants.reorderAppBarIconSize, color: Colors.blue),
            onPressed: () => Navigator.pop(context, _images),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 24) / 2;
      const itemAspect = AppConstants.reorderCellAspect;
      final itemHeight = itemWidth / itemAspect;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.reorderGridPadding),
        child: Wrap(
          spacing: AppConstants.reorderGridSpacing,
          runSpacing: AppConstants.reorderGridRunSpacing,
          children: List.generate(_images.length, (index) {
            return _buildCell(index, itemWidth, itemHeight);
          }),
        ),
      );
    });
  }

  Widget _buildCell(int index, double width, double height) {
    final path = _images[index];
    final isDragging = _draggingIndex == index;
    final isHovered = _hoverIndex == index && _draggingIndex != null && _draggingIndex != index;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        _onHover(index);
        return true;
      },
      onAcceptWithDetails: (_) {}, // handled in _onDragEnd
      builder: (context, candidateData, rejectedData) {
        return SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LongPressDraggable<int>(
                data: index,
                delay: const Duration(milliseconds: AppConstants.reorderDragDelayMs),
                onDragStarted: () => _onDragStarted(index),
                onDragEnd: (_) => _onDragEnd(index),
                onDraggableCanceled: (velocity, offset) => setState(() {
                  _draggingIndex = null;
                  _hoverIndex = null;
                }),
                feedback: _buildThumbnail(path, width, height,
                    isDragging: false, isHovered: false, isFeedback: true),
                childWhenDragging: _buildPlaceholder(width, height),
                child: _buildThumbnail(path, width, height,
                    isDragging: isDragging, isHovered: isHovered),
              ),
                const SizedBox(height: AppConstants.reorderLabelGap),
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: AppConstants.reorderLabelFontSize,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(
    String path,
    double width,
    double height, {
    bool isDragging = false,
    bool isHovered = false,
    bool isFeedback = false,
  }) {
    return Material(
      elevation: isFeedback ? AppConstants.reorderCardElevationFeedback : (isDragging ? 0 : AppConstants.reorderCardElevationNormal),
      borderRadius: BorderRadius.circular(AppConstants.reorderCardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppConstants.reorderAnimDurationMs),
        width: isFeedback ? width * AppConstants.reorderCardFeedbackScale : width,
        height: isFeedback ? height * AppConstants.reorderCardFeedbackScale : height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.reorderCardRadius),
          border: isHovered
              ? Border.all(color: Colors.blue, width: AppConstants.reorderCardBorderWidth)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.reorderCardRadius),
          child: Opacity(
            opacity: isDragging ? 0.0 : 1.0,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              width: width,
              height: height,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppConstants.reorderCardRadius),
        border: Border.all(color: Colors.blue.withValues(alpha: AppConstants.reorderCardBorderAlpha), width: 2),
      ),
    );
  }
}
