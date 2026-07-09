import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/report_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Displays a list of evidence files from a report in a grid layout.
/// Handles both image and text files, rendering appropriate UI for each type.
/// Returns empty widget if no evidence is provided.
class ReportEvidenceSection extends StatelessWidget {
  final List<EvidenceFile> evidence;

  const ReportEvidenceSection({
    Key? key,
    required this.evidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (evidence.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidence',
          style: context.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: evidence.length,
          itemBuilder: (context, index) => EvidenceFileView(
            file: evidence[index],
          ),
        ),
      ],
    );
  }
}

/// Displays a single evidence file, routing to appropriate view based on file type.
/// Images render as thumbnails with fullscreen zoom capability.
/// Text files render with expandable preview.
class EvidenceFileView extends StatelessWidget {
  final EvidenceFile file;

  const EvidenceFileView({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (file.type == 'image') {
      return _ImageEvidenceView(file: file);
    } else {
      return _TextEvidenceView(file: file);
    }
  }
}

/// Displays an image evidence file as a thumbnail with tap-to-zoom fullscreen capability.
class _ImageEvidenceView extends StatefulWidget {
  final EvidenceFile file;

  const _ImageEvidenceView({
    required this.file,
  });

  @override
  State<_ImageEvidenceView> createState() => _ImageEvidenceViewState();
}

class _ImageEvidenceViewState extends State<_ImageEvidenceView> {
  late ImageProvider _imageProvider;
  ImageProvider? _loadedProvider;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _imageProvider = NetworkImage(widget.file.url);
    _precacheImage();
  }

  /// Pre-loads image into memory cache for smooth display and error detection.
  void _precacheImage() async {
    try {
      await precacheImage(_imageProvider, context);
      if (mounted) {
        setState(() => _loadedProvider = _imageProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  /// Opens fullscreen image view with interactive zoom and pan.
  void _showFullscreenImage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog.fullscreen(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1,
            maxScale: 3,
            child: Center(
              child: Image(
                image: _imageProvider,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loadedProvider != null ? () => _showFullscreenImage(context) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderMD,
          border: Border.all(color: context.dividerColor),
          color: context.cardBackground,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: context.textHint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image failed',
                      style: context.caption.copyWith(
                        color: context.textHint,
                      ),
                    ),
                  ],
                ),
              )
            else if (_loadedProvider != null)
              ClipRRect(
                borderRadius: AppRadius.borderMD,
                child: Image(
                  image: _loadedProvider!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.file.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a text evidence file with expandable preview.
/// Shows first 3 lines by default, with "Show more" button to expand full content.
class _TextEvidenceView extends StatefulWidget {
  final EvidenceFile file;

  const _TextEvidenceView({
    required this.file,
  });

  @override
  State<_TextEvidenceView> createState() => _TextEvidenceViewState();
}

class _TextEvidenceViewState extends State<_TextEvidenceView> {
  late Future<String> _textFuture;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _textFuture = _fetchText();
  }

  /// Fetches text content from the evidence file URL.
  /// TODO: Implement actual HTTP fetch once backend text-file endpoint is available.
  Future<String> _fetchText() async {
    try {
      // Placeholder for actual text file fetch.
      // In production, this would make an HTTP GET request to fetch file content
      // from the backend storage URL.
      return 'Text file content would be loaded here.';
    } catch (e) {
      return 'Failed to load text file.';
    }
  }

  /// Formats file size in human-readable format.
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Formats date in readable format (MMM dd, yyyy).
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
        color: context.cardBackground,
      ),
      padding: Spacing.paddingSM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File header with icon and filename
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.file.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Text content with expandable preview
          Expanded(
            child: FutureBuilder<String>(
              future: _textFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading file',
                      style: context.caption.copyWith(
                        color: context.textHint,
                      ),
                    ),
                  );
                }

                final text = snapshot.data ?? '';
                final lines = text.split('\n');
                final isLong = lines.length > 3;
                final displayText = _isExpanded
                    ? text
                    : lines.take(3).join('\n');

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: context.caption,
                        maxLines: _isExpanded ? null : 3,
                        overflow: _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      if (isLong && !_isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _isExpanded = true),
                            child: Text(
                              'Show more',
                              style: context.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // File metadata footer
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatFileSize(widget.file.size),
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                ),
              ),
              Text(
                _formatDate(widget.file.uploadedAt),
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
