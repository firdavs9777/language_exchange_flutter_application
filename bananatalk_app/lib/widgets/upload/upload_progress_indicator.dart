import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/upload_task.dart';
import '../../providers/upload_manager_provider.dart';

/// Floating upload progress indicator
/// Shows a compact pill when uploading, expandable to show all tasks
class UploadProgressIndicator extends ConsumerStatefulWidget {
  const UploadProgressIndicator({Key? key}) : super(key: key);

  @override
  ConsumerState<UploadProgressIndicator> createState() =>
      _UploadProgressIndicatorState();
}

class _UploadProgressIndicatorState
    extends ConsumerState<UploadProgressIndicator>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadManagerProvider);

    // Only show if there are active or recent tasks
    if (uploadState.activeTasks.isEmpty &&
        uploadState.failedTasks.isEmpty) {
      if (_animationController.isCompleted) {
        _animationController.reverse();
      }
      return const SizedBox.shrink();
    }

    // Show the indicator
    if (!_animationController.isAnimating &&
        _animationController.status == AnimationStatus.dismissed) {
      _animationController.forward();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: _isExpanded
          ? _buildExpandedView(uploadState)
          : _buildCompactView(uploadState),
    );
  }

  Widget _buildCompactView(UploadManagerState state) {
    final activeTask = state.currentTask ?? state.activeTasks.firstOrNull;
    final progress = activeTask?.progress ?? 0.0;
    final activeCount = state.activeTasks.length;
    final failedCount = state.failedTasks.length;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: failedCount > 0 ? Colors.red.shade600 : Colors.blue.shade600,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (failedCount > 0) ...[
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '$failedCount failed',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activeCount == 1
                    ? 'Uploading ${(progress * 100).toInt()}%'
                    : '$activeCount uploads',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(UploadManagerState state) {
    return Container(
      width: 300,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Uploads',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.expand_less, size: 20),
                  onPressed: () => setState(() => _isExpanded = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Task list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Active tasks
                ...state.activeTasks.map((task) => _buildTaskItem(task)),
                // Failed tasks
                ...state.failedTasks.map((task) => _buildTaskItem(task)),
              ],
            ),
          ),

          // Footer with actions
          if (state.failedTasks.isNotEmpty || state.completedTasks.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state.failedTasks.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        final notifier = ref.read(uploadManagerProvider.notifier);
                        for (final task in state.failedTasks) {
                          notifier.retryUpload(task.id);
                        }
                      },
                      child: const Text('Retry All'),
                    ),
                  if (state.completedTasks.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(uploadManagerProvider.notifier).clearCompleted();
                      },
                      child: const Text('Clear Completed'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(UploadTask task) {
    final notifier = ref.read(uploadManagerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Status icon
          _buildStatusIcon(task),
          const SizedBox(width: 12),

          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.typeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.statusText,
                  style: TextStyle(
                    color: task.status == UploadStatus.failed
                        ? Colors.red
                        : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                // Progress bar for uploading tasks
                if (task.status == UploadStatus.uploading) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (task.status == UploadStatus.failed)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => notifier.retryUpload(task.id),
              tooltip: 'Retry',
            ),
          if (task.isActive)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => notifier.cancelUpload(task.id),
              tooltip: 'Cancel',
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(UploadTask task) {
    switch (task.status) {
      case UploadStatus.queued:
        return Icon(Icons.schedule, color: Colors.grey.shade600, size: 24);
      case UploadStatus.uploading:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: task.progress,
            strokeWidth: 2,
          ),
        );
      case UploadStatus.processing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case UploadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 24);
      case UploadStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 24);
      case UploadStatus.cancelled:
        return Icon(Icons.cancel, color: Colors.grey.shade600, size: 24);
    }
  }
}

/// Mini upload indicator for app bar or bottom nav
class MiniUploadIndicator extends ConsumerWidget {
  const MiniUploadIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveUploads = ref.watch(hasActiveUploadsProvider);
    final state = ref.watch(uploadManagerProvider);

    if (!hasActiveUploads && state.failedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final progress = state.overallProgress;
    final hasFailed = state.failedTasks.isNotEmpty;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: hasFailed ? Colors.red : Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!hasFailed)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: Colors.white.withOpacity(0.3),
              ),
            ),
          Icon(
            hasFailed ? Icons.error_outline : Icons.cloud_upload,
            color: Colors.white,
            size: 14,
          ),
        ],
      ),
    );
  }
}

/// Full screen upload queue view
class UploadQueueScreen extends ConsumerWidget {
  const UploadQueueScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadManagerProvider);
    final allTasks = [
      ...state.activeTasks,
      ...state.failedTasks,
      ...state.completedTasks,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Queue'),
        actions: [
          if (state.completedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                ref.read(uploadManagerProvider.notifier).clearCompleted();
              },
              tooltip: 'Clear Completed',
            ),
        ],
      ),
      body: allTasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_done, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No uploads',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: allTasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = allTasks[index];
                return _buildTaskTile(context, ref, task);
              },
            ),
    );
  }

  Widget _buildTaskTile(BuildContext context, WidgetRef ref, UploadTask task) {
    final notifier = ref.read(uploadManagerProvider.notifier);

    return ListTile(
      leading: _buildStatusAvatar(task),
      title: Text(task.typeName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.statusText),
          if (task.status == UploadStatus.uploading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(
                value: task.progress,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (task.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                task.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.status == UploadStatus.failed)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.retryUpload(task.id),
            ),
          if (task.isActive)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => notifier.cancelUpload(task.id),
            ),
          if (!task.isActive)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => notifier.removeTask(task.id),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusAvatar(UploadTask task) {
    Color bgColor;
    IconData icon;

    switch (task.status) {
      case UploadStatus.queued:
        bgColor = Colors.grey;
        icon = Icons.schedule;
        break;
      case UploadStatus.uploading:
      case UploadStatus.processing:
        bgColor = Colors.blue;
        icon = Icons.cloud_upload;
        break;
      case UploadStatus.completed:
        bgColor = Colors.green;
        icon = Icons.check;
        break;
      case UploadStatus.failed:
        bgColor = Colors.red;
        icon = Icons.error;
        break;
      case UploadStatus.cancelled:
        bgColor = Colors.grey;
        icon = Icons.cancel;
        break;
    }

    return CircleAvatar(
      backgroundColor: bgColor,
      child: task.status == UploadStatus.uploading ||
              task.status == UploadStatus.processing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: task.status == UploadStatus.uploading
                    ? task.progress
                    : null,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, color: Colors.white),
    );
  }
}
