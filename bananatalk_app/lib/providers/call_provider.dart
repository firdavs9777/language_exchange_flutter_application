import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call_manager.dart';

class CallNotifier extends ChangeNotifier {
  final CallManager _callManager = CallManager();

  CallModel? get currentCall => _callManager.currentCall;
  bool get isInCall => currentCall != null;
  bool get isMuted => _callManager.isMuted;
  bool get isVideoEnabled => _callManager.isVideoEnabled;

  CallManager get callManager => _callManager;

  void setIncomingCallCallback(Function(CallModel) callback) {
    _callManager.onIncomingCall = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallAcceptedCallback(Function(CallModel) callback) {
    _callManager.onCallAccepted = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallRejectedCallback(Function(CallModel) callback) {
    _callManager.onCallRejected = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallEndedCallback(Function(CallModel) callback) {
    _callManager.onCallEnded = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallErrorCallback(Function(String) callback) {
    _callManager.onCallError = callback;
  }

  Future<void> initiateCall(
    String targetUserId,
    String targetUserName,
    String? targetUserProfilePicture,
    CallType callType,
  ) async {
    await _callManager.initiateCall(
      targetUserId,
      targetUserName,
      targetUserProfilePicture,
      callType,
    );
    notifyListeners();
  }

  Future<void> acceptCall() async {
    await _callManager.acceptCall();
    notifyListeners();
  }

  void rejectCall() {
    _callManager.rejectCall();
    notifyListeners();
  }

  void endCall() {
    _callManager.endCall();
    notifyListeners();
  }

  void toggleMute() {
    _callManager.toggleMute();
    notifyListeners();
  }

  void toggleVideo() {
    _callManager.toggleVideo();
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _callManager.switchCamera();
  }

  @override
  void dispose() {
    _callManager.dispose();
    super.dispose();
  }
}

final callProvider = ChangeNotifierProvider<CallNotifier>((ref) {
  return CallNotifier();
});

