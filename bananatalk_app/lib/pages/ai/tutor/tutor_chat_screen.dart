import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/tutor_voice_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/tutor/quiz_card.dart';
import 'package:bananatalk_app/widgets/tutor/tutor_quota_indicator.dart';
import 'package:bananatalk_app/widgets/tutor/vocab_card.dart';
import 'package:bananatalk_app/widgets/tutor/grammar_card.dart';
import 'package:bananatalk_app/widgets/tutor/srs_due_card.dart';
import 'package:bananatalk_app/widgets/tutor/mini_lesson_card.dart';

class TutorChatScreen extends ConsumerStatefulWidget {
  const TutorChatScreen({super.key});

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtl = ScrollController();
  final _voice = TutorVoiceService();
  bool _started = false;
  bool _voiceMode = false;
  bool _recording = false;
  bool _transcribing = false;
  int _lastSpokenIndex = -1;

  /// Cached tier for analytics — read once in initState so we can
  /// fire tutor_chip_completed from dispose() without ref access.
  String _userTier = 'free';

  /// Cached chat controller so dispose() can flush the end-session
  /// event without going through `ref` (ref is invalid once the
  /// ConsumerStatefulElement is being unmounted).
  TutorChatController? _chatNotifier;

  @override
  void initState() {
    super.initState();
    _chatNotifier = ref.read(tutorChatControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _userTier = ref.read(userProvider).valueOrNull?.isVip == true ? 'vip' : 'free';
      AnalyticsService.instance.tutorChipUsed(chipName: 'chat', userTier: _userTier);
      try {
        await ref.read(tutorChatControllerProvider.notifier).start();
        if (!mounted) return;
        setState(() => _started = true);
        _scrollToBottom();
      } catch (e) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiTutorChatStartFailed(e.toString()))),
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
    _controller.clear();
    await ref.read(tutorChatControllerProvider.notifier).send(text);
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
      } else {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiTutorChatTranscribeFailed)),
        );
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
    // Fire and forget; failures degrade silently to text-only.
    _voice.speakAndPlay(session.id, messageIndex: idx);
  }

  @override
  void dispose() {
    AnalyticsService.instance.tutorChipCompleted(chipName: 'chat', userTier: _userTier);
    // Fire-and-forget end via the cached notifier — ref.read here would
    // throw because the ConsumerStatefulElement is mid-unmount.
    final n = _chatNotifier;
    if (n != null && n.mounted && n.state.session != null) {
      n.end();
    }
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
        title: Text(l10n.aiTutorChatTitle),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: TutorQuotaIndicator(featureKey: 'chat')),
          ),
          IconButton(
            tooltip: _voiceMode ? l10n.aiTutorChatVoiceOn : l10n.aiTutorChatVoiceOff,
            icon: Icon(_voiceMode ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _voiceMode = !_voiceMode);
              if (!_voiceMode) _voice.stopPlayback();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !_started
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _MessageBubble(message: messages[i]);
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
                        : (_transcribing
                            ? l10n.aiTutorChatTranscribing
                            : l10n.aiTutorChatHoldToTalk),
                    style: IconButton.styleFrom(
                      backgroundColor: _recording
                          ? Colors.red.withValues(alpha: 0.2)
                          : null,
                    ),
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
                                : l10n.aiTutorChatInputHint),
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
                    onPressed:
                        (state.sending || _recording || _transcribing)
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

class _MessageBubble extends StatelessWidget {
  final TutorMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    final Widget body = switch (message.messageType) {
      'quiz_card' => QuizCard(payload: message.payload ?? const {}),
      'vocab_card' => VocabCard(payload: message.payload ?? const {}),
      'grammar_card' => GrammarCard(payload: message.payload ?? const {}),
      'srs_due_card' => SrsDueCard(payload: message.payload ?? const {}),
      'mini_lesson_card' =>
        MiniLessonCard(payload: message.payload ?? const {}),
      _ => _TextBubble(text: message.content, isUser: isUser),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.messageType != 'text' && message.content.isNotEmpty)
            Align(
              alignment: alignment,
              child: _TextBubble(text: message.content, isUser: isUser),
            ),
          if (message.messageType != 'text') const SizedBox(height: 6),
          Align(alignment: alignment, child: body),
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _TextBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : context.containerColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : context.textPrimary),
        ),
      ),
    );
  }
}
