import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import 'package:bananatalk_app/services/livekit_service.dart';

/// Smoke-test screen for LiveKit.
///
/// 1. Tap "Connect" → backend mints a token, we join the `smoke-test` room
/// 2. Local participant card shows your name + mic/cam state
/// 3. Each remote participant gets a card automatically
/// 4. Open this screen on a second device with a second account to verify
///    audio (and optional video) flows end-to-end.
class LiveKitTestScreen extends StatefulWidget {
  const LiveKitTestScreen({super.key});

  @override
  State<LiveKitTestScreen> createState() => _LiveKitTestScreenState();
}

class _LiveKitTestScreenState extends State<LiveKitTestScreen> {
  final LiveKitService _service = LiveKitService();

  String _status = 'idle';
  String? _error;
  bool _busy = false;
  bool _micEnabled = true;
  bool _camEnabled = false;
  String? _roomName;

  EventsListener<RoomEvent>? _listener;

  @override
  void dispose() {
    _listener?.dispose();
    _service.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _status = 'fetching token…';
      _error = null;
    });
    try {
      final t = await _service.fetchTestToken();
      setState(() {
        _status = 'connecting to ${t.roomName}…';
        _roomName = t.roomName;
      });
      await _service.connect(
        url: t.url,
        token: t.token,
        enableMicrophone: _micEnabled,
        enableCamera: _camEnabled,
      );

      // Listen to room events so the participant list re-renders on join/leave.
      _listener = _service.room!.createListener()
        ..on<ParticipantConnectedEvent>((_) => setState(() {}))
        ..on<ParticipantDisconnectedEvent>((_) => setState(() {}))
        ..on<TrackSubscribedEvent>((_) => setState(() {}))
        ..on<TrackUnsubscribedEvent>((_) => setState(() {}))
        ..on<TrackMutedEvent>((_) => setState(() {}))
        ..on<TrackUnmutedEvent>((_) => setState(() {}))
        ..on<LocalTrackPublishedEvent>((_) => setState(() {}))
        ..on<LocalTrackUnpublishedEvent>((_) => setState(() {}))
        ..on<RoomDisconnectedEvent>((_) {
          setState(() => _status = 'disconnected');
        });

      setState(() => _status = 'connected');
    } catch (e) {
      setState(() {
        _status = 'error';
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await _service.disconnect();
    _listener?.dispose();
    _listener = null;
    if (!mounted) return;
    setState(() {
      _status = 'idle';
      _busy = false;
    });
  }

  Future<void> _toggleMic() async {
    final next = !_micEnabled;
    await _service.setMicrophoneEnabled(next);
    setState(() => _micEnabled = next);
  }

  Future<void> _toggleCam() async {
    final next = !_camEnabled;
    await _service.setCameraEnabled(next);
    setState(() => _camEnabled = next);
  }

  @override
  Widget build(BuildContext context) {
    final room = _service.room;
    final remotes = room?.remoteParticipants.values.toList() ?? const [];
    final connected = _service.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveKit smoke test'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(
                status: _status,
                roomName: _roomName,
                error: _error,
                participantCount: connected ? remotes.length + 1 : 0,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : (connected ? _disconnect : _connect),
                      icon: Icon(connected ? Icons.call_end : Icons.call),
                      label: Text(connected ? 'Disconnect' : 'Connect'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: connected ? _toggleMic : null,
                    icon: Icon(_micEnabled ? Icons.mic : Icons.mic_off),
                    tooltip: 'Toggle mic',
                  ),
                  IconButton.filledTonal(
                    onPressed: connected ? _toggleCam : null,
                    icon: Icon(
                      _camEnabled ? Icons.videocam : Icons.videocam_off,
                    ),
                    tooltip: 'Toggle camera',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (connected) ...[
                Text('You',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                _LocalParticipantCard(
                  participant: room!.localParticipant!,
                  micEnabled: _micEnabled,
                  camEnabled: _camEnabled,
                ),
                const SizedBox(height: 16),
                Text(
                  'Remote participants (${remotes.length})',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: remotes.isEmpty
                      ? const Center(
                          child: Text(
                            'Waiting for another participant…\n'
                            'Open this screen on a second device.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: remotes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _RemoteParticipantCard(
                            participant: remotes[i],
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.roomName,
    required this.error,
    required this.participantCount,
  });

  final String status;
  final String? roomName;
  final String? error;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == 'connected'
                      ? Icons.check_circle
                      : (status == 'error'
                          ? Icons.error
                          : Icons.radio_button_unchecked),
                  size: 18,
                  color: status == 'connected'
                      ? Colors.green
                      : (status == 'error' ? Colors.red : null),
                ),
                const SizedBox(width: 8),
                Text('Status: $status'),
              ],
            ),
            if (roomName != null) ...[
              const SizedBox(height: 4),
              Text('Room: $roomName'),
            ],
            if (participantCount > 0) ...[
              const SizedBox(height: 4),
              Text('Participants: $participantCount'),
            ],
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocalParticipantCard extends StatelessWidget {
  const _LocalParticipantCard({
    required this.participant,
    required this.micEnabled,
    required this.camEnabled,
  });

  final LocalParticipant participant;
  final bool micEnabled;
  final bool camEnabled;

  @override
  Widget build(BuildContext context) {
    final videoTrack = participant.videoTrackPublications
        .where((p) => p.track != null)
        .map((p) => p.track)
        .whereType<VideoTrack>()
        .firstOrNull;

    return _ParticipantCard(
      label: participant.name.isNotEmpty
          ? '${participant.name} (you)'
          : '${participant.identity} (you)',
      micEnabled: micEnabled,
      camEnabled: camEnabled,
      videoTrack: videoTrack,
      isSpeaking: participant.isSpeaking,
    );
  }
}

class _RemoteParticipantCard extends StatelessWidget {
  const _RemoteParticipantCard({required this.participant});

  final RemoteParticipant participant;

  @override
  Widget build(BuildContext context) {
    final hasAudio = participant.audioTrackPublications
        .any((p) => p.subscribed && !p.muted);
    final videoTrack = participant.videoTrackPublications
        .where((p) => p.track != null && p.subscribed)
        .map((p) => p.track)
        .whereType<VideoTrack>()
        .firstOrNull;

    return _ParticipantCard(
      label: participant.name.isNotEmpty
          ? participant.name
          : participant.identity,
      micEnabled: hasAudio,
      camEnabled: videoTrack != null,
      videoTrack: videoTrack,
      isSpeaking: participant.isSpeaking,
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.label,
    required this.micEnabled,
    required this.camEnabled,
    required this.videoTrack,
    required this.isSpeaking,
  });

  final String label;
  final bool micEnabled;
  final bool camEnabled;
  final VideoTrack? videoTrack;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSpeaking ? Colors.green : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            SizedBox(
              width: 160,
              height: 120,
              child: videoTrack != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: VideoTrackRenderer(videoTrack!),
                    )
                  : Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.person, size: 48),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(micEnabled ? Icons.mic : Icons.mic_off,
                            size: 18),
                        const SizedBox(width: 12),
                        Icon(
                          camEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
