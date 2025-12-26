enum CallType { audio, video }

enum CallDirection { incoming, outgoing }

enum CallStatus {
  ringing,
  connecting,
  connected,
  ended,
  rejected,
  missed,
  failed
}

class CallModel {
  final String callId;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final CallType callType;
  final CallDirection direction;
  CallStatus status;
  final DateTime startTime;
  DateTime? endTime;
  int? duration; // Duration in seconds

  CallModel({
    required this.callId,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.callType,
    required this.direction,
    this.status = CallStatus.ringing,
    required this.startTime,
    this.endTime,
    this.duration,
  });

  factory CallModel.fromJson(
    Map<String, dynamic> json,
    CallDirection direction,
  ) {
    String userId;
    String userName;
    String? userProfilePicture;

    if (direction == CallDirection.incoming) {
      final caller = json['caller'] as Map<String, dynamic>?;
      userId = caller?['_id']?.toString() ?? json['callerId']?.toString() ?? '';
      userName = caller?['name']?.toString() ?? json['callerName']?.toString() ?? 'Unknown';
      userProfilePicture = caller?['profilePicture']?.toString() ?? 
                          caller?['image']?.toString() ?? 
                          json['callerProfilePicture']?.toString();
    } else {
      final recipient = json['recipient'] as Map<String, dynamic>?;
      userId = recipient?['_id']?.toString() ?? json['recipientId']?.toString() ?? '';
      userName = recipient?['name']?.toString() ?? json['recipientName']?.toString() ?? 'Unknown';
      userProfilePicture = recipient?['profilePicture']?.toString() ?? 
                          recipient?['image']?.toString() ?? 
                          json['recipientProfilePicture']?.toString();
    }

    return CallModel(
      callId: json['callId']?.toString() ?? json['_id']?.toString() ?? '',
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
      callType: json['callType'] == 'video' ? CallType.video : CallType.audio,
      direction: direction,
      status: CallStatus.ringing,
      startTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'callType': callType == CallType.video ? 'video' : 'audio',
      'direction': direction == CallDirection.incoming ? 'incoming' : 'outgoing',
      'status': status.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
    };
  }

  CallModel copyWith({
    String? callId,
    String? userId,
    String? userName,
    String? userProfilePicture,
    CallType? callType,
    CallDirection? direction,
    CallStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      callType: callType ?? this.callType,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
    );
  }
}

