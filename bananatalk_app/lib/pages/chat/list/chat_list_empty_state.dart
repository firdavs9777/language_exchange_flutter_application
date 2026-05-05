import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_empty_state.dart';
import 'package:flutter/material.dart';

/// Chat-list-specific empty states.
///
/// Two variants are exposed:
///  - [ChatListEmptyState.noResults] — shown when a search query returns nothing.
///  - [ChatListEmptyState.noChats]   — shown when the chat list itself is empty.
///
/// Both delegate rendering to the shared [ChatEmptyState] widget.
class ChatListEmptyState extends StatelessWidget {
  final bool isSearchEmpty;
  final String searchQuery;
  final VoidCallback? onFindUser;

  const ChatListEmptyState.noResults({
    super.key,
    required this.searchQuery,
    this.onFindUser,
  }) : isSearchEmpty = true;

  const ChatListEmptyState.noChats({super.key})
      : isSearchEmpty = false,
        searchQuery = '',
        onFindUser = null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    if (isSearchEmpty) {
      final isUsernameSearch = searchQuery.trim().startsWith('@');
      final searchTerm = isUsernameSearch
          ? searchQuery.trim().substring(1)
          : searchQuery.trim();

      return ChatEmptyState(
        icon: Icons.search_off,
        title: l10n.noResultsFound,
        body: isUsernameSearch
            ? 'User @$searchTerm not in your chats'
            : l10n.tryDifferentSearch,
        cta: isUsernameSearch && searchTerm.isNotEmpty && onFindUser != null
            ? ElevatedButton.icon(
                onPressed: onFindUser,
                icon: const Icon(Icons.person_search, size: 20),
                label: Text('Find @$searchTerm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
            : null,
      );
    }

    return ChatEmptyState(
      icon: Icons.chat_bubble_outline,
      title: l10n.chats,
      body: l10n.searchConversations,
    );
  }
}
