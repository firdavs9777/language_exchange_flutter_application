import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/services/giphy_service.dart';
import 'sticker_button.dart';

class ChatStickerPanel extends ConsumerStatefulWidget {
  final AnimationController animationController;
  final Function(String) onSendSticker;
  final Function(String gifUrl)? onSendGif;

  // Organized stickers by categories
  static const Map<String, List<String>> _stickerCategories = {
    'Smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
      '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
      '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜',
    ],
    'Emotions': [
      '🤪', '🤨', '🧐', '🤓', '😎', '🥸', '🤩', '🥳',
      '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️',
      '😤', '😠', '😡', '🤬', '🥺', '😢', '😭', '😱',
    ],
    'Hand Gestures': [
      '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙',
      '👈', '👉', '👆', '🖕', '👇', '☝️', '👋', '🤚',
      '🖐️', '✋', '🖖', '👏', '🙌', '🤝', '🙏', '✍️',
    ],
    'Hearts': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
      '💘', '💝', '💟', '♥️', '💌', '💋', '💍', '💎',
    ],
  };

  const ChatStickerPanel({
    Key? key,
    required this.animationController,
    required this.onSendSticker,
    this.onSendGif,
  }) : super(key: key);

  static String _localizedCategory(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Smileys': return l10n.smileys;
      case 'Emotions': return l10n.emotions;
      case 'Hand Gestures': return l10n.handGestures;
      case 'Hearts': return l10n.hearts;
      default: return key;
    }
  }

  @override
  ConsumerState<ChatStickerPanel> createState() => _ChatStickerPanelState();
}

class _ChatStickerPanelState extends ConsumerState<ChatStickerPanel> {
  List<GiphyGif> _gifs = [];
  bool _isLoadingGifs = false;
  final TextEditingController _gifSearchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadTrendingGifs();
  }

  @override
  void dispose() {
    _gifSearchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrendingGifs() async {
    setState(() => _isLoadingGifs = true);
    try {
      final service = ref.read(giphyServiceProvider);
      final gifs = await service.getTrendingGifs(limit: 20);
      if (mounted) {
        setState(() {
          _gifs = gifs;
          _isLoadingGifs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGifs = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      _loadTrendingGifs();
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchGifs(query.trim());
    });
  }

  Future<void> _searchGifs(String query) async {
    setState(() => _isLoadingGifs = true);
    try {
      final service = ref.read(giphyServiceProvider);
      final gifs = await service.searchGifs(query, limit: 20);
      if (mounted) {
        setState(() {
          _gifs = gifs;
          _isLoadingGifs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGifs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Total tabs: GIF + sticker categories
    final tabCount = 1 + ChatStickerPanel._stickerCategories.length;

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Container(
          height: 280 * widget.animationController.value,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              top: BorderSide(
                color: context.dividerColor,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Opacity(
            opacity: widget.animationController.value.clamp(0.0, 1.0),
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: 280,
              child: DefaultTabController(
              length: tabCount,
              child: Column(
                children: [
                  // Tab bar
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TabBar(
                      isScrollable: true,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: context.textSecondary,
                      indicatorColor: Theme.of(context).primaryColor,
                      indicatorWeight: 2,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(text: AppLocalizations.of(context)!.gif),
                        ...ChatStickerPanel._stickerCategories.keys.map((category) {
                          return Tab(text: ChatStickerPanel._localizedCategory(context, category));
                        }),
                      ],
                    ),
                  ),

                  // Tab views
                  Expanded(
                    child: TabBarView(
                      children: [
                        // GIF tab
                        _buildGifGrid(),
                        // Sticker tabs
                        ...ChatStickerPanel._stickerCategories.values.map((stickers) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: stickers.length,
                              itemBuilder: (context, index) {
                                return StickerButton(
                                  sticker: stickers[index],
                                  onTap: () => widget.onSendSticker(stickers[index]),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGifGrid() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _gifSearchController,
              onChanged: _onSearchChanged,
              style: TextStyle(fontSize: 14, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchGifs,
                hintStyle: TextStyle(fontSize: 13, color: context.textHint),
                prefixIcon: Icon(Icons.search, size: 18, color: context.textSecondary),
                suffixIcon: _gifSearchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _gifSearchController.clear();
                          _loadTrendingGifs();
                        },
                        child: Icon(Icons.close, size: 16, color: context.textSecondary),
                      )
                    : null,
                filled: true,
                fillColor: context.containerColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        // GIF grid
        Expanded(
          child: _isLoadingGifs
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _gifs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gif_box_rounded, size: 32, color: context.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.noGifsFound,
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GridView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _gifs.length,
                        itemBuilder: (context, index) {
                          final gif = _gifs[index];
                          return GestureDetector(
                            onTap: () {
                              if (widget.onSendGif != null) {
                                widget.onSendGif!(gif.originalUrl);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: gif.previewUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: context.containerColor,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: context.containerColor,
                                  child: Icon(Icons.broken_image_rounded, size: 20, color: context.textSecondary),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
