import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';

/// A small rounded thumbnail for a document, used in list/sheet rows.
///
/// Resolves the stored relative [thumbnailPath] to an absolute path
/// asynchronously and falls back to a PDF icon when the path is absent
/// or the file cannot be loaded.
class DocThumbnail extends StatefulWidget {
  final String? thumbnailPath;

  /// Width of the rendered thumbnail. Defaults to [AppConstants.collectionDocThumbWidth].
  final double width;

  /// Height of the rendered thumbnail. Defaults to [AppConstants.collectionDocThumbHeight].
  final double height;

  /// Corner radius. Defaults to [AppConstants.collectionDocThumbRadius].
  final double borderRadius;

  const DocThumbnail({
    super.key,
    this.thumbnailPath,
    this.width = AppConstants.collectionDocThumbWidth,
    this.height = AppConstants.collectionDocThumbHeight,
    this.borderRadius = AppConstants.collectionDocThumbRadius,
  });

  @override
  State<DocThumbnail> createState() => _DocThumbnailState();
}

class _DocThumbnailState extends State<DocThumbnail> {
  String? _absPath;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(DocThumbnail old) {
    super.didUpdateWidget(old);
    if (old.thumbnailPath != widget.thumbnailPath) _resolve();
  }

  Future<void> _resolve() async {
    final raw = widget.thumbnailPath;
    if (raw == null || raw.isEmpty) return;
    final abs = await resolveDocPath(raw);
    if (mounted) setState(() => _absPath = abs);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: _absPath != null
            ? Image.file(
                File(_absPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Center(
        child: Icon(
          Icons.picture_as_pdf,
          size: AppConstants.collectionDocThumbIconSize,
          color: Colors.grey,
        ),
      );
}
