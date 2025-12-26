import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class MediaMessageWidget extends StatelessWidget {
  final MessageMedia media;
  final bool isSentByMe;
  final VoidCallback? onTap;

  const MediaMessageWidget({
    super.key,
    required this.media,
    this.isSentByMe = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (media.type) {
      case 'image':
        return _buildImageMessage(context, colorScheme);
      case 'video':
        return _buildVideoMessage(context, colorScheme);
      case 'audio':
        return _buildAudioMessage(context, colorScheme);
      case 'document':
        return _buildDocumentMessage(context, colorScheme);
      case 'location':
        return _buildLocationMessage(context, colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageMessage(BuildContext context, ColorScheme colorScheme) {
    final imageUrl = media.thumbnail ?? media.url;
    
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CachedImageWidget(
            imageUrl: imageUrl,
            width: 250,
            height: 250,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
            placeholderColor: colorScheme.surfaceVariant,
            errorWidget: Container(
              width: 250,
              height: 250,
              color: colorScheme.surfaceVariant,
              child: Icon(
                Icons.broken_image,
                color: colorScheme.error,
                size: 48,
              ),
            ),
          ),
          if (media.fileName != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Text(
                  media.fileName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoMessage(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (media.thumbnail != null)
              CachedImageWidget(
                imageUrl: media.thumbnail,
                width: 250,
                height: 200,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
              ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
            if (media.fileName != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  media.fileName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMessage(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.audiotrack,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  media.fileName ?? 'Audio Message',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (media.fileSize != null)
                  Text(
                    _formatFileSize(media.fileSize!),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.play_arrow, color: colorScheme.primary),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentMessage(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getDocumentIcon(media.fileName),
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    media.fileName ?? 'Document',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (media.fileSize != null)
                    Text(
                      _formatFileSize(media.fileSize!),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context, ColorScheme colorScheme) {
    if (media.location == null) {
      return const SizedBox.shrink();
    }

    final location = media.location!;
    
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.placeName ?? location.address ?? 'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (location.address != null && location.placeName != null) ...[
              const SizedBox(height: 4),
              Text(
                location.address!,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.map,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;
    
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
