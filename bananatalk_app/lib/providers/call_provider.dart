import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call_manager.dart'
    show CallManager, CallUiState, CallQuality;

class CallNotifier extends ChangeNotifier {
  final CallManager _callManager = CallManager();

  CallModel? get currentCall => _callManager.currentCall;
  bool get isInCall => currentCall != null;
  bool get isMuted => _callManager.isMuted;
  bool get isVideoEnabled => _callManager.isVideoEnabled;
  bool get isSpeakerOn => _callManager.isSpeakerOn;
  CallUiState get connectionState => _callManager.connectionState;
  CallQuality get callQuality => _callManager.callQuality;

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

  void setCallConnectedCallback(Function(CallModel) callback) {
    _callManager.onCallConnected = (call) {
      callback(call);
      notifyListeners();
    };
  }

  void setCallErrorCallback(Function(String) callback) {
    _callManager.onCallError = callback;
  }

  void setConnectionStateCallback(Function(CallUiState) callback) {
    _callManager.onConnectionStateChanged = (state) {
      callback(state);
      notifyListeners();
    };
  }

  void setCallQualityCallback(Function(CallQuality) callback) {
    _callManager.onCallQualityChanged = (quality) {
      callback(quality);
      notifyListeners();
    };
  }

  void setCallDurationWarningCallback(Function(int remainingSeconds) callback) {
    _callManager.onCallDurationWarning = callback;
  }

  void setCallDurationLimitCallback(Function() callback) {
    _callManager.onCallDurationLimitReached = callback;
  }

  /// Set whether the current caller is VIP (no duration limit)
  void setVipCall(bool isVip) {
    _callManager.setVipCall(isVip);
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

  Future<void> toggleSpeaker() async {
    await _callManager.toggleSpeaker();
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

