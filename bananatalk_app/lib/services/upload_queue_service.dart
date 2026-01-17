import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/upload_task.dart';
import '../providers/provider_root/moments_providers.dart';
import '../services/stories_service.dart';
import '../providers/provider_models/story_model.dart';

/// Service for managing background upload queue
/// Handles moments and stories uploads with persistence and retry logic
class UploadQueueService {
  static final UploadQueueService _instance = UploadQueueService._internal();
  factory UploadQueueService() => _instance;
  UploadQueueService._internal();

  static const String _storageKey = 'upload_queue_tasks';
  static const int _maxRetries = 3;

  final MomentsService _momentsService = MomentsService();

  /// List of all upload tasks
  final List<UploadTask> _tasks = [];

  /// Stream controller for progress updates
  final _progressController = StreamController<UploadProgress>.broadcast();

  /// Stream controller for task list changes
  final _tasksController = StreamController<List<UploadTask>>.broadcast();

  /// Whether the service is processing
  bool _isProcessing = false;

  /// Get all tasks
  List<UploadTask> get tasks => List.unmodifiable(_tasks);

  /// Get active tasks only
  List<UploadTask> get activeTasks =>
      _tasks.where((t) => t.isActive).toList();

  /// Get failed tasks
  List<UploadTask> get failedTasks =>
      _tasks.where((t) => t.status == UploadStatus.failed).toList();

  /// Stream of progress updates
  Stream<UploadProgress> get progressStream => _progressController.stream;

  /// Stream of task list changes
  Stream<List<UploadTask>> get tasksStream => _tasksController.stream;

  /// Check if there are any active uploads
  bool get hasActiveUploads => activeTasks.isNotEmpty;

  /// Initialize service and restore pending tasks
  Future<void> initialize() async {
    await _loadTasks();
    _resumeFailedUploads();
  }

  /// Queue a new upload task
  Future<String> queueUpload(UploadTask task) async {
    _tasks.add(task);
    _notifyTasksChanged();
    await _saveTasks();

    // Start processing if not already
    _processQueue();

    return task.id;
  }

  /// Queue moment upload (text + optional images + optional video)
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
    final hasVideo = videoPath != null && videoPath.isNotEmpty;
    final task = UploadTask(
      type: hasVideo ? UploadType.momentVideo : UploadType.moment,
      localFilePath: videoPath ?? (imagePaths?.isNotEmpty == true ? imagePaths!.first : ''),
      metadata: {
        'title': title,
        'description': description,
        'privacy': privacy,
        'category': category,
        'language': language,
        'mood': mood,
        'tags': tags,
        'location': location,
        'imagePaths': imagePaths,
        'videoPath': videoPath,
      },
    );

    return queueUpload(task);
  }

  /// Queue story upload
  Future<String> queueStoryUpload({
    required String mediaPath,
    bool isVideo = false,
    String? text,
    String? backgroundColor,
    StoryPrivacy privacy = StoryPrivacy.everyone,
  }) async {
    final task = UploadTask(
      type: isVideo ? UploadType.storyVideo : UploadType.story,
      localFilePath: mediaPath,
      metadata: {
        'mediaPath': mediaPath,
        'isVideo': isVideo,
        'text': text,
        'backgroundColor': backgroundColor,
        'privacy': privacy.name,
      },
    );

    return queueUpload(task);
  }

  /// Cancel an upload task
  Future<void> cancelUpload(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        status: UploadStatus.cancelled,
      );
      _notifyTasksChanged();
      await _saveTasks();
    }
  }

  /// Retry a failed upload
  Future<void> retryUpload(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1 && _tasks[taskIndex].status == UploadStatus.failed) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        status: UploadStatus.queued,
        progress: 0.0,
        error: null,
      );
      _notifyTasksChanged();
      await _saveTasks();
      _processQueue();
    }
  }

  /// Remove a task from the queue
  Future<void> removeTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    _notifyTasksChanged();
    await _saveTasks();
  }

  /// Clear all completed tasks
  Future<void> clearCompletedTasks() async {
    _tasks.removeWhere((t) => t.status == UploadStatus.completed);
    _notifyTasksChanged();
    await _saveTasks();
  }

  /// Process the upload queue
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (true) {
      // Find next queued task
      final taskIndex = _tasks.indexWhere((t) => t.status == UploadStatus.queued);
      if (taskIndex == -1) break;

      final task = _tasks[taskIndex];
      await _processTask(task, taskIndex);
    }

    _isProcessing = false;
  }

  /// Process a single upload task
  Future<void> _processTask(UploadTask task, int taskIndex) async {
    try {
      // Update status to uploading
      _tasks[taskIndex] = task.copyWith(status: UploadStatus.uploading);
      _notifyTasksChanged();
      _notifyProgress(task.id, 0.0, UploadStatus.uploading);

      String? resultId;

      switch (task.type) {
        case UploadType.moment:
          resultId = await _uploadMoment(task, taskIndex);
          break;
        case UploadType.momentVideo:
          resultId = await _uploadMomentWithVideo(task, taskIndex);
          break;
        case UploadType.story:
          resultId = await _uploadStory(task, taskIndex, isVideo: false);
          break;
        case UploadType.storyVideo:
          resultId = await _uploadStory(task, taskIndex, isVideo: true);
          break;
      }

      // Mark as completed
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        status: UploadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
        resultId: resultId,
      );
      _notifyTasksChanged();
      _notifyProgress(task.id, 1.0, UploadStatus.completed, message: 'Upload complete!');
      await _saveTasks();

    } catch (e) {
      print('Upload error for task ${task.id}: $e');

      // Increment retry count and check if should retry
      final newRetryCount = task.retryCount + 1;
      final shouldRetry = newRetryCount < _maxRetries;

      _tasks[taskIndex] = task.copyWith(
        status: shouldRetry ? UploadStatus.queued : UploadStatus.failed,
        error: e.toString(),
        retryCount: newRetryCount,
      );
      _notifyTasksChanged();
      _notifyProgress(
        task.id,
        task.progress,
        shouldRetry ? UploadStatus.queued : UploadStatus.failed,
        message: shouldRetry ? 'Retrying...' : 'Upload failed: ${e.toString()}',
      );
      await _saveTasks();

      // If should retry, add a delay before next attempt
      if (shouldRetry) {
        await Future.delayed(Duration(seconds: 2 * newRetryCount));
      }
    }
  }

  /// Upload a moment (text + optional images, no video)
  Future<String?> _uploadMoment(UploadTask task, int taskIndex) async {
    final metadata = task.metadata;

    // Create the moment first
    _notifyProgress(task.id, 0.1, UploadStatus.uploading, message: 'Creating moment...');

    final moment = await _momentsService.createMoments(
      title: metadata['title'] ?? '',
      description: metadata['description'] ?? '',
      privacy: metadata['privacy'] ?? 'public',
      category: metadata['category'] ?? 'general',
      language: metadata['language'] ?? 'en',
      mood: metadata['mood'],
      tags: metadata['tags'] != null ? List<String>.from(metadata['tags']) : null,
      location: metadata['location'],
    );

    // Update progress
    _tasks[taskIndex] = _tasks[taskIndex].copyWith(progress: 0.3);
    _notifyProgress(task.id, 0.3, UploadStatus.uploading, message: 'Uploading images...');

    // Upload images if any
    final imagePaths = metadata['imagePaths'];
    if (imagePaths != null && (imagePaths as List).isNotEmpty) {
      final imageFiles = imagePaths.map((p) => File(p.toString())).toList();
      await _momentsService.uploadMomentPhotos(moment.id!, imageFiles);
    }

    _tasks[taskIndex] = _tasks[taskIndex].copyWith(progress: 1.0);
    return moment.id;
  }

  /// Upload a moment with video
  Future<String?> _uploadMomentWithVideo(UploadTask task, int taskIndex) async {
    final metadata = task.metadata;

    // Create the moment first
    _notifyProgress(task.id, 0.1, UploadStatus.uploading, message: 'Creating moment...');

    final moment = await _momentsService.createMoments(
      title: metadata['title'] ?? '',
      description: metadata['description'] ?? '',
      privacy: metadata['privacy'] ?? 'public',
      category: metadata['category'] ?? 'general',
      language: metadata['language'] ?? 'en',
      mood: metadata['mood'],
      tags: metadata['tags'] != null ? List<String>.from(metadata['tags']) : null,
      location: metadata['location'],
    );

    // Update progress
    _tasks[taskIndex] = _tasks[taskIndex].copyWith(progress: 0.2);
    _notifyProgress(task.id, 0.2, UploadStatus.uploading, message: 'Uploading video...');

    // Upload video
    final videoPath = metadata['videoPath'];
    if (videoPath != null) {
      final videoFile = File(videoPath);
      await _momentsService.uploadMomentVideo(
        moment.id!,
        videoFile,
        onProgress: (progress) {
          // Map progress (0-100) to our range (0.2-0.9)
          final mappedProgress = 0.2 + (progress / 100) * 0.7;
          _tasks[taskIndex] = _tasks[taskIndex].copyWith(progress: mappedProgress);
          _notifyProgress(task.id, mappedProgress, UploadStatus.uploading,
              message: 'Uploading video... $progress%');
        },
      );
    }

    // Upload images if any
    final imagePaths = metadata['imagePaths'];
    if (imagePaths != null && (imagePaths as List).isNotEmpty) {
      _notifyProgress(task.id, 0.95, UploadStatus.uploading, message: 'Uploading images...');
      final imageFiles = imagePaths.map((p) => File(p.toString())).toList();
      await _momentsService.uploadMomentPhotos(moment.id!, imageFiles);
    }

    _tasks[taskIndex] = _tasks[taskIndex].copyWith(progress: 1.0);
    return moment.id;
  }

  /// Upload a story (image or video)
  Future<String?> _uploadStory(UploadTask task, int taskIndex, {required bool isVideo}) async {
    final metadata = task.metadata;

    _notifyProgress(task.id, 0.1, UploadStatus.uploading, message: 'Creating story...');

    final mediaPath = metadata['mediaPath'];
    final mediaFile = File(mediaPath);

    // Map privacy string back to enum
    StoryPrivacy privacy = StoryPrivacy.everyone;
    final privacyStr = metadata['privacy'];
    if (privacyStr != null) {
      privacy = StoryPrivacy.values.firstWhere(
        (p) => p.name == privacyStr,
        orElse: () => StoryPrivacy.everyone,
      );
    }

    final result = await StoriesService.createStory(
      mediaFiles: [mediaFile],
      text: metadata['text'],
      backgroundColor: metadata['backgroundColor'],
      privacy: privacy,
    );

    if (!result.success) {
      throw Exception(result.error ?? 'Failed to create story');
    }

    _tasks[taskIndex] = _tasks[taskIndex].copyWith(progress: 1.0);
    return result.data?.id;
  }

  /// Notify progress update
  void _notifyProgress(String taskId, double progress, UploadStatus status, {String? message}) {
    _progressController.add(UploadProgress(
      taskId: taskId,
      progress: progress,
      status: status,
      message: message,
    ));
  }

  /// Notify tasks changed
  void _notifyTasksChanged() {
    _tasksController.add(List.unmodifiable(_tasks));
  }

  /// Resume failed uploads on init
  void _resumeFailedUploads() {
    // Reset any uploads that were in progress when app closed
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].status == UploadStatus.uploading ||
          _tasks[i].status == UploadStatus.processing) {
        _tasks[i] = _tasks[i].copyWith(
          status: UploadStatus.queued,
          progress: 0.0,
        );
      }
    }
    _notifyTasksChanged();
    _processQueue();
  }

  /// Save tasks to persistent storage
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks.map((t) => t.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(tasksJson));
    } catch (e) {
      print('Error saving upload tasks: $e');
    }
  }

  /// Load tasks from persistent storage
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString(_storageKey);
      if (tasksString != null) {
        final tasksList = jsonDecode(tasksString) as List;
        _tasks.clear();
        _tasks.addAll(tasksList.map((t) => UploadTask.fromJson(t)));

        // Remove very old completed tasks (older than 24 hours)
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        _tasks.removeWhere((t) =>
            t.status == UploadStatus.completed &&
            t.completedAt != null &&
            t.completedAt!.isBefore(cutoff));

        _notifyTasksChanged();
      }
    } catch (e) {
      print('Error loading upload tasks: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _tasksController.close();
  }
}
