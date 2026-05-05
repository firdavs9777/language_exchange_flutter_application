import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Top search bar for the chat list — text field + clear button.
/// State (controller, focus node, query) is owned by the parent; this
/// widget is purely presentational.
class ChatListSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ChatListSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = context.textMuted;

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: 'Search or type @username',
          hintStyle: TextStyle(color: mutedText, fontSize: 16),
          prefixIcon: Icon(Icons.search, color: mutedText, size: 22),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: mutedText, size: 20),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(fontSize: 16),
        onChanged: onChanged,
      ),
    );
  }
}
