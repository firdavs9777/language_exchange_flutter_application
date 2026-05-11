import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../models/call_model.dart';
import 'livekit_service.dart';

/// Transport layer that adapts the LiveKit SDK to the n=2 (1:1 call) shape.
///
/// `call_manager.dart` will be rewritten (task B3) to delegate room transport
/// to an instance of this class while preserving its current public API to
/// the UI. The manager remains responsible for higher-level call lifecycle
/// (signalling via socket, ringtones, duration limits, CallKit, VIP rules);
/// this class is purely about the LiveKit room.
///
/// Compared to `VoiceRoomLiveKitManager`, this class:
///   - caches the *single* expected RemoteParticipant as [_remotePeer]
///   - exposes peer mute / peer video / connection-quality / reconnect
///     callbacks instead of collection deltas
///   - surfaces [localVideoTrack] / [remoteVideoTrack] getters so the
///     future ActiveCallScreen rewrite (B4) can feed them directly to
///     [VideoTrackRenderer] without reaching through [Room].
///
/// On a 1:1 call, [ParticipantDisconnectedEvent] does *not* clear
/// [_remotePeer] — the caller decides whether to retain the reference
/// for a "reconnecting" UI or tear down. [disconnect] clears it.
class CallLiveKitManager {
  CallLiveKitManager({LiveKitService? livekit})
      : _livekit = livekit ?? LiveKitService();

  final LiveKitService _livekit;
  EventsListener<RoomEvent>? _listener;
  RemoteParticipant? _remotePeer;

  // -- Callbacks ------------------------------------------------------------

  /// Fired when the remote peer joins the room. For 1:1 this fires at most
  /// once per [connect] call (modulo reconnects creating a new participant
  /// session — rare).
  void Function()? onPeerConnected;

  /// Fired when the cached [_remotePeer] disconnects. Field is *not* cleared
  /// so callers can keep showing peer's avatar / name during a brief outage.
  void Function()? onPeerDisconnected;

  /// Audio-track mute state of the remote peer changed.
  void Function(bool muted)? onPeerMuteChanged;

  /// Video on/off for the remote peer. Driven by
  /// `TrackSubscribed` / `TrackUnsubscribed` for the video kind — these
  /// fire reliably on our side regardless of who publishes, with
  /// `autoSubscribe: true` (set in [LiveKitService.connect]).
  void Function(bool enabled)? onPeerVideoChanged;

  /// Connection quality update for the remote peer (`excellent`, `good`,
  /// `poor`, `lost`). Updates for the local participant are ignored.
  void Function(ConnectionQuality)? onConnectionQualityChanged;

  /// Local room transport is attempting to reconnect to LiveKit.
  void Function()? onReconnecting;

  /// Local room transport finished reconnecting.
  void Function()? onReconnected;

  /// Local room transport has fully disconnected (terminal). Distinct
  /// from [onPeerDisconnected].
  void Function()? onLocalDisconnected;

  // -- Getters --------------------------------------------------------------

  Room? get room => _livekit.room;
  RemoteParticipant? get remotePeer => _remotePeer;
  bool get isConnected => _livekit.isConnected;

  /// First published local video track if any, else null. For B4's
  /// self-preview tile via [VideoTrackRenderer].
  VideoTrack? get localVideoTrack {
    final pubs = _livekit.room?.localParticipant?.videoTrackPublications;
    if (pubs == null) return null;
    for (final pub in pubs) {
      final t = pub.track;
      if (t is VideoTrack) return t;
    }
    return null;
  }

  /// First subscribed remote video track from [_remotePeer] if any. For
  /// B4's main remote-video tile via [VideoTrackRenderer]. Returns null
  /// while peer's camera is off / not yet subscribed.
  VideoTrack? get remoteVideoTrack {
    final pubs = _remotePeer?.videoTrackPublications;
    if (pubs == null) return null;
    for (final pub in pubs) {
      final t = pub.track;
      if (t is VideoTrack) return t;
    }
    return null;
  }

  // -- API ------------------------------------------------------------------

  /// Connect to the LiveKit room and wire room events. Audio calls publish
  /// mic only; video calls publish both mic and camera.
  Future<void> connect({
    required String url,
    required String token,
    required CallType type,
  }) async {
    await _livekit.connect(
      url: url,
      token: token,
      enableMicrophone: true,
      enableCamera: type == CallType.video,
    );

    _wireRoomEvents();

    // It's possible (rare for 1:1) the peer is already in the room when we
    // join — e.g. recovery flow or a stale room. ParticipantConnectedEvent
    // only fires for *future* joins, so we have to seed from snapshot.
    final r = _livekit.room;
    if (r != null && r.remoteParticipants.isNotEmpty) {
      final peer = r.remoteParticipants.values.first;
      _remotePeer = peer;
      onPeerConnected?.call();
    }
  }

  /// Mute/unmute the local microphone. [muted] == true mutes.
  Future<void> setMuted(bool muted) async {
    await _livekit.setMicrophoneEnabled(!muted);
  }

  /// Enable/disable the local camera (publishes/unpublishes the video track).
  Future<void> setCameraEnabled(bool enabled) async {
    await _livekit.setCameraEnabled(enabled);
  }

  /// Tear down the listener and disconnect from the LiveKit room. Clears
  /// the cached [_remotePeer].
  Future<void> disconnect() async {
    await _listener?.dispose();
    _listener = null;
    _remotePeer = null;
    await _livekit.disconnect();
  }

  // -- Internal -------------------------------------------------------------

  void _wireRoomEvents() {
    final r = _livekit.room;
    if (r == null) {
      debugPrint('CallLiveKitManager: room null after connect, skipping wire');
      return;
    }

    final l = r.createListener();
    _listener = l;

    l.on<ParticipantConnectedEvent>((event) {
      _remotePeer = event.participant;
      onPeerConnected?.call();
    });

    l.on<ParticipantDisconnectedEvent>((event) {
      // Only signal if it's the participant we've been tracking. Do NOT
      // clear the field — caller decides whether to keep showing the
      // peer during a reconnect window.
      if (event.participant.identity == _remotePeer?.identity) {
        onPeerDisconnected?.call();
      }
    });

    // Audio mute/unmute on the peer side.
    l.on<TrackMutedEvent>((event) {
      if (event.publication.kind == TrackType.AUDIO &&
          event.participant.identity == _remotePeer?.identity) {
        onPeerMuteChanged?.call(true);
      }
    });

    l.on<TrackUnmutedEvent>((event) {
      if (event.publication.kind == TrackType.AUDIO &&
          event.participant.identity == _remotePeer?.identity) {
        onPeerMuteChanged?.call(false);
      }
    });

    // Peer video on/off. With autoSubscribe=true (LiveKitService default)
    // TrackSubscribed fires reliably on the remote side once the
    // subscription is set up, which is the right "I can render this"
    // signal for the UI. TrackUnsubscribed is the mirror.
    l.on<TrackSubscribedEvent>((event) {
      if (event.publication.kind == TrackType.VIDEO &&
          event.participant.identity == _remotePeer?.identity) {
        onPeerVideoChanged?.call(true);
      }
    });

    l.on<TrackUnsubscribedEvent>((event) {
      if (event.publication.kind == TrackType.VIDEO &&
          event.participant.identity == _remotePeer?.identity) {
        onPeerVideoChanged?.call(false);
      }
    });

    // Connection quality (per-participant in LiveKit). We only surface
    // updates for the remote peer — the local quality is monitored by
    // the room itself and rarely useful at the call-screen level.
    l.on<ParticipantConnectionQualityUpdatedEvent>((event) {
      if (event.participant.identity == _remotePeer?.identity) {
        onConnectionQualityChanged?.call(event.connectionQuality);
      }
    });

    l.on<RoomReconnectingEvent>((_) => onReconnecting?.call());
    l.on<RoomReconnectedEvent>((_) => onReconnected?.call());
    l.on<RoomDisconnectedEvent>((_) => onLocalDisconnected?.call());
  }
}
