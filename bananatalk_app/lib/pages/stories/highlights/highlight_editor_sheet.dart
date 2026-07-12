import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// Bottom sheet for creating, renaming, and deleting a story highlight, and
/// (from the story viewer) picking an existing highlight — or creating a new
/// one — to add a story to.
///
/// Three entry points, each with its own static `show*` helper:
///  * [showCreate] — title field only, used from the highlights row's
///    leading "+ New" circle.
///  * [showEdit] — rename / delete an existing highlight, used on long-press
///    of an own-profile highlight circle.
///  * [showPicker] — lists existing highlights plus a "New highlight" row,
///    used from the story viewer's own-story "Add to highlight" action.
class HighlightEditorSheet {
  HighlightEditorSheet._();

  /// Shows the create sheet. Returns the created [StoryHighlight] on
  /// success, or null if cancelled/failed.
  static Future<StoryHighlight?> showCreate(
    BuildContext context, {
    String? storyId,
  }) {
    return showModalBottomSheet<StoryHighlight?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreateHighlightSheet(storyId: storyId),
    );
  }

  /// Shows the rename/delete sheet for an existing highlight. Returns
  /// `'deleted'`, `'renamed'`, or null (no change / cancelled).
  static Future<String?> showEdit(
    BuildContext context, {
    required StoryHighlight highlight,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditHighlightSheet(highlight: highlight),
    );
  }

  /// Shows a picker: existing highlights (tap to add [storyId] to it) plus a
  /// "New highlight" row that opens [showCreate]. Returns true if the story
  /// ended up added to a highlight (existing or newly created).
  static Future<bool> showPicker(
    BuildContext context, {
    required String storyId,
    required List<StoryHighlight> existingHighlights,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _HighlightPickerSheet(
        storyId: storyId,
        existingHighlights: existingHighlights,
      ),
    );
    return result ?? false;
  }
}

// ---------------------------------------------------------------------------
// Create
// ---------------------------------------------------------------------------

class _CreateHighlightSheet extends StatefulWidget {
  final String? storyId;
  const _CreateHighlightSheet({this.storyId});

  @override
  State<_CreateHighlightSheet> createState() => _CreateHighlightSheetState();
}

class _CreateHighlightSheetState extends State<_CreateHighlightSheet> {
  final _controller = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final result = await StoriesService.createHighlight(
        title: title,
        storyId: widget.storyId,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.pop(context, result['data'] as StoryHighlight?);
      } else {
        setState(() {
          _isSaving = false;
          _error = 'Failed to create highlight';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              const SizedBox(height: 12),
              Text(
                l10n.newHighlight,
                style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.highlightName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: context.bodySmall.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.createHighlight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit (rename / delete)
// ---------------------------------------------------------------------------

class _EditHighlightSheet extends StatefulWidget {
  final StoryHighlight highlight;
  const _EditHighlightSheet({required this.highlight});

  @override
  State<_EditHighlightSheet> createState() => _EditHighlightSheetState();
}

class _EditHighlightSheetState extends State<_EditHighlightSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.highlight.title);
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _rename() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final result = await StoriesService.updateHighlight(
        highlightId: widget.highlight.id,
        title: title,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.pop(context, 'renamed');
      } else {
        setState(() {
          _isSaving = false;
          _error = 'Failed to rename highlight';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLG),
        title: Text(
          l10n.deleteHighlightTitle,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.deleteHighlightConfirm(widget.highlight.title),
          style: context.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: context.labelLarge.copyWith(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              l10n.delete,
              style: context.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final result = await StoriesService.deleteHighlight(
        highlightId: widget.highlight.id,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.pop(context, 'deleted');
      } else {
        setState(() {
          _isSaving = false;
          _error = 'Failed to delete highlight';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              const SizedBox(height: 12),
              Text(
                l10n.editHighlight,
                style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.highlightName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _rename(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: context.bodySmall.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.deleteHighlight),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _rename,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Picker (used from the story viewer's "Add to highlight" action)
// ---------------------------------------------------------------------------

class _HighlightPickerSheet extends StatefulWidget {
  final String storyId;
  final List<StoryHighlight> existingHighlights;

  const _HighlightPickerSheet({
    required this.storyId,
    required this.existingHighlights,
  });

  @override
  State<_HighlightPickerSheet> createState() => _HighlightPickerSheetState();
}

class _HighlightPickerSheetState extends State<_HighlightPickerSheet> {
  bool _isBusy = false;

  Future<void> _addToExisting(StoryHighlight highlight) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await StoriesService.addToHighlight(
        highlightId: highlight.id,
        storyId: widget.storyId,
      );
      if (!mounted) return;
      Navigator.pop(context, result['success'] == true);
    } catch (_) {
      if (mounted) Navigator.pop(context, false);
    }
  }

  Future<void> _createNew() async {
    if (_isBusy) return;
    final created = await HighlightEditorSheet.showCreate(
      context,
      storyId: widget.storyId,
    );
    if (!mounted) return;
    Navigator.pop(context, created != null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.addToHighlight,
                style: context.titleLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (widget.existingHighlights.isNotEmpty) ...[
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: widget.existingHighlights.map((h) {
                    final alreadyIn = h.stories.any((s) => s.id == widget.storyId);
                    return ListTile(
                      leading: _HighlightThumb(highlight: h),
                      title: Text(h.title),
                      subtitle: Text('${h.storyCount} stories'),
                      trailing: alreadyIn
                          ? Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: (alreadyIn || _isBusy)
                          ? null
                          : () => _addToExisting(h),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
              title: Text(l10n.newHighlight),
              onTap: _isBusy ? null : _createNew,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _HighlightThumb extends StatelessWidget {
  final StoryHighlight highlight;
  const _HighlightThumb({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final coverUrl = highlight.coverImage?.isNotEmpty == true
        ? highlight.coverImage
        : (highlight.stories.isNotEmpty
            ? highlight.stories.first.thumbnail
            : null);

    return CircleAvatar(
      radius: 24,
      backgroundColor: context.dividerColor,
      child: coverUrl != null && coverUrl.isNotEmpty
          ? ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CachedImageWidget(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  errorWidget: Icon(
                    Icons.auto_stories,
                    size: 20,
                    color: context.textMuted,
                  ),
                ),
              ),
            )
          : Icon(Icons.auto_stories, size: 20, color: context.textMuted),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
