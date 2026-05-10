import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/widgets/moments_snackbar.dart';

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
/// Foundation for C16 tag-autocomplete: replace the plain [TextField] below
/// with an autocomplete widget without touching the caller.
Future<List<String>> showCreateTagDialog(
  BuildContext context, {
  required List<String> existingTags,
  int maxTags = 5,
}) async {
  // Work on a local mutable copy so the dialog is self-contained.
  final workingTags = List<String>.from(existingTags);
  final controller = TextEditingController();

  final result = await showDialog<List<String>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final l10n = AppLocalizations.of(dialogContext)!;
          final theme = Theme.of(dialogContext);

          void addTag() {
            final tag = controller.text.trim();
            if (tag.isEmpty) return;
            if (workingTags.contains(tag)) {
              controller.clear();
              return;
            }
            if (workingTags.length >= maxTags) {
              showMomentsSnackBar(
                dialogContext,
                message: l10n.maxTagsAllowed,
              );
              return;
            }
            setDialogState(() {
              workingTags.add(tag);
              controller.clear();
            });
          }

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
        },
      );
    },
  );

  controller.dispose();

  // If dialog was dismissed without tapping Done, return existing tags unchanged.
  return result ?? existingTags;
}
