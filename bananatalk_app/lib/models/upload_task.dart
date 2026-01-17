import 'package:uuid/uuid.dart';

/// Type of upload task
enum UploadType {
  moment,
  momentVideo,
  story,
  storyVideo,
}

/// Status of upload task
enum UploadStatus {
  queued,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
}

/// Represents a file upload task for background processing
class UploadTask {
  final String id;
  final UploadType type;
  final String localFilePath;
  final Map<String, dynamic> metadata;
  UploadStatus status;
  double progress;
  final DateTime createdAt;
  DateTime? completedAt;
  String? error;
  String? resultId; // ID of created moment/story after successful upload
  int retryCount;

  UploadTask({
    String? id,
    required this.type,
    required this.localFilePath,
    Map<String, dynamic>? metadata,
    this.status = UploadStatus.queued,
    this.progress = 0.0,
    DateTime? createdAt,
    this.completedAt,
    this.error,
    this.resultId,
    this.retryCount = 0,
  })  : id = id ?? const Uuid().v4(),
        metadata = metadata ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// Create from JSON (for persistence)
  factory UploadTask.fromJson(Map<String, dynamic> json) {
    return UploadTask(
      id: json['id'] as String,
      type: UploadType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => UploadType.moment,
      ),
      localFilePath: json['localFilePath'] as String,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
      status: UploadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UploadStatus.queued,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      error: json['error'] as String?,
      resultId: json['resultId'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  /// Convert to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'localFilePath': localFilePath,
      'metadata': metadata,
      'status': status.name,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'error': error,
      'resultId': resultId,
      'retryCount': retryCount,
    };
  }

  /// Create a copy with updated fields
  UploadTask copyWith({
    UploadStatus? status,
    double? progress,
    DateTime? completedAt,
    String? error,
    String? resultId,
    int? retryCount,
  }) {
    return UploadTask(
      id: id,
      type: type,
      localFilePath: localFilePath,
      metadata: metadata,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
      resultId: resultId ?? this.resultId,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Check if task is active (not finished)
  bool get isActive =>
      status == UploadStatus.queued ||
      status == UploadStatus.uploading ||
      status == UploadStatus.processing;

  /// Check if task is for video content
  bool get isVideo =>
      type == UploadType.momentVideo || type == UploadType.storyVideo;

  /// Get display name for task type
  String get typeName {
    switch (type) {
      case UploadType.moment:
        return 'Moment';
      case UploadType.momentVideo:
        return 'Moment Video';
      case UploadType.story:
        return 'Story';
      case UploadType.storyVideo:
        return 'Story Video';
    }
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case UploadStatus.queued:
        return 'Waiting...';
      case UploadStatus.uploading:
        return 'Uploading ${(progress * 100).toInt()}%';
      case UploadStatus.processing:
        return 'Processing...';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  String toString() {
    return 'UploadTask(id: $id, type: $type, status: $status, progress: $progress)';
  }
}

/// Progress update for an upload task
class UploadProgress {
  final String taskId;
  final double progress;
  final UploadStatus status;
  final String? message;

  UploadProgress({
    required this.taskId,
    required this.progress,
    required this.status,
    this.message,
  });
}
