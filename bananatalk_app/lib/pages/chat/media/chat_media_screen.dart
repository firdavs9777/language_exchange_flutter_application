import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_empty_state.dart';

/// Screen showing all media, links, and documents shared in a conversation
class ChatMediaScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? senderId;
  final String? receiverId;
  final String otherUserName;

  const ChatMediaScreen({
    Key? key,
    this.conversationId,
    this.senderId,
    this.receiverId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  ConsumerState<ChatMediaScreen> createState() => _ChatMediaScreenState();
}

class _ChatMediaScreenState extends ConsumerState<ChatMediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Message> _allMessages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (widget.senderId == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    try {
      final messageService = ref.read(messageServiceProvider);
      final messages = await messageService.getUserMessages(id: widget.senderId);
      
      // Filter to only messages in this conversation
      final conversationMessages = messages.where((msg) {
        return (msg.sender.id == widget.senderId && msg.receiver.id == widget.receiverId) ||
               (msg.sender.id == widget.receiverId && msg.receiver.id == widget.senderId);
      }).toList();

      if (mounted) {
        setState(() {
          _allMessages = conversationMessages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<Message> get _mediaMessages {
    return _allMessages.where((msg) {
      if (msg.media == null) return false;
      final type = msg.media!.type.toLowerCase();
      return type == 'image' || type == 'video';
    }).toList();
  }

  List<Message> get _linkMessages {
    return _allMessages.where((msg) {
      final text = msg.message ?? '';
      return text.contains('http://') || text.contains('https://');
    }).toList();
  }

  List<Message> get _documentMessages {
    return _allMessages.where((msg) {
      if (msg.media == null) return false;
      final type = msg.media!.type.toLowerCase();
      return type == 'document' || type == 'audio' || type == 'file';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media with ${widget.otherUserName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.photo_library),
              text: 'Media (${_mediaMessages.length})',
            ),
            Tab(
              icon: const Icon(Icons.link),
              text: 'Links (${_linkMessages.length})',
            ),
            Tab(
              icon: const Icon(Icons.insert_drive_file),
              text: 'Docs (${_documentMessages.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: context.iconColor, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading media', style: TextStyle(color: context.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadMessages,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMediaTab(),
                    _buildLinksTab(),
                    _buildDocsTab(),
                  ],
                ),
    );
  }

  Widget _buildMediaTab() {
    if (_mediaMessages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        message: 'No photos or videos shared yet',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _mediaMessages.length,
      itemBuilder: (context, index) {
        final message = _mediaMessages[index];
        final media = message.media!;
        final isVideo = media.type.toLowerCase() == 'video';

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _openMedia(media);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: context.containerColor,
                child: CachedImageWidget(
                  imageUrl: media.thumbnail ?? media.url,
                  fit: BoxFit.cover,
                  errorWidget: _buildMediaPlaceholder(isVideo),
                ),
              ),
              if (isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: AppColors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinksTab() {
    if (_linkMessages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.link_off,
        message: 'No links shared yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _linkMessages.length,
      itemBuilder: (context, index) {
        final message = _linkMessages[index];
        final text = message.message ?? '';
        
        // Extract URL from text
        final urlRegex = RegExp(r'https?://[^\s]+');
        final match = urlRegex.firstMatch(text);
        final url = match?.group(0) ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link, color: Colors.blue),
            ),
            title: Text(
              url,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatDate(message.createdAt),
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
            onTap: () => _openUrl(url),
          ),
        );
      },
    );
  }

  Widget _buildDocsTab() {
    if (_documentMessages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_off,
        message: 'No documents shared yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documentMessages.length,
      itemBuilder: (context, index) {
        final message = _documentMessages[index];
        final media = message.media!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(media.mimeType),
                color: Colors.orange,
              ),
            ),
            title: Text(
              media.fileName ?? 'Document',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${_formatFileSize(media.fileSize)} • ${_formatDate(message.createdAt)}',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _openUrl(media.url),
            ),
            onTap: () => _openUrl(media.url),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return ChatEmptyState(icon: icon, title: message);
  }

  Widget _buildMediaPlaceholder(bool isVideo) {
    return Center(
      child: Icon(
        isVideo ? Icons.videocam : Icons.image,
        color: context.iconColor,
        size: 32,
      ),
    );
  }

  void _openMedia(MessageMedia media) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => _FullScreenMedia(media: media),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          showChatSnackBar(context, message: 'Cannot open: $url', type: ChatSnackBarType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        showChatSnackBar(context, message: 'Error opening link: $e', type: ChatSnackBarType.error);
      }
    }
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('audio')) return Icons.audio_file;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Icons.table_chart;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return Icons.slideshow;
    if (mimeType.contains('zip') || mimeType.contains('archive')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int? size) {
    if (size == null) return 'Unknown size';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String dateString) {
    try {
      final date = parseToKoreaTime(dateString);
      final now = getKoreaNow();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}

/// Full screen media viewer
class _FullScreenMedia extends StatelessWidget {
  final MessageMedia media;

  const _FullScreenMedia({required this.media});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.white),
            onPressed: () async {
              final uri = Uri.parse(media.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedImageWidget(
            imageUrl: media.url,
            fit: BoxFit.contain,
            placeholderColor: AppColors.black,
            errorWidget: const Center(
              child: Icon(Icons.broken_image, color: AppColors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}

