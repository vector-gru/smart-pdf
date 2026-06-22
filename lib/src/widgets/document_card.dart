import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../db/app_db.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onMore;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
    required this.onExport,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.cardMarginH,
        vertical: AppConstants.cardMarginV,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      elevation: AppConstants.cardElevation,
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.cardPaddingH,
            vertical: AppConstants.cardPaddingV,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.cardThumbnailRadius),
                child: Container(
                  width: AppConstants.cardThumbnailWidth,
                  height: AppConstants.cardThumbnailHeight,
                  color: Colors.grey[200],
                  child: _buildThumbnail(),
                ),
              ),
              const SizedBox(width: AppConstants.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: AppConstants.fontTitle,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat(AppConstants.dateFormat).format(document.createdAt),
                      style: const TextStyle(
                        fontSize: AppConstants.fontSubtitle,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ActionIcon(icon: Icons.share_outlined, onTap: onShare),
                        SizedBox(width: AppConstants.actionIconSpacing),
                        _ActionIcon(icon: Icons.delete_outline, onTap: onDelete),
                        SizedBox(width: AppConstants.actionIconSpacing),
                        _ActionIcon(icon: Icons.photo_library_outlined, onTap: onExport),
                        SizedBox(width: AppConstants.actionIconSpacing),
                        _ActionIcon(icon: Icons.more_vert, onTap: onMore),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final path = document.thumbnailPath;
    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _pdfIcon());
    }
    return _pdfIcon();
  }

  Widget _pdfIcon() {
    return const Center(child: Icon(Icons.picture_as_pdf, size: 32, color: Colors.grey));
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.actionIconSize),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.actionIconPadding),
        child: Icon(icon, size: AppConstants.actionIconSize, color: AppColors.iconAction),
      ),
    );
  }
}
