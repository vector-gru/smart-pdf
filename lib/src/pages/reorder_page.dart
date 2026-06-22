import 'dart:io';
import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.pop(context, null),
          ),
          const Expanded(
            child: Text(
              'Reorder',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 28, color: Colors.blue),
            onPressed: () => Navigator.pop(context, _images),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 24) / 2; // 2 columns, 8px padding each side + 8px gap
      const itemAspect = 0.72; // portrait ratio
      final itemHeight = itemWidth / itemAspect;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 12,
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
                delay: const Duration(milliseconds: 300),
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
              const SizedBox(height: 6),
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
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
      elevation: isFeedback ? 8 : (isDragging ? 0 : 2),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isFeedback ? width * 0.9 : width,
        height: isFeedback ? height * 0.9 : height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: isHovered
              ? Border.all(color: Colors.blue, width: 2.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.4), width: 2),
      ),
    );
  }
}
