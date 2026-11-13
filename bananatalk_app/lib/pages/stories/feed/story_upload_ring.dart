import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/pages/stories/widgets/story_limit.dart';
import 'package:bananatalk_app/providers/upload_manager_provider.dart';
import 'package:bananatalk_app/services/story_upload_payload.dart';

/// The story task whose state the own ring shows: a failed one first (it
/// needs the user), else one that is waiting or sending. Completed and
/// cancelled tasks show nothing. A task queued by another account is never
/// shown (the queue drops those anyway; a task with no owner is treated as
/// the signed-in user's).
UploadTask? storyTaskForRing(List<UploadTask> tasks, String? userId) {
  // Until the signed-in user is known, show nothing (never "any owner").
  if (userId == null || userId.isEmpty) return null;
  UploadTask? active;
  for (final t in tasks) {
    if (!t.isStory) continue;
    final owner = t.metadata['ownerUserId'];
    if (owner != null && owner != userId) continue;
    if (t.status == UploadStatus.failed) return t;
    if (t.status == UploadStatus.queued ||
        t.status == UploadStatus.uploading ||
        t.status == UploadStatus.processing) {
      active ??= t;
    }
  }
  return active;
}

/// Whether the Retry button is offered: always, except when the private copy
/// of the media is gone (nothing can bring it back). The daily limit can be
/// retried tomorrow.
bool storyFailureRetryable(StoryUploadFailure? failure) =>
    failure != StoryUploadFailure.fileMissing;

/// The localized sentence for a failed story task's stable failure code.
String storyUploadFailureText(
    AppLocalizations l10n, StoryUploadFailure? failure) {
  switch (failure) {
    case StoryUploadFailure.limitReached:
      return l10n.limitDescStories;
    case StoryUploadFailure.fileMissing:
      return l10n.storyUploadFileMissing;
    case StoryUploadFailure.failed:
    case null:
      return l10n.storyUploadFailed;
  }
}

/// A small pill: a spinner and "posting" while the story is queued or
/// uploading; a warning and "Tap to retry" when it failed.
class StoryUploadChip extends StatelessWidget {
  const StoryUploadChip(
      {super.key,
      required this.failed,
      this.retryable = true,
      this.maxWidth});

  final bool failed;

  /// Failed and Retry will be offered: says "Tap to retry", else the plain
  /// failure label.
  final bool retryable;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = !failed
        ? l10n.storyUploading
        : retryable
            ? l10n.storyUploadRetry
            : l10n.storyUploadFailed;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Semantics(
        label: label,
        button: failed,
        excludeSemantics: true,
        child: Container(
          key: Key(failed ? 'story-upload-failed' : 'story-upload-progress'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: failed ? const Color(0xFFD32F2F) : Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (failed)
                  const Icon(Icons.warning_amber_rounded,
                      size: 11, color: Colors.white)
                else
                  const SizedBox(
                    width: 9,
                    height: 9,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                const SizedBox(width: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Goes inside the own ring's `Stack`. Only inserted by the rail when the
/// upload queue flag is on; it is the one place that subscribes to the queue.
/// Draws nothing when there is no story task for [userId].
class StoryUploadRing extends ConsumerWidget {
  const StoryUploadRing({super.key, this.userId, this.avatarSize = 64});

  final String? userId;
  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadManagerProvider);
    final task = storyTaskForRing(state.tasks, userId);
    if (task == null) return const SizedBox.shrink();
    final failed = task.status == UploadStatus.failed;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 8,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: failed ? () => _onFailedTap(context, ref, task) : null,
          child: StoryUploadChip(
            failed: failed,
            retryable: storyFailureRetryable(task.storyFailure),
            maxWidth: avatarSize,
          ),
        ),
      ),
    );
  }

  Future<void> _onFailedTap(
      BuildContext context, WidgetRef ref, UploadTask task) async {
    // The queue may have started another attempt since this was drawn.
    if (_failedTask(ref, task.id) == null) return;
    if (task.storyFailure == StoryUploadFailure.limitReached) {
      await showStoryLimitDialog(context);
      if (!context.mounted) return;
      if (_failedTask(ref, task.id) == null) return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _FailedSheet(taskId: task.id),
    );
  }
}

UploadTask? _failedTask(WidgetRef ref, String taskId) {
  for (final t in ref.read(uploadManagerProvider).tasks) {
    if (t.id == taskId) return t.status == UploadStatus.failed ? t : null;
  }
  return null;
}

/// Watches the task: when it is no longer failed (another attempt started,
/// or it was removed) the sheet closes instead of acting on a stale task.
class _FailedSheet extends ConsumerStatefulWidget {
  const _FailedSheet({required this.taskId});

  final String taskId;

  @override
  ConsumerState<_FailedSheet> createState() => _FailedSheetState();
}

class _FailedSheetState extends ConsumerState<_FailedSheet> {
  /// The sheet pops itself at most once, however often the queue notifies
  /// while it closes (a second pop would take the screen underneath).
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    final taskId = widget.taskId;
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(uploadManagerProvider.notifier);
    UploadTask? task;
    for (final t in ref.watch(uploadManagerProvider).tasks) {
      if (t.id == taskId && t.status == UploadStatus.failed) task = t;
    }
    if (task == null) {
      if (!_closing) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.maybePop(context);
        });
      }
      return const SizedBox.shrink();
    }
    final failure = task.storyFailure;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              storyUploadFailureText(l10n, failure),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Retrying cannot bring a deleted file back.
            if (storyFailureRetryable(failure))
              FilledButton(
                key: const Key('story-upload-retry'),
                onPressed: () {
                  Navigator.pop(context);
                  notifier.retryUpload(taskId);
                },
                child: Text(l10n.retry),
              ),
            TextButton(
              key: const Key('story-upload-remove'),
              onPressed: () {
                Navigator.pop(context);
                notifier.removeTask(taskId);
              },
              child: Text(l10n.storyUploadRemove),
            ),
          ],
        ),
      ),
    );
  }
}
