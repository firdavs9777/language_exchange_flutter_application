import 'dart:io';
import 'package:flutter/material.dart';

/// Dialog to preview and confirm image or video before sending
class ImagePreviewDialog extends StatefulWidget {
  final File imageFile;
  final String? initialCaption;
  final Function(String? caption) onSend;

  const ImagePreviewDialog({
    Key? key,
    required this.imageFile,
    this.initialCaption,
    required this.onSend,
  }) : super(key: key);

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();

  static Future<void> show({
    required BuildContext context,
    required File imageFile,
    String? initialCaption,
    required Function(String? caption) onSend,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImagePreviewDialog(
        imageFile: imageFile,
        initialCaption: initialCaption,
        onSend: onSend,
      ),
    );
  }
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  final TextEditingController _captionController = TextEditingController();
  bool _isSending = false;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCaption != null) {
      _captionController.text = widget.initialCaption!;
    }
    // Check if file is a video
    final path = widget.imageFile.path.toLowerCase();
    _isVideo = path.endsWith('.mp4') || 
                path.endsWith('.mov') || 
                path.endsWith('.avi') || 
                path.endsWith('.mkv') ||
                path.contains('video') ||
                path.contains('.mov');
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_isSending) return;

    setState(() => _isSending = true);
    
    final caption = _captionController.text.trim();
    widget.onSend(caption.isEmpty ? null : caption);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.black,
        child: Stack(
          children: [
            // Media preview (image or video)
            Positioned.fill(
              child: _isVideo
                  ? _buildVideoPreview()
                  : InteractiveViewer(
                      child: Center(
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // If image fails to load, it might be a video
                            return _buildVideoPreview();
                          },
                        ),
                      ),
                    ),
            ),

            // Top bar with close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    'Preview',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),

            // Bottom bar with caption and send button
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        enabled: !_isSending,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _handleSend,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video thumbnail placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  color: Colors.white70,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Video File',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.imageFile.path.split('/').last,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Play button overlay
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

