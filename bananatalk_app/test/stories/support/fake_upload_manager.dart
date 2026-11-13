import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/upload_task.dart';
import 'package:bananatalk_app/providers/upload_manager_provider.dart';
import 'package:bananatalk_app/services/story_upload_payload.dart';
import 'package:bananatalk_app/services/upload_queue_service.dart';

/// An upload manager whose tasks the test sets directly and whose queue /
/// retry / remove calls are recorded instead of sent. No network, no timers.
class FakeUploadManager extends UploadManagerNotifier {
  FakeUploadManager() : super(UploadQueueService());

  final queued = <StoryUploadPayload>[];
  final retried = <String>[];
  final removed = <String>[];
  Object? queueError;

  /// The base class initialises asynchronously and then writes its own (empty)
  /// task list; wait for that, then the test's tasks stay.
  Future<void> ready() async {
    while (!state.isInitialized) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  void setTasks(List<UploadTask> tasks) =>
      state = state.copyWith(tasks: tasks, isInitialized: true);

  @override
  Future<String> queueStoryUpload(StoryUploadPayload payload) async {
    final e = queueError;
    if (e != null) throw e;
    queued.add(payload);
    return 'task-${queued.length}';
  }

  @override
  Future<void> retryUpload(String taskId) async => retried.add(taskId);

  @override
  Future<void> removeTask(String taskId) async => removed.add(taskId);
}

/// Points the real queue's device seams at throwaway fakes so creating a
/// [FakeUploadManager] never touches a plugin.
Future<void> useFakeQueueSeams() async {
  final docs = await Directory.systemTemp.createTemp('ring-docs');
  UploadQueueService.documentsDirectory = () async => docs;
  UploadQueueService.connectivityChanges =
      () => StreamController<List<ConnectivityResult>>.broadcast().stream;
  addTearDown(() {
    UploadQueueService.resetStorySeamsForTest();
    docs.deleteSync(recursive: true);
  });
}

UploadTask storyTask(
  UploadStatus status, {
  String id = 't1',
  String? owner = 'me',
  StoryUploadFailure? failure,
}) =>
    UploadTask(
      id: id,
      type: UploadType.story,
      localFilePath: '',
      status: status,
      metadata: {
        'ownerUserId': owner,
        if (failure != null) kStoryFailureKey: failure.name,
      },
    );
