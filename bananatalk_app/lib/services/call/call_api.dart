import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// Result of a call REST request, with the server's machine-readable codes.
class CallApiResult {
  const CallApiResult({
    required this.ok,
    required this.statusCode,
    this.errorCode,
    this.error,
    this.data = const {},
  });

  factory CallApiResult.fromResponse(ApiResponse r) => CallApiResult(
        ok: r.success,
        statusCode: r.statusCode,
        errorCode: r.errorCode,
        error: r.error,
        data: r.data is Map
            ? Map<String, dynamic>.from(r.data as Map)
            : const <String, dynamic>{},
      );

  final bool ok;
  final int statusCode;
  final String? errorCode;
  final String? error;
  final Map<String, dynamic> data;

  /// Another device (or the timeout) won the race: dismiss silently.
  bool get isCallStateConflict => statusCode == 409 && errorCode == 'CALL_STATE';
  bool get isCalleeBusy => statusCode == 409 && errorCode == 'CALLEE_BUSY';
  bool get isCallerBusy => statusCode == 409 && errorCode == 'CALLER_BUSY';
}

abstract class CallApi {
  Future<CallApiResult> initiate({required String receiverId, required CallType type});
  Future<CallApiResult> accept(String callId, {String? deviceId});
  Future<CallApiResult> decline(String callId, {String? deviceId});
  Future<CallApiResult> end(String callId);
  Future<CallApiResult> current();
  Future<CallApiResult> get(String callId);
}

class RestCallApi implements CallApi {
  RestCallApi([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;

  Map<String, dynamic> _device(String? deviceId) =>
      {if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId};

  @override
  Future<CallApiResult> initiate({required String receiverId, required CallType type}) async =>
      CallApiResult.fromResponse(await _client.post('calls/initiate',
          body: {'receiverId': receiverId, 'type': type.name}));

  @override
  Future<CallApiResult> accept(String callId, {String? deviceId}) async =>
      CallApiResult.fromResponse(
          await _client.post('calls/$callId/accept', body: _device(deviceId)));

  @override
  Future<CallApiResult> decline(String callId, {String? deviceId}) async =>
      CallApiResult.fromResponse(
          await _client.post('calls/$callId/decline', body: _device(deviceId)));

  @override
  Future<CallApiResult> end(String callId) async =>
      CallApiResult.fromResponse(await _client.post('calls/$callId/end'));

  @override
  Future<CallApiResult> current() async =>
      CallApiResult.fromResponse(await _client.get('calls/current'));

  @override
  Future<CallApiResult> get(String callId) async =>
      CallApiResult.fromResponse(await _client.get('calls/$callId'));
}
