import 'package:flutter/material.dart';
import 'sticker_button.dart';

class ChatStickerPanel extends StatelessWidget {
  final AnimationController animationController;
  final Function(String) onSendSticker;

  // Organized stickers by categories
  static const Map<String, List<String>> _stickerCategories = {
    'Smileys': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
    ],
    'Emotions': [
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🥸',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🥺',
      '😢',
      '😭',
      '😱',
    ],
    'Hand Gestures': [
      '👍',
      '👎',
      '👌',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '🖕',
      '👇',
      '☝️',
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '👏',
      '🙌',
      '🤝',
      '🙏',
      '✍️',
    ],
    'Hearts': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '♥️',
      '💌',
      '💋',
      '💍',
      '💎',
    ],
  };

  const ChatStickerPanel({
    Key? key,
    required this.animationController,
    required this.onSendSticker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          height: 280 * animationController.value,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey[200]!,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Opacity(
            opacity: animationController.value,
            child: DefaultTabController(
              length: _stickerCategories.length,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tab bar
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TabBar(
                      isScrollable: true,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey[600],
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
                      tabs: _stickerCategories.keys.map((category) {
                        return Tab(text: category);
                      }).toList(),
                    ),
                  ),

                  // Sticker grids
                  Expanded(
                    child: TabBarView(
                      children: _stickerCategories.values.map((stickers) {
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
                                onTap: () => onSendSticker(stickers[index]),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
