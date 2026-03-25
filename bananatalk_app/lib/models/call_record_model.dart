import 'package:bananatalk_app/models/call_model.dart';

enum CallRecordStatus { answered, missed, rejected }

class CallParticipant {
  final String id;
  final String name;
  final String? profilePicture;

  const CallParticipant({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      profilePicture: json['profilePicture']?.toString() ?? json['image']?.toString(),
    );
  }
}

class CallRecord {
  final String id;
  final List<CallParticipant> participants;
  final CallType type;
  final CallRecordStatus status;
  final int? duration; // seconds
  final DateTime startTime;
  final DateTime? endTime;
  final String initiatorId;
  final CallDirection direction;

  const CallRecord({
    required this.id,
    required this.participants,
    required this.type,
    required this.status,
    this.duration,
    required this.startTime,
    this.endTime,
    required this.initiatorId,
    required this.direction,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determine direction based on initiator
    final initiatorId = json['initiator']?.toString() ?? '';
    final direction = initiatorId == currentUserId
        ? CallDirection.outgoing
        : CallDirection.incoming;

    // Parse status
    CallRecordStatus status;
    final statusStr = json['status']?.toString() ?? '';
    switch (statusStr) {
      case 'answered':
      case 'ended':
        status = CallRecordStatus.answered;
      case 'missed':
        status = CallRecordStatus.missed;
      case 'rejected':
        status = CallRecordStatus.rejected;
      default:
        status = CallRecordStatus.answered;
    }

    return CallRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      participants: (json['participants'] as List? ?? [])
          .map((p) => CallParticipant.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      type: json['type'] == 'video' ? CallType.video : CallType.audio,
      status: status,
      duration: json['duration'] as int?,
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ??
          DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
      initiatorId: initiatorId,
      direction: direction,
    );
  }

  /// Get the other participant (for 1-on-1 calls)
  CallParticipant? getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  /// Format duration as mm:ss or hh:mm:ss
  String get formattedDuration {
    if (duration == null) return '';
    final d = Duration(seconds: duration!);
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
