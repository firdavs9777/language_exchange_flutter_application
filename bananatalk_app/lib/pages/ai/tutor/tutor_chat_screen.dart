import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/tutor/tutor_session.dart';
import '../../../providers/tutor_provider.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/tutor/quiz_card.dart';
import '../../../widgets/tutor/vocab_card.dart';
import '../../../widgets/tutor/grammar_card.dart';

class TutorChatScreen extends ConsumerStatefulWidget {
  const TutorChatScreen({super.key});

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtl = ScrollController();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(tutorChatControllerProvider.notifier).start();
        if (!mounted) return;
        setState(() => _started = true);
        _scrollToBottom();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start: $e')),
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
  }

  @override
  void dispose() {
    // Fire-and-forget end so memory updates on background.
    final state = ref.read(tutorChatControllerProvider);
    if (state.session != null) {
      ref.read(tutorChatControllerProvider.notifier).end();
    }
    _controller.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorChatControllerProvider);
    final messages = state.session?.messages ?? const <TutorMessage>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Chat with tutor')),
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
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
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
                    onPressed: state.sending ? null : _send,
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
