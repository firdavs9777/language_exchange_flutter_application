import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/tutor_voice_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Roleplay chat — almost the same as TutorChatScreen but:
/// - Shows the scenario goal banner at the top
/// - End-scenario button surfaces the scoreboard sheet
/// - Forces text-only chat (cards aren't allowed in roleplay anyway,
///   server enforces this)
class RoleplayChatScreen extends ConsumerStatefulWidget {
  final TutorScenario scenario;
  const RoleplayChatScreen({super.key, required this.scenario});

  @override
  ConsumerState<RoleplayChatScreen> createState() => _RoleplayChatScreenState();
}

class _RoleplayChatScreenState extends ConsumerState<RoleplayChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtl = ScrollController();
  final _voice = TutorVoiceService();
  bool _voiceMode = false;
  bool _recording = false;
  bool _transcribing = false;
  bool _ending = false;
  bool _starting = true;
  int _lastSpokenIndex = -1;

  @override
  void initState() {
    super.initState();
    // Start the session here (instead of in the picker) so the screen's
    // own ref.watch keeps tutorChatControllerProvider alive — the picker
    // doesn't watch it, so starting there raced against autoDispose and
    // the new screen would mount with a fresh empty notifier.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref
            .read(tutorChatControllerProvider.notifier)
            .startRoleplay(widget.scenario.id);
        if (!mounted) return;
        setState(() => _starting = false);
        _scrollToBottom();
      } catch (e) {
        if (!mounted) return;
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start: $e')),
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(
          _scrollCtl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final notifier = ref.read(tutorChatControllerProvider.notifier);
    if (notifier.state.session == null) {
      // Start hasn't finished yet — block send rather than silently
      // swallowing the user's text.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still starting the scenario — try again in a moment.')),
      );
      return;
    }
    _controller.clear();
    await notifier.send(text);
    if (!mounted) return;
    final err = ref.read(tutorChatControllerProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $err')),
      );
    }
    _scrollToBottom();
    _maybeSpeakLatestReply();
  }

  Future<void> _toggleRecord() async {
    final sessionId = ref.read(tutorChatControllerProvider).session?.id;
    if (sessionId == null) return;

    if (_recording) {
      final path = await _voice.stopRecording();
      setState(() {
        _recording = false;
        _transcribing = true;
      });
      if (path == null) {
        setState(() => _transcribing = false);
        return;
      }
      final text = await _voice.transcribe(sessionId, path);
      if (!mounted) return;
      setState(() => _transcribing = false);
      if (text != null && text.trim().isNotEmpty) {
        await ref.read(tutorChatControllerProvider.notifier).send(text.trim());
        _scrollToBottom();
        _maybeSpeakLatestReply();
      }
      return;
    }

    final ok = await _voice.startRecording();
    if (!ok) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiTutorChatMicPermissionDenied)),
      );
      return;
    }
    setState(() => _recording = true);
  }

  void _maybeSpeakLatestReply() {
    if (!_voiceMode) return;
    final session = ref.read(tutorChatControllerProvider).session;
    if (session == null) return;
    final idx = session.messages.length - 1;
    final last = session.messages.isNotEmpty ? session.messages.last : null;
    if (last == null || last.role != 'assistant') return;
    if (idx == _lastSpokenIndex) return;
    _lastSpokenIndex = idx;
    _voice.speakAndPlay(session.id, messageIndex: idx);
  }

  Future<void> _endScenario() async {
    final session = ref.read(tutorChatControllerProvider).session;
    if (session == null) return;
    setState(() => _ending = true);
    try {
      // Hit /end which runs gradeScenario server-side.
      final res = await ApiClient().post('tutor/sessions/${session.id}/end');
      if (!res.success || res.data == null) {
        throw StateError(res.error ?? 'Could not end scenario');
      }
      final raw = res.data as Map<String, dynamic>;
      final inner = raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw;
      final updated = TutorSession.fromJson(inner);
      // Step 13A: roleplay completion analytics — fired after the
      // /end response with the score returns successfully.
      final isVip = ref.read(userProvider).valueOrNull?.isVip == true;
      AnalyticsService.instance.tutorChipCompleted(
        chipName: 'roleplay', userTier: isVip ? 'vip' : 'free',
      );
      if (!mounted) return;
      await _voice.stopPlayback();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _ScoreSheet(
          scenario: widget.scenario,
          score: updated.scenarioScore,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context); // back to scenario picker
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiTutorRoleplayEndFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    _controller.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(tutorChatControllerProvider);
    final messages = state.session?.messages ?? const <TutorMessage>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.scenario.emoji}  ${widget.scenario.title}'),
        actions: [
          IconButton(
            tooltip: _voiceMode ? l10n.aiTutorChatVoiceOn : l10n.aiTutorChatVoiceOff,
            icon: Icon(_voiceMode ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _voiceMode = !_voiceMode);
              if (!_voiceMode) _voice.stopPlayback();
            },
          ),
          TextButton(
            onPressed: _ending ? null : _endScenario,
            child: Text(_ending ? '…' : l10n.aiTutorRoleplayEnd),
          ),
        ],
      ),
      body: Column(
        children: [
          // Goal banner — always visible, anchors the user's objective.
          Container(
            width: double.infinity,
            color: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.scenario.goal,
                    style: context.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtl,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length + (state.sending ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final m = messages[i];
                final isUser = m.role == 'user';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primary
                              : context.containerColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          m.content,
                          style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : context.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed:
                        (state.sending || _transcribing) ? null : _toggleRecord,
                    icon: Icon(_recording
                        ? Icons.stop
                        : (_transcribing ? Icons.hourglass_empty : Icons.mic)),
                    tooltip: _recording
                        ? l10n.aiTutorChatStopRecording
                        : l10n.aiTutorChatHoldToTalk,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_recording && !_transcribing,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: _recording
                            ? l10n.aiTutorChatListening
                            : (_transcribing
                                ? l10n.aiTutorChatTranscribing
                                : l10n.aiTutorChatTypeReplyHint),
                        hintStyle: TextStyle(color: context.textMuted),
                        filled: true,
                        fillColor: context.containerColor,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMD,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: (state.sending || _recording || _transcribing)
                        ? null
                        : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreSheet extends StatelessWidget {
  final TutorScenario scenario;
  final ScenarioScore? score;
  const _ScoreSheet({required this.scenario, required this.score});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('${scenario.emoji}  ${scenario.title}',
              style: context.titleMedium.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (score != null) ...[
            Center(
              child: Text(
                '${score!.score}/100',
                style: context.titleLarge.copyWith(
                  color: _scoreColor(score!.score),
                  fontWeight: FontWeight.w800,
                  fontSize: 44,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(score!.feedback, style: context.bodyMedium),
          ] else
            Text("Couldn't grade this one — try again next time.",
                style: context.bodyMedium),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.aiTutorRoleplayDone),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 80) return Colors.green;
    if (s >= 60) return Colors.orange;
    return Colors.red;
  }
}
