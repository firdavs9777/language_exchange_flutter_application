import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/pages/moments/create/moment_media_rules.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:bananatalk_app/services/story_upload_payload.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Task-metadata key holding the id of the moment this task already created.
///
/// Stored in metadata (which is persisted with the task) so a retry — even
/// one after an app restart — re-runs only the failed media step instead of
/// creating the moment again.
const String kCreatedMomentIdKey = 'createdMomentId';

/// Posts one attempt of a queued story; [idempotencyKey] is sent as the
/// `Idempotency-Key` header, so a repeat can never create a second story.
typedef StoryPoster = Future<SingleStoryResponse> Function(
    StoryUploadPayload payload, String idempotencyKey);

/// [UploadQueueService.queueStoryUpload] could not queue the story (its
/// media could not be copied, or nobody is signed in). Nothing was queued;
/// the caller can post the blocking way instead.
class StoryUploadQueueException implements Exception {
  StoryUploadQueueException(this.message);
  final String message;

  @override
  String toString() => 'StoryUploadQueueException: $message';
}

// Story-task bookkeeping, persisted in the task's metadata next to the
// payload (StoryUploadPayload.fromJson ignores these keys).
const String _kNextAttemptAt = 'storyNextAttemptAt'; // ms since epoch
const String _kWaitReason = 'storyWaitReason'; // failure | inProgress | tryAgain
const String _kInProgressSince = 'storyInProgressSince'; // ms since epoch
const String _kInProgressCount = 'storyInProgressCount';
const String _kTryAgainCount = 'storyTryAgainCount';
const String _waitForFailure = 'failure';

/// Service for managing background upload queue
/// Handles moments and stories uploads with persistence and retry logic
class UploadQueueService {
  static final UploadQueueService _instance = UploadQueueService._internal();
  factory UploadQueueService() => _instance;
  UploadQueueService._internal();

  static const String _storageKey = 'upload_queue_tasks';
  static const int _maxRetries = 3;

  static Duration defaultRetryDelay(int attempt) =>
      Duration(seconds: 2 * attempt);

  /// Pause before automatic retry number [attempt]. Swappable so tests do not
  /// wait real seconds.
  @visibleForTesting
  static Duration Function(int attempt) retryDelay = defaultRetryDelay;

  // ---- Stories ------------------------------------------------------------
  // A story task has its own policy (moments keep the one above): the
  // Idempotency-Key is the task id on every attempt, so any attempt -- an
  // automatic retry, a manual one, one after a restart -- is safe to send.

  /// Private copies of queued story media live here, under the app's
  /// documents directory, as `<taskId>.<ext>`.
  static const String storyUploadsFolder = 'story_uploads';

  /// Waits after an ordinary failure: 5 automatic retries, then `failed`.
  static const List<Duration> storyRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 45),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  /// Waits after "Story upload already in progress" (409); the last repeats.
  /// The whole multipart body is re-sent each time, hence the back-off.
  static const List<Duration> storyInProgressDelays = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  /// "In progress" for this long (from the first such answer) gives up.
  static const Duration storyInProgressGiveUp = Duration(minutes: 30);

  /// Wait after a 503, at most [storyTryAgainInARow] times in a row.
  static const Duration storyTryAgainDelay = Duration(seconds: 30);
  static const int storyTryAgainInARow = 5;

  /// A stored retry time further away than this is not trusted (the device
  /// clock moved) and the attempt runs at once.
  static const Duration _longestStoryWait = Duration(minutes: 10);

  static Future<SingleStoryResponse> defaultStoryPoster(
      StoryUploadPayload p, String idempotencyKey) {
    if (p.isTextStory) {
      return StoriesService.createTextStory(
        text: p.text ?? ' ',
        backgroundColor: p.backgroundColor ?? '#000000',
        textColor: p.textColor ?? '#FFFFFF',
        fontStyle: p.fontStyle ?? 'normal',
        privacy: p.privacy,
        allowReplies: p.allowReplies,
        allowSharing: p.allowSharing,
        overlays: p.overlays,
        hashtags: p.hashtags,
        location: p.location,
        mentions: p.mentions,
        link: p.link,
        poll: p.poll,
        questionBox: p.questionBox,
        correctionSticker: p.correctionSticker,
        quizSticker: p.quizSticker,
        wordSticker: p.wordSticker,
        idempotencyKey: idempotencyKey,
      );
    }
    return StoriesService.createStory(
      mediaFiles: [File(p.mediaPath!)],
      text: p.text,
      backgroundColor: p.backgroundColor,
      textColor: p.textColor,
      fontStyle: p.fontStyle,
      privacy: p.privacy,
      poll: p.poll,
      questionBox: p.questionBox,
      location: p.location,
      link: p.link,
      mentions: p.mentions,
      hashtags: p.hashtags,
      allowReplies: p.allowReplies,
      allowSharing: p.allowSharing,
      overlays: p.overlays,
      correctionSticker: p.correctionSticker,
      quizSticker: p.quizSticker,
      wordSticker: p.wordSticker,
      idempotencyKey: idempotencyKey,
    );
  }

  static Future<String?> _storedUserId() async =>
      (await SharedPreferences.getInstance()).getString('userId');

  static Timer _realTimer(Duration d, void Function() cb) => Timer(d, cb);

  static Stream<List<ConnectivityResult>> _realConnectivity() =>
      Connectivity().onConnectivityChanged;

  @visibleForTesting
  static StoryPoster storyPoster = defaultStoryPoster;
  @visibleForTesting
  static Future<Directory> Function() documentsDirectory =
      getApplicationDocumentsDirectory;
  @visibleForTesting
  static Future<String?> Function() signedInUserId = _storedUserId;
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;
  @visibleForTesting
  static Timer Function(Duration, void Function()) startTimer = _realTimer;
  @visibleForTesting
  static Stream<List<ConnectivityResult>> Function() connectivityChanges =
      _realConnectivity;

  /// One story attempt may take this long (a large video on a slow line);
  /// then it counts as a failure and is retried with the same key.
  @visibleForTesting
  static Duration storyAttemptTimeout = const Duration(minutes: 10);

  static Stream<FileSystemEntity> _realLister(Directory d) => d.list();

  /// Lists the uploads folder for the orphan sweep (tests slow it down).
  @visibleForTesting
  static Stream<FileSystemEntity> Function(Directory) storyDirLister =
      _realLister;

  @visibleForTesting
  static void resetStorySeamsForTest() {
    storyPoster = defaultStoryPoster;
    documentsDirectory = getApplicationDocumentsDirectory;
    signedInUserId = _storedUserId;
    clock = DateTime.now;
    startTimer = _realTimer;
    connectivityChanges = _realConnectivity;
    storyAttemptTimeout = const Duration(minutes: 10);
    storyDirLister = _realLister;
  }

  final _storyPostedController = StreamController<String>.broadcast();

  /// The id of a story task, once, when its story is on the server (posted
  /// now, or found already posted by an earlier attempt).
  Stream<String> get storyPostedStream => _storyPostedController.stream;

  /// Wakes the queue for the earliest waiting story retry.
  Timer? _storyWakeTimer;

  /// A story could run but no signed-in user id was readable: look again
  /// after [_noUserDelays] (the last repeats), counted by [_noUserLooks].
  bool _storyWaitingForUser = false;
  int _noUserLooks = 0;
  static const List<Duration> _noUserDelays = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  /// Story tasks whose attempt is running right now.
  final Set<String> _storyAttemptsInFlight = {};

  /// Copies being made by [queueStoryUpload]; the orphan sweep spares them.
  final Set<String> _copiesInProgress = {};

  final MomentsService _momentsService = MomentsService();

  /// List of all upload tasks
  final List<UploadTask> _tasks = [];

  /// Stream controller for progress updates
  final _progressController = StreamController<UploadProgress>.broadcast();

  /// Stream controller for task list changes
  final _tasksController = StreamController<List<UploadTask>>.broadcast();

  /// Whether the service is processing
  bool _isProcessing = false;

  /// Bumped by [endSession]. Every upload captures it when it starts and
  /// stops at its next step once it changes, so a logout cannot let the
  /// previous account's upload carry on -- the second step (photos/video
  /// after the moment is created) reads the token fresh from prefs, i.e.
  /// it would have run as whoever signed in next -- or write its result
  /// into the next account's queue.
  int _sessionGeneration = 0;

  @visibleForTesting
  int get sessionGenerationForTest => _sessionGeneration;

  /// Logout / account deletion / session expiry: drop every task of the
  /// signed-out account and abandon in-flight ones at their next step. A
  /// single HTTP request already on the wire finishes under the old
  /// account's own token (it was signed when sent); nothing after it runs.
  Future<void> endSession() async {
    _sessionGeneration++;
    _tasks.clear();
    _isProcessing = false;
    _notifyTasksChanged();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
    // Stories: no retry may wake up, and the account's private media
    // copies go with its tasks. (The subscription is already cancelled by
    // _notifyTasksChanged above: no story task is left.)
    _storyWakeTimer?.cancel();
    _storyWakeTimer = null;
    _wasOffline = false;
    _storyWaitingForUser = false;
    _noUserLooks = 0;
    await _sweepStoryFiles();
  }

  void _checkSession(int generation) {
    if (generation != _sessionGeneration) throw _SessionEnded();
  }

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
    await _restoreStoryTasks();
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
    required String description,
    String privacy = 'public',
    String category = 'general',
    String language = 'en',
    String? mood,
    List<String>? tags,
    Map<String, dynamic>? location,
    List<String>? imagePaths,
    String? videoPath,
    String? backgroundColor,
    // Workstream G: Reels ride on the same moment-creation pipeline.
    String? promptId,
    bool isReel = false,
    // ISO-8601 UTC; null posts at once.
    String? scheduledFor,
  }) async {
    final hasVideo = videoPath != null && videoPath.isNotEmpty;
    final task = UploadTask(
      type: hasVideo ? UploadType.momentVideo : UploadType.moment,
      localFilePath: videoPath ?? (imagePaths?.isNotEmpty == true ? imagePaths!.first : ''),
      metadata: {
        'description': description,
        'privacy': privacy,
        'category': category,
        'language': language,
        'mood': mood,
        'tags': tags,
        'location': location,
        'imagePaths': imagePaths,
        'videoPath': videoPath,
        'backgroundColor': backgroundColor,
        'promptId': promptId,
        'isReel': isReel,
        'scheduledFor': scheduledFor,
      },
    );

    return queueUpload(task);
  }

  /// Queue a story with everything it carries. Returns the task id, which is
  /// also the story's Idempotency-Key on every attempt.
  ///
  /// The media is first copied to `<documents>/story_uploads/<taskId>.<ext>`
  /// so a cleared cache or a deleted gallery file cannot lose the story; the
  /// copy is deleted once the story is posted, or the task is cancelled or
  /// removed. If the copy fails (or nobody is signed in) this throws
  /// [StoryUploadQueueException] and nothing is queued.
  Future<String> queueStoryUpload(StoryUploadPayload payload) async {
    final generation = _sessionGeneration;
    final id = const Uuid().v4();

    var owner = payload.ownerUserId;
    if (owner == null || owner.isEmpty) owner = await _signedInUserIdOrNull();
    if (owner == null || owner.isEmpty) {
      throw StoryUploadQueueException('nobody is signed in');
    }

    // Until the task is in the list, the orphan sweep must spare its copy.
    _copiesInProgress.add(id);
    try {
      String? copyPath;
      if (!payload.isTextStory) {
        copyPath = await _copyStoryMedia(id, payload.mediaPath!);
        if (generation != _sessionGeneration) {
          // Signed out while copying: this story belongs to nobody now.
          await _deleteStoryFile(copyPath);
          throw StoryUploadQueueException('the session ended');
        }
      }

      final task = UploadTask(
        id: id,
        type: payload.isVideo ? UploadType.storyVideo : UploadType.story,
        localFilePath: copyPath ?? '',
        metadata: payload
            .copyWith(mediaPath: copyPath, ownerUserId: owner)
            .toJson(),
      );
      return await queueUpload(task);
    } finally {
      _copiesInProgress.remove(id);
    }
  }

  /// The pre-payload form: a media story with a caption, colour and privacy.
  Future<String> queueSimpleStoryUpload({
    required String mediaPath,
    bool isVideo = false,
    String? text,
    String? backgroundColor,
    StoryPrivacy privacy = StoryPrivacy.everyone,
  }) {
    return queueStoryUpload(StoryUploadPayload(
      mediaPath: mediaPath,
      isVideo: isVideo,
      text: text,
      backgroundColor: backgroundColor,
      privacy: privacy,
    ));
  }

  /// Cancel an upload task
  Future<void> cancelUpload(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final cancelled = _tasks[taskIndex].copyWith(
        status: UploadStatus.cancelled,
      );
      _tasks[taskIndex] = cancelled;
      _notifyTasksChanged();
      await _saveTasks();
      // Not _tasks[taskIndex]: the save awaited, and the list may have moved.
      await _deleteStoryCopy(cancelled);
    }
  }

  /// Retry a failed upload
  Future<void> retryUpload(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1 && _tasks[taskIndex].status == UploadStatus.failed) {
      final task = _tasks[taskIndex];
      if (task.isStory) {
        // A fresh automatic schedule; the key (the task id) stays the same,
        // so if an earlier attempt did post, this gets that story back.
        _clearStoryWait(task.metadata);
        task.metadata.remove(kStoryFailureKey);
      }
      _tasks[taskIndex] = task.copyWith(
        status: UploadStatus.queued,
        progress: 0.0,
        error: null,
        retryCount: task.isStory ? 0 : null,
      );
      _notifyTasksChanged();
      await _saveTasks();
      _processQueue();
    }
  }

  /// Remove a task from the queue
  Future<void> removeTask(String taskId) async {
    final removed = _tasks.where((t) => t.id == taskId).toList();
    _tasks.removeWhere((t) => t.id == taskId);
    _notifyTasksChanged();
    await _saveTasks();
    for (final task in removed) {
      await _deleteStoryCopy(task);
    }
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
    final generation = _sessionGeneration;

    while (generation == _sessionGeneration) {
      // Story tasks run only as their owner and only once their retry time
      // has come; with no story queued this is exactly the moment loop.
      String? userId;
      _storyWaitingForUser = false;
      if (_tasks.any((t) => t.isStory && t.status == UploadStatus.queued)) {
        userId = await _signedInUserIdOrNull();
        if (generation != _sessionGeneration) break;
        if (userId == null || userId.isEmpty) {
          final now = clock();
          _storyWaitingForUser = _tasks.any((t) =>
              t.isStory &&
              t.status == UploadStatus.queued &&
              _storyRetryAt(t, now) == null);
        } else {
          _storyWaitingForUser = false;
          _noUserLooks = 0;
        }
        await _dropStoryTasksOfOtherUsers(userId);
        if (generation != _sessionGeneration) break;
      }

      // Find next queued task
      final now = clock();
      final taskIndex = _tasks.indexWhere((t) =>
          t.status == UploadStatus.queued &&
          (!t.isStory || _storyRunnable(t, userId, now)));
      if (taskIndex == -1) break;

      final task = _tasks[taskIndex];
      if (task.isStory) {
        await _processStoryTask(task, generation);
      } else {
        await _processTask(task, generation);
      }
    }

    // A newer session owns the flag now (endSession reset it).
    if (generation == _sessionGeneration) {
      _isProcessing = false;
      _armStoryWakeTimer();
    }
  }

  /// Writes [update] onto the task with [id] wherever it sits now; false,
  /// writing nothing, when it has left the queue.
  ///
  /// The moment path must never hold a list index across an await: a task
  /// removed meanwhile (the stories ring's Remove) shifts every task after
  /// it, and a stale index writes into another task or past the end.
  bool _updateTask(String id, UploadTask Function(UploadTask) update) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1) return false;
    _tasks[i] = update(_tasks[i]);
    return true;
  }

  /// Process a single upload task
  Future<void> _processTask(UploadTask task, [int? generation]) async {
    final gen = generation ?? _sessionGeneration;
    final id = task.id;
    try {
      // Update status to uploading
      _updateTask(id, (_) => task.copyWith(status: UploadStatus.uploading));
      _notifyTasksChanged();
      _notifyProgress(task.id, 0.0, UploadStatus.uploading);

      String? resultId;

      switch (task.type) {
        case UploadType.moment:
          resultId = await _uploadMoment(task, gen);
          break;
        case UploadType.momentVideo:
          resultId = await _uploadMomentWithVideo(task, gen);
          break;
        case UploadType.story:
        case UploadType.storyVideo:
          // Never reached: _processQueue runs story tasks through
          // _processStoryTask, which has its own outcomes and retry policy.
          throw StateError('story task outside _processStoryTask');
      }

      _checkSession(gen);
      // Mark as completed (unless it was removed while uploading).
      if (!_updateTask(
          id,
          (t) => t.copyWith(
                status: UploadStatus.completed,
                progress: 1.0,
                completedAt: DateTime.now(),
                resultId: resultId,
              ))) {
        return;
      }
      _notifyTasksChanged();
      _notifyProgress(task.id, 1.0, UploadStatus.completed, message: 'Upload complete!');
      await _saveTasks();

    } catch (e) {
      // Signed out mid-upload: the task is gone with its account. Writing
      // its failure would index into the next account's queue.
      if (e is _SessionEnded || gen != _sessionGeneration) return;
      // Removed while uploading: nothing left to mark or retry.
      if (!_tasks.any((t) => t.id == id)) return;

      // Increment retry count and check if should retry
      final newRetryCount = task.retryCount + 1;
      final shouldRetry = newRetryCount < _maxRetries;

      if (!shouldRetry &&
          (task.type == UploadType.moment ||
              task.type == UploadType.momentVideo)) {
        await _rollBackCreatedMoment(task);
        if (gen != _sessionGeneration) return;
      }

      if (!_updateTask(
          id,
          (_) => task.copyWith(
                status: shouldRetry ? UploadStatus.queued : UploadStatus.failed,
                error: e.toString(),
                retryCount: newRetryCount,
              ))) {
        return;
      }
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
        await Future.delayed(retryDelay(newRetryCount));
      }
    }
  }

  /// The image files of a moment task, or empty.
  List<File> _imageFiles(Map<String, dynamic> metadata) {
    final imagePaths = metadata['imagePaths'];
    if (imagePaths is! List || imagePaths.isEmpty) return const [];
    return imagePaths.map((p) => File(p.toString())).toList();
  }

  /// Creates the task's moment, or returns the one an earlier attempt of this
  /// same task already created.
  ///
  /// The id is written into the task's metadata the moment the server
  /// answers, and saved, so a retry -- automatic, manual, or after an app
  /// restart -- re-runs only the media step that failed. Before this, every
  /// retry created another moment: a photo or video step that failed twice
  /// left three caption-only copies in the feed.
  Future<String> _createOrReuseMoment(UploadTask task, int gen) async {
    final metadata = task.metadata;
    final existing = metadata[kCreatedMomentIdKey];
    if (existing is String && existing.isNotEmpty) return existing;

    // Refuse a photo the upload step would refuse, BEFORE anything exists.
    final images = _imageFiles(metadata);
    final problem = firstMomentImageProblem([
      for (final f in images) (f.path, await f.length()),
    ]);
    if (problem != null) throw Exception(problem);

    _notifyProgress(task.id, 0.1, UploadStatus.uploading, message: 'Creating moment...');

    final moment = await _momentsService.createMoments(
      description: metadata['description'] ?? '',
      privacy: metadata['privacy'] ?? 'public',
      category: metadata['category'] ?? 'general',
      language: metadata['language'] ?? 'en',
      mood: metadata['mood'],
      tags: metadata['tags'] != null ? List<String>.from(metadata['tags']) : null,
      location: metadata['location'],
      backgroundColor: metadata['backgroundColor'],
      promptId: metadata['promptId'],
      isReel: metadata['isReel'] == true,
      scheduledFor: metadata['scheduledFor'],
    );
    _checkSession(gen);
    metadata[kCreatedMomentIdKey] = moment.id;
    await _saveTasks();
    ActivationStore().markDone(ActivationAction.moment).ignore();
    return moment.id;
  }

  /// A moment task failed for the last time after its moment was created:
  /// delete that moment rather than leave a caption-only (or, for a
  /// photo/video-only post, completely empty) half in the feed. See
  /// `afterMediaUploadFailed` -- photos and video are all-or-nothing.
  ///
  /// Best effort: if the delete itself fails the id is kept, so a manual
  /// retry still attaches the media to the existing moment instead of
  /// creating a duplicate.
  Future<void> _rollBackCreatedMoment(UploadTask task) async {
    final id = task.metadata[kCreatedMomentIdKey];
    if (id is! String || id.isEmpty) return;
    try {
      await _momentsService.deleteUserMoment(id: id);
      task.metadata.remove(kCreatedMomentIdKey);
    } catch (e) {
      debugPrint('Upload rollback: could not delete moment $id: $e');
    }
  }

  /// Upload a moment (text + optional images, no video)
  Future<String?> _uploadMoment(UploadTask task, int gen) async {
    final momentId = await _createOrReuseMoment(task, gen);

    // Update progress
    _updateTask(task.id, (t) => t.copyWith(progress: 0.3));
    _notifyProgress(task.id, 0.3, UploadStatus.uploading, message: 'Uploading images...');

    // Upload images if any
    final imageFiles = _imageFiles(task.metadata);
    if (imageFiles.isNotEmpty) {
      await _momentsService.uploadMomentPhotos(momentId, imageFiles);
    }

    _updateTask(task.id, (t) => t.copyWith(progress: 1.0));
    return momentId;
  }

  /// Upload a moment with video
  Future<String?> _uploadMomentWithVideo(UploadTask task, int gen) async {
    final metadata = task.metadata;
    final momentId = await _createOrReuseMoment(task, gen);

    // Update progress
    _updateTask(task.id, (t) => t.copyWith(progress: 0.2));
    _notifyProgress(task.id, 0.2, UploadStatus.uploading, message: 'Uploading video...');

    // Upload video
    final videoPath = metadata['videoPath'];
    if (videoPath != null) {
      final videoFile = File(videoPath);
      await _momentsService.uploadMomentVideo(
        momentId,
        videoFile,
        onProgress: (progress) {
          if (gen != _sessionGeneration) return;
          // Map progress (0-100) to our range (0.2-0.9)
          final mappedProgress = 0.2 + (progress / 100) * 0.7;
          _updateTask(task.id, (t) => t.copyWith(progress: mappedProgress));
          _notifyProgress(task.id, mappedProgress, UploadStatus.uploading,
              message: 'Uploading video... $progress%');
        },
      );
    }

    _checkSession(gen);

    // Upload images if any
    final imageFiles = _imageFiles(metadata);
    if (imageFiles.isNotEmpty) {
      _notifyProgress(task.id, 0.95, UploadStatus.uploading, message: 'Uploading images...');
      await _momentsService.uploadMomentPhotos(momentId, imageFiles);
    }

    _updateTask(task.id, (t) => t.copyWith(progress: 1.0));
    return momentId;
  }

  /// One attempt of a story task, and what its outcome means:
  ///  - posted (201, a replay included) -> completed; the copy is deleted;
  ///  - "already posted" (409) -> the story exists or existed: completed and
  ///    removed from the queue, never failed;
  ///  - "in progress" (409) -> retried after 30 s, 2 min, 5 min, then every
  ///    10 min, without using an attempt; failed after 30 minutes of it;
  ///  - 503 -> retried after 30 s without using an attempt, at most
  ///    [storyTryAgainInARow] times in a row, then an ordinary failure;
  ///  - daily limit (429) -> failed, no automatic retry;
  ///  - private copy missing -> failed, no retry;
  ///  - anything else, a timeout or an exception -> [storyRetryDelays], then
  ///    failed until the user retries or removes it.
  /// The Idempotency-Key is the task id every time.
  Future<void> _processStoryTask(UploadTask task, int gen) async {
    final id = task.id;
    var index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    task.metadata.remove(_kNextAttemptAt);
    _tasks[index] = task.copyWith(status: UploadStatus.uploading, progress: 0.0);
    _notifyTasksChanged();
    _notifyProgress(id, 0.0, UploadStatus.uploading);

    SingleStoryResponse? result;
    var fileMissing = false;
    String? error;
    _storyAttemptsInFlight.add(id);
    try {
      var payload = StoryUploadPayload.fromJson(task.metadata);
      if (!payload.isTextStory) {
        final media = await _currentStoryFile(payload.mediaPath!);
        if (!await media.exists()) {
          fileMissing = true;
        } else {
          payload = payload.copyWith(mediaPath: media.path);
        }
      }
      if (!fileMissing && gen == _sessionGeneration) {
        _notifyProgress(id, 0.1, UploadStatus.uploading,
            message: 'Creating story...');
        result = await storyPoster(payload, id).timeout(storyAttemptTimeout);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      _storyAttemptsInFlight.remove(id);
    }

    // Signed out meanwhile: the task left with its account.
    if (gen != _sessionGeneration) return;
    index = _tasks.indexWhere((t) => t.id == id);
    // Cancelled or removed while the request was out: leave it as it is.
    if (index == -1 || _tasks[index].status != UploadStatus.uploading) return;
    final current = _tasks[index];
    final m = current.metadata;
    error ??= result?.error;

    if (fileMissing) {
      return _failStory(index, StoryUploadFailure.fileMissing, error);
    }
    if (result != null && result.success) {
      _clearStoryWait(m);
      m.remove(kStoryFailureKey);
      _tasks[index] = current.copyWith(
        status: UploadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
        resultId: result.data?.id,
      );
      _notifyTasksChanged();
      _notifyProgress(id, 1.0, UploadStatus.completed,
          message: 'Upload complete!');
      await _saveTasks();
      _storyPostedController.add(id);
      await _deleteStoryCopy(current);
      return;
    }
    if (result?.failure == StoryPostFailure.alreadyPosted) {
      // An earlier attempt of this same task posted it.
      _tasks[index] = current.copyWith(
        status: UploadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
      );
      _notifyTasksChanged();
      _notifyProgress(id, 1.0, UploadStatus.completed,
          message: 'Upload complete!');
      _tasks.removeWhere((t) => t.id == id);
      _notifyTasksChanged();
      await _saveTasks();
      _storyPostedController.add(id);
      await _deleteStoryCopy(current);
      return;
    }
    if (result?.failure == StoryPostFailure.inProgress) {
      m.remove(_kTryAgainCount);
      final now = clock();
      final since = m[_kInProgressSince] is int
          ? DateTime.fromMillisecondsSinceEpoch(m[_kInProgressSince] as int)
          : now;
      if (now.difference(since) >= storyInProgressGiveUp) {
        return _failStory(index, StoryUploadFailure.failed, error);
      }
      final count = m[_kInProgressCount] is int ? m[_kInProgressCount] as int : 0;
      m[_kInProgressSince] = since.millisecondsSinceEpoch;
      m[_kInProgressCount] = count + 1;
      var delay = storyInProgressDelays[
          count < storyInProgressDelays.length
              ? count
              : storyInProgressDelays.length - 1];
      // The last look lands exactly at the give-up time, not up to 10 min
      // after it: an "in progress" answer then fails the task at 30 min.
      final left = since.add(storyInProgressGiveUp).difference(now);
      if (delay > left) delay = left;
      return _scheduleStoryRetry(index, delay, 'inProgress', error);
    }
    m.remove(_kInProgressSince);
    m.remove(_kInProgressCount);
    if (result?.failure == StoryPostFailure.tryAgain) {
      final streak = m[_kTryAgainCount] is int ? m[_kTryAgainCount] as int : 0;
      if (streak < storyTryAgainInARow) {
        m[_kTryAgainCount] = streak + 1;
        return _scheduleStoryRetry(
            index, storyTryAgainDelay, 'tryAgain', error);
      }
      // Too many 503s in a row: an ordinary failure from here.
    }
    m.remove(_kTryAgainCount);
    if (result != null && result.limitReached) {
      return _failStory(index, StoryUploadFailure.limitReached, error);
    }
    final failure = result?.failure;
    if (failure == StoryPostFailure.noMedia ||
        failure == StoryPostFailure.noText ||
        failure == StoryPostFailure.videoTooLarge) {
      // Refused on the device; the same payload would be refused again.
      return _failStory(index, StoryUploadFailure.failed, error);
    }

    final failures = current.retryCount + 1;
    if (failures <= storyRetryDelays.length) {
      return _scheduleStoryRetry(
          index, storyRetryDelays[failures - 1], _waitForFailure, error,
          retryCount: failures);
    }
    return _failStory(index, StoryUploadFailure.failed, error,
        retryCount: failures);
  }

  Future<void> _scheduleStoryRetry(
    int index,
    Duration delay,
    String reason,
    String? error, {
    int? retryCount,
  }) async {
    final task = _tasks[index];
    task.metadata[_kNextAttemptAt] = clock().add(delay).millisecondsSinceEpoch;
    task.metadata[_kWaitReason] = reason;
    _tasks[index] = task.copyWith(
      status: UploadStatus.queued,
      error: error,
      retryCount: retryCount,
    );
    _notifyTasksChanged();
    _notifyProgress(task.id, task.progress, UploadStatus.queued,
        message: 'Retrying...');
    await _saveTasks();
  }

  Future<void> _failStory(
    int index,
    StoryUploadFailure code,
    String? error, {
    int? retryCount,
  }) async {
    final task = _tasks[index];
    _clearStoryWait(task.metadata);
    task.metadata[kStoryFailureKey] = code.name;
    _tasks[index] = task.copyWith(
      status: UploadStatus.failed,
      error: error ?? code.name,
      retryCount: retryCount,
    );
    _notifyTasksChanged();
    _notifyProgress(task.id, task.progress, UploadStatus.failed,
        message: 'Upload failed: ${error ?? code.name}');
    await _saveTasks();
  }

  void _clearStoryWait(Map<String, dynamic> m) {
    m.remove(_kNextAttemptAt);
    m.remove(_kWaitReason);
    m.remove(_kInProgressSince);
    m.remove(_kInProgressCount);
    m.remove(_kTryAgainCount);
  }

  /// When a waiting story task may run, or null when it may run now.
  DateTime? _storyRetryAt(UploadTask t, DateTime now) {
    final at = t.metadata[_kNextAttemptAt];
    if (at is! int) return null;
    final when = DateTime.fromMillisecondsSinceEpoch(at);
    if (!when.isAfter(now)) return null;
    if (when.difference(now) > _longestStoryWait) return null;
    return when;
  }

  bool _storyRunnable(UploadTask t, String? userId, DateTime now) {
    if (userId == null || userId.isEmpty) return false;
    final owner = t.metadata['ownerUserId'];
    if (owner is String && owner.isNotEmpty && owner != userId) return false;
    return _storyRetryAt(t, now) == null;
  }

  /// Arms one timer for the earliest waiting story retry.
  void _armStoryWakeTimer() {
    _storyWakeTimer?.cancel();
    _storyWakeTimer = null;
    final now = clock();
    DateTime? earliest;
    for (final t in _tasks) {
      if (!t.isStory || t.status != UploadStatus.queued) continue;
      final at = _storyRetryAt(t, now);
      if (at != null && (earliest == null || at.isBefore(earliest))) {
        earliest = at;
      }
    }
    if (_storyWaitingForUser) {
      final wait = _noUserDelays[_noUserLooks < _noUserDelays.length
          ? _noUserLooks
          : _noUserDelays.length - 1];
      _noUserLooks++;
      final at = now.add(wait);
      if (earliest == null || at.isBefore(earliest)) earliest = at;
    }
    if (earliest == null) return;
    final gen = _sessionGeneration;
    _storyWakeTimer = startTimer(earliest.difference(now), () {
      _storyWakeTimer = null;
      if (gen == _sessionGeneration) _processQueue();
    });
  }

  Future<String?> _signedInUserIdOrNull() async {
    try {
      return await signedInUserId();
    } catch (_) {
      return null;
    }
  }

  /// A story task queued by another account is never uploaded: dropped,
  /// with its private copy. Legacy tasks (no owner) stay: the queue is
  /// cleared at every sign-out, so they can only be the current user's.
  Future<void> _dropStoryTasksOfOtherUsers(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    final foreign = _tasks.where((t) {
      if (!t.isStory) return false;
      final owner = t.metadata['ownerUserId'];
      return owner is String && owner.isNotEmpty && owner != userId;
    }).toList();
    if (foreign.isEmpty) return;
    _tasks.removeWhere(foreign.contains);
    _notifyTasksChanged();
    await _saveTasks();
    for (final t in foreign) {
      await _deleteStoryCopy(t);
    }
  }

  /// After a restart: drop other accounts' story tasks and delete private
  /// copies that belong to no task.
  Future<void> _restoreStoryTasks() async {
    final generation = _sessionGeneration;
    if (_tasks.any((t) => t.isStory)) {
      final userId = await _signedInUserIdOrNull();
      if (generation != _sessionGeneration) return;
      await _dropStoryTasksOfOtherUsers(userId);
    }
    await _sweepStoryFiles();
  }

  /// Deletes every file in the uploads folder no task (and no copy being
  /// made) refers to.
  Future<void> _sweepStoryFiles() async {
    try {
      final dir = await _storyUploadsDir();
      if (!await dir.exists()) return;
      await for (final entry in storyDirLister(dir)) {
        final name = _fileName(entry.path);
        // Checked live per entry: a story queued while the listing runs is
        // in _tasks by the time its file is reached (a snapshot taken
        // before the listing would miss it and delete its copy).
        if (_isReferencedStoryFile(name)) continue;
        if (_copiesInProgress.any(name.startsWith)) continue;
        try {
          await entry.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {
      // No documents directory (tests, a broken install): nothing to sweep.
    }
  }

  bool _isReferencedStoryFile(String name) => _tasks.any((t) {
        final path = t.metadata['mediaPath'];
        return t.isStory && path is String && _fileName(path) == name;
      });

  Future<Directory> _storyUploadsDir() async =>
      Directory('${(await documentsDirectory()).path}/$storyUploadsFolder');

  static String _fileName(String path) => path.split('/').last;

  /// [path] as stored, re-rooted on today's documents directory when it is
  /// one of our copies: on iOS the app container's path changes with an app
  /// update, so a stored absolute path can go stale.
  Future<File> _currentStoryFile(String path) async {
    if (!path.contains('/$storyUploadsFolder/')) return File(path);
    try {
      final dir = await _storyUploadsDir();
      return File('${dir.path}/${_fileName(path)}');
    } catch (_) {
      return File(path);
    }
  }

  Future<String> _copyStoryMedia(String id, String sourcePath) async {
    File? dest;
    try {
      final dir = await _storyUploadsDir();
      await dir.create(recursive: true);
      final name = _fileName(sourcePath);
      final dot = name.lastIndexOf('.');
      final ext = dot > 0 ? name.substring(dot) : '';
      dest = File('${dir.path}/$id$ext');
      await File(sourcePath).copy(dest.path);
      return dest.path;
    } catch (e) {
      if (dest != null) await _deleteStoryFile(dest.path);
      throw StoryUploadQueueException('could not copy the story media: $e');
    }
  }

  /// Deletes a story task's private copy. Never touches a file outside the
  /// uploads folder (a task from an older release points at the user's own
  /// file).
  Future<void> _deleteStoryCopy(UploadTask task) async {
    if (!task.isStory) return;
    final path = task.metadata['mediaPath'];
    if (path is! String || !path.contains('/$storyUploadsFolder/')) return;
    try {
      await _deleteStoryFile((await _currentStoryFile(path)).path);
    } catch (_) {}
  }

  Future<void> _deleteStoryFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Subscribed to connectivity only while a story task could use it.
  void _syncStoryConnectivity() {
    final wanted = _tasks.any((t) =>
        t.isStory &&
        (t.isActive ||
            (t.status == UploadStatus.failed &&
                t.storyFailure == StoryUploadFailure.failed)));
    if (wanted && _connectivitySubscription == null) {
      try {
        _connectivitySubscription = connectivityChanges()
            .listen(_onConnectivityChanged, onError: (_) {});
      } catch (_) {
        // Plugin missing (tests, unsupported platform): timers still retry.
      }
    } else if (!wanted && _connectivitySubscription != null) {
      _connectivitySubscription!.cancel();
      _connectivitySubscription = null;
      _wasOffline = false;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) {
      _wasOffline = true;
      return;
    }
    if (!_wasOffline) return;
    _wasOffline = false;
    _retryStoriesOnReconnect();
  }

  /// Back online: each story task waiting after an ordinary failure, or
  /// failed by one, gets one attempt now. Not a task in flight, not a 429,
  /// not a missing file, not one the server says is still uploading.
  void _retryStoriesOnReconnect() {
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (!t.isStory) continue;
      final m = t.metadata;
      if (t.status == UploadStatus.queued && m[_kWaitReason] == _waitForFailure) {
        m.remove(_kNextAttemptAt);
        m.remove(_kWaitReason);
        changed = true;
      } else if (t.status == UploadStatus.failed &&
          t.storyFailure == StoryUploadFailure.failed) {
        m.remove(kStoryFailureKey);
        _tasks[i] = t.copyWith(status: UploadStatus.queued, progress: 0.0);
        changed = true;
      }
    }
    if (!changed) return;
    _notifyTasksChanged();
    _saveTasks();
    _processQueue();
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
    _syncStoryConnectivity();
  }

  /// Resume failed uploads on init
  void _resumeFailedUploads() {
    // Reset any uploads that were in progress when app closed
    for (var i = 0; i < _tasks.length; i++) {
      // A story queued while initialize() ran may already be on the wire:
      // resetting it would drop that attempt's answer and send it again.
      if (_storyAttemptsInFlight.contains(_tasks[i].id)) continue;
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
    }
  }

  /// Load tasks from persistent storage
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString(_storageKey);
      if (tasksString != null) {
        final tasksList = jsonDecode(tasksString) as List;
        final loaded = tasksList.map((t) => UploadTask.fromJson(t)).toList();
        // A task queued while this load was reading prefs is kept: a story
        // posted as the queue starts up must not vanish from memory (and
        // have its private copy swept as an orphan).
        final loadedIds = loaded.map((t) => t.id).toSet();
        final queuedMeanwhile =
            _tasks.where((t) => !loadedIds.contains(t.id)).toList();
        _tasks.clear();
        _tasks.addAll(loaded);
        _tasks.addAll(queuedMeanwhile);

        // Remove very old completed tasks (older than 24 hours)
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        _tasks.removeWhere((t) =>
            t.status == UploadStatus.completed &&
            t.completedAt != null &&
            t.completedAt!.isBefore(cutoff));

        _notifyTasksChanged();
      }
    } catch (e) {
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _tasksController.close();
    _storyPostedController.close();
    _storyWakeTimer?.cancel();
    _storyWakeTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}

/// Thrown inside an upload when [UploadQueueService.endSession] ran.
class _SessionEnded implements Exception {}
