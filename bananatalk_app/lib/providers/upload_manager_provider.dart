import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/upload_task.dart';
import '../services/upload_queue_service.dart';
import '../providers/provider_models/story_model.dart';

/// State class for upload manager
class UploadManagerState {
  final List<UploadTask> tasks;
  final bool isInitialized;
  final String? currentUploadId;

  const UploadManagerState({
    this.tasks = const [],
    this.isInitialized = false,
    this.currentUploadId,
  });

  UploadManagerState copyWith({
    List<UploadTask>? tasks,
    bool? isInitialized,
    String? currentUploadId,
  }) {
    return UploadManagerState(
      tasks: tasks ?? this.tasks,
      isInitialized: isInitialized ?? this.isInitialized,
      currentUploadId: currentUploadId ?? this.currentUploadId,
    );
  }

  /// Get active upload tasks
  List<UploadTask> get activeTasks =>
      tasks.where((t) => t.isActive).toList();

  /// Get failed tasks
  List<UploadTask> get failedTasks =>
      tasks.where((t) => t.status == UploadStatus.failed).toList();

  /// Get completed tasks
  List<UploadTask> get completedTasks =>
      tasks.where((t) => t.status == UploadStatus.completed).toList();

  /// Check if there are any active uploads
  bool get hasActiveUploads => activeTasks.isNotEmpty;

  /// Get the current uploading task
  UploadTask? get currentTask {
    if (currentUploadId == null) return null;
    try {
      return tasks.firstWhere((t) => t.id == currentUploadId);
    } catch (_) {
      return null;
    }
  }

  /// Get overall progress (0.0 - 1.0)
  double get overallProgress {
    if (activeTasks.isEmpty) return 0.0;
    final total = activeTasks.fold<double>(0, (sum, t) => sum + t.progress);
    return total / activeTasks.length;
  }
}

/// Upload manager notifier for Riverpod
class UploadManagerNotifier extends StateNotifier<UploadManagerState> {
  final UploadQueueService _uploadService;
  StreamSubscription<List<UploadTask>>? _tasksSubscription;
  StreamSubscription<UploadProgress>? _progressSubscription;

  UploadManagerNotifier(this._uploadService)
      : super(const UploadManagerState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize the upload service
    await _uploadService.initialize();

    // Listen to task changes
    _tasksSubscription = _uploadService.tasksStream.listen((tasks) {
      state = state.copyWith(tasks: tasks);
    });

    // Listen to progress updates
    _progressSubscription = _uploadService.progressStream.listen((progress) {
      state = state.copyWith(currentUploadId: progress.taskId);
    });

    // Set initial state
    state = state.copyWith(
      tasks: _uploadService.tasks,
      isInitialized: true,
    );
  }

  /// Queue a moment upload
  Future<String> queueMomentUpload({
    required String title,
    required String description,
    String privacy = 'public',
    String category = 'general',
    String language = 'en',
    String? mood,
    List<String>? tags,
    Map<String, dynamic>? location,
    List<String>? imagePaths,
    String? videoPath,
  }) async {
    return _uploadService.queueMomentUpload(
      title: title,
      description: description,
      privacy: privacy,
      category: category,
      language: language,
      mood: mood,
      tags: tags,
      location: location,
      imagePaths: imagePaths,
      videoPath: videoPath,
    );
  }

  /// Queue a story upload
  Future<String> queueStoryUpload({
    required String mediaPath,
    bool isVideo = false,
    String? text,
    String? backgroundColor,
    StoryPrivacy privacy = StoryPrivacy.everyone,
  }) async {
    return _uploadService.queueStoryUpload(
      mediaPath: mediaPath,
      isVideo: isVideo,
      text: text,
      backgroundColor: backgroundColor,
      privacy: privacy,
    );
  }

  /// Cancel an upload
  Future<void> cancelUpload(String taskId) async {
    await _uploadService.cancelUpload(taskId);
  }

  /// Retry a failed upload
  Future<void> retryUpload(String taskId) async {
    await _uploadService.retryUpload(taskId);
  }

  /// Remove a task from queue
  Future<void> removeTask(String taskId) async {
    await _uploadService.removeTask(taskId);
  }

  /// Clear all completed tasks
  Future<void> clearCompleted() async {
    await _uploadService.clearCompletedTasks();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for upload queue service singleton
final uploadQueueServiceProvider = Provider<UploadQueueService>((ref) {
  return UploadQueueService();
});

/// Provider for upload manager state
final uploadManagerProvider =
    StateNotifierProvider<UploadManagerNotifier, UploadManagerState>((ref) {
  final uploadService = ref.watch(uploadQueueServiceProvider);
  return UploadManagerNotifier(uploadService);
});

/// Provider for current upload progress stream
final uploadProgressStreamProvider = StreamProvider<UploadProgress>((ref) {
  final uploadService = ref.watch(uploadQueueServiceProvider);
  return uploadService.progressStream;
});

/// Provider for active tasks count
final activeUploadsCountProvider = Provider<int>((ref) {
  final state = ref.watch(uploadManagerProvider);
  return state.activeTasks.length;
});

/// Provider to check if there are any active uploads
final hasActiveUploadsProvider = Provider<bool>((ref) {
  final state = ref.watch(uploadManagerProvider);
  return state.hasActiveUploads;
});

/// Provider for current uploading task
final currentUploadingTaskProvider = Provider<UploadTask?>((ref) {
  final state = ref.watch(uploadManagerProvider);
  return state.currentTask;
});
