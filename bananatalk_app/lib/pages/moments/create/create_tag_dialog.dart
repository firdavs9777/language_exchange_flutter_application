import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/widgets/moments_snackbar.dart';
import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:bananatalk_app/utils/hashtag_text.dart';

const String _kRecentTagsKey = 'recent_moment_tags';
const int _kMaxRecentTags = 10;

Future<List<String>> loadRecentMomentTags() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_kRecentTagsKey) ?? <String>[];
}

Future<void> persistRecentMomentTag(String tag) async {
  if (tag.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getStringList(_kRecentTagsKey) ?? <String>[];
  current.remove(tag);
  current.insert(0, tag);
  if (current.length > _kMaxRecentTags) {
    current.removeRange(_kMaxRecentTags, current.length);
  }
  await prefs.setStringList(_kRecentTagsKey, current);
}

/// The tags to offer as chips under the caption: the last three distinct
/// hashtags written in [caption] that are not in [existing] (compared
/// case-insensitively), in caption order. Pure; no network.
List<String> suggestedTagsFromCaption(String caption, List<String> existing) {
  final taken = <String>{
    for (final t in existing) normalizeHashtag(t) ?? t.toLowerCase(),
  };
  final found = <String>[];
  for (final span in splitHashtags(caption)) {
    final raw = span.tag;
    if (!span.isHashtag || raw == null) continue;
    final tag = normalizeHashtag(raw);
    if (tag == null || taken.contains(tag)) continue;
    taken.add(tag);
    found.add(tag);
  }
  return found.length <= 3 ? found : found.sublist(found.length - 3);
}

/// Shows a dialog that lets the user add and remove tags for a moment.
///
/// Returns the updated tag list (may be unchanged if the user only closed the
/// dialog without modifying anything), or `null` if the dialog was dismissed
/// unexpectedly.
///
/// The dialog is self-contained: it owns a local copy of [existingTags] and a
/// [TextEditingController] for the input field, so the caller only has to
/// propagate the returned list back into its own state.
///
/// When [suggest] is given (hashtags on), what the user types is looked up
/// through it, debounced, and the matches show above the recent tags. A
/// failing lookup shows nothing.
Future<List<String>> showCreateTagDialog(
  BuildContext context, {
  required List<String> existingTags,
  int maxTags = 5,
  Future<List<HashtagCount>> Function(String query)? suggest,
}) async {
  final result = await showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => _CreateTagDialog(
      existingTags: existingTags,
      maxTags: maxTags,
      suggest: suggest,
    ),
  );

  // If dialog was dismissed without tapping Done, return existing tags unchanged.
  return result ?? existingTags;
}

/// The dialog's own state (a local copy of the tags, the input controller and
/// the suggestion lookup), disposed with the route so nothing is used while
/// the dialog is still animating out.
class _CreateTagDialog extends StatefulWidget {
  const _CreateTagDialog({
    required this.existingTags,
    required this.maxTags,
    required this.suggest,
  });

  final List<String> existingTags;
  final int maxTags;
  final Future<List<HashtagCount>> Function(String query)? suggest;

  @override
  State<_CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<_CreateTagDialog> {
  late final List<String> workingTags = List<String>.from(widget.existingTags);
  final controller = TextEditingController();
  Timer? suggestTimer;
  int suggestGeneration = 0;
  List<HashtagCount> suggestions = <HashtagCount>[];

  @override
  void dispose() {
    suggestTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext dialogContext) {
    final suggest = widget.suggest;
    final maxTags = widget.maxTags;
    void setDialogState(VoidCallback fn) => setState(fn);
    final l10n = AppLocalizations.of(dialogContext)!;
    final theme = Theme.of(dialogContext);

    void addTag([String? tagOverride]) {
      final tag = tagOverride ?? controller.text.trim();
      if (tag.isEmpty) return;
      if (workingTags.contains(tag)) {
        if (tagOverride == null) controller.clear();
        return;
      }
      if (workingTags.length >= maxTags) {
        showMomentsSnackBar(dialogContext, message: l10n.maxTagsAllowed);
        return;
      }
      setDialogState(() {
        workingTags.add(tag);
        if (tagOverride == null) controller.clear();
      });
      persistRecentMomentTag(tag);
    }

    void onTyped(String text) {
      if (suggest == null) return;
      suggestTimer?.cancel();
      final generation = ++suggestGeneration;
      final tag = normalizeHashtag(text);
      if (tag == null) {
        if (suggestions.isNotEmpty) {
          setDialogState(() => suggestions = <HashtagCount>[]);
        }
        return;
      }
      suggestTimer = Timer(const Duration(milliseconds: 250), () async {
        List<HashtagCount> found;
        try {
          found = await suggest(tag);
        } catch (_) {
          found = <HashtagCount>[];
        }
        // Closed, or a newer keystroke is the one to answer.
        if (!mounted || generation != suggestGeneration) return;
        setDialogState(() => suggestions = found);
      });
    }

    final shownSuggestions = suggestions
        .where(
          (s) => !workingTags.any(
            (t) => (normalizeHashtag(t) ?? t) == s.tag.toLowerCase(),
          ),
        )
        .take(8)
        .toList();

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.addTags,
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: l10n.enterTag,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: onTyped,
            onSubmitted: (_) => addTag(),
          ),
          const SizedBox(height: 12),
          if (workingTags.isNotEmpty)
            Wrap(
              spacing: 8,
              children: workingTags.map((tag) {
                return Chip(
                  label: Text(
                    '#$tag',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  onDeleted: () {
                    setDialogState(() => workingTags.remove(tag));
                  },
                );
              }).toList(),
            ),
          if (shownSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: shownSuggestions.map((s) {
                  return ActionChip(
                    label: Text('#${s.tag}'),
                    onPressed: () => addTag(s.tag),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FutureBuilder<List<String>>(
            future: loadRecentMomentTags(),
            builder: (ctx, snapshot) {
              final recent = snapshot.data ?? <String>[];
              final suggestable = recent
                  .where((t) => !workingTags.contains(t))
                  .take(8)
                  .toList();
              if (suggestable.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.noRecentTags,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.recentTags, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: suggestable.map((tag) {
                      return ActionChip(
                        label: Text('#$tag'),
                        onPressed: () => addTag(tag),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, workingTags),
          child: Text(
            l10n.done,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            addTag();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
