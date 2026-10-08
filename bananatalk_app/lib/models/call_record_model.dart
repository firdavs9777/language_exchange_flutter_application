import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/utils/string_sanitizer.dart';

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
      name: sanitize(json['name'], 'Unknown'),
      profilePicture:
          json['profilePicture']?.toString() ?? json['image']?.toString(),
    );
  }
}

/// A call as embedded in a chat message (`media.callData`). The server
/// writes a superset that live builds also read, so every field here
/// tolerates the old shape.
class CallRecord {
  final String id;
  final String? callUuid;
  final List<CallParticipant> participants;
  final CallType type;
  final CallRecordStatus status;
  final CallOutcome? outcome;
  final int? duration; // whole seconds
  final DateTime startTime;
  final DateTime? endTime;
  final String initiatorId;
  final CallDirection direction;

  const CallRecord({
    required this.id,
    this.callUuid,
    required this.participants,
    required this.type,
    required this.status,
    this.outcome,
    this.duration,
    required this.startTime,
    this.endTime,
    required this.initiatorId,
    required this.direction,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json, String currentUserId) {
    final initiatorId = json['initiator']?.toString() ?? '';
    final statusStr = json['status']?.toString() ?? '';
    final CallRecordStatus status;
    switch (statusStr) {
      case 'missed':
        status = CallRecordStatus.missed;
      case 'rejected':
        status = CallRecordStatus.rejected;
      default:
        status = CallRecordStatus.answered;
    }
    final rawParticipants = json['participants'];
    return CallRecord(
      id: json['callId']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      callUuid: json['callUuid']?.toString(),
      participants: rawParticipants is List
          ? rawParticipants
              .whereType<Map>()
              .map((p) => CallParticipant.fromJson(Map<String, dynamic>.from(p)))
              .toList()
          : const [],
      type: json['type'] == 'video' ? CallType.video : CallType.audio,
      status: status,
      outcome: callOutcomeFromWire(json['outcome']?.toString()) ??
          legacyCallOutcome(statusStr),
      duration: (json['duration'] as num?)?.floor(),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ??
          DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
      initiatorId: initiatorId,
      direction: initiatorId == currentUserId
          ? CallDirection.outgoing
          : CallDirection.incoming,
    );
  }

  CallParticipant? getOtherParticipant(String currentUserId) {
    if (participants.isEmpty) return null;
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  String get formattedDuration =>
      duration == null ? '' : formatCallDuration(duration!);
}

/// One row of `GET /calls` (spec §4.7). Labels are derived client-side.
class CallLogEntry {
  final String id;
  final String? callUuid;
  final CallType type;
  final CallDirection direction;
  final CallOutcome outcome;
  final int duration;
  final String otherId;
  final String otherName;
  final String? otherAvatar;
  final DateTime createdAt;

  const CallLogEntry({
    required this.id,
    this.callUuid,
    required this.type,
    required this.direction,
    required this.outcome,
    required this.duration,
    required this.otherId,
    required this.otherName,
    this.otherAvatar,
    required this.createdAt,
  });

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    final other = json['otherParty'] is Map
        ? Map<String, dynamic>.from(json['otherParty'] as Map)
        : const <String, dynamic>{};
    return CallLogEntry(
      id: json['id']?.toString() ?? '',
      callUuid: json['callUuid']?.toString(),
      type: json['type'] == 'video' ? CallType.video : CallType.audio,
      direction: json['direction'] == 'out'
          ? CallDirection.outgoing
          : CallDirection.incoming,
      outcome: callOutcomeFromWire(json['outcome']?.toString()) ??
          CallOutcome.completed,
      duration: (json['duration'] as num?)?.floor() ?? 0,
      otherId: other['id']?.toString() ?? '',
      otherName: sanitize(other['name'], 'Unknown'),
      otherAvatar: other['avatar']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
