import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Interactive question box widget for stories
class StoryQuestionBoxWidget extends StatefulWidget {
  final StoryQuestionBox questionBox;
  final bool isOwner;
  final Function(String, bool)? onSubmitAnswer;

  /// Called when the owner taps "View responses". When provided, this
  /// overrides the default behavior of showing [widget.questionBox.responses]
  /// directly — useful for fetching live responses (e.g. via
  /// `StoriesService.getQuestionResponses`) instead of relying on whatever
  /// snapshot was embedded in the story payload.
  final VoidCallback? onViewResponses;

  /// Called with `true` when the answer input gains focus (story playback
  /// should pause) and `false` when it loses focus (playback should resume).
  final ValueChanged<bool>? onFocusChanged;

  /// The viewer already answered (server `hasAnswered`, or an answer sent
  /// earlier in this session): open straight on the "answer sent" state
  /// instead of offering the input again.
  final bool hasAnswered;

  const StoryQuestionBoxWidget({
    Key? key,
    required this.questionBox,
    this.isOwner = false,
    this.onSubmitAnswer,
    this.onViewResponses,
    this.onFocusChanged,
    this.hasAnswered = false,
  }) : super(key: key);

  @override
  State<StoryQuestionBoxWidget> createState() => _StoryQuestionBoxWidgetState();
}

class _StoryQuestionBoxWidgetState extends State<StoryQuestionBoxWidget> {
  final _answerController = TextEditingController();
  final _answerFocusNode = FocusNode();
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _hasSubmitted = !widget.isOwner && widget.hasAnswered;
    _answerFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant StoryQuestionBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOwner && widget.hasAnswered && !_hasSubmitted) {
      _hasSubmitted = true;
    }
  }

  void _handleFocusChange() {
    widget.onFocusChanged?.call(_answerFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _answerFocusNode.removeListener(_handleFocusChange);
    _answerFocusNode.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;
    
    setState(() => _isSubmitting = true);
    
    widget.onSubmitAnswer?.call(_answerController.text.trim(), _isAnonymous);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _hasSubmitted = true;
      });
      // Submission complete — release the playback pause even if the field
      // technically still has focus (e.g. keyboard hasn't dismissed yet).
      widget.onFocusChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.8),
            Colors.pink.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.questionBox.prompt,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!widget.isOwner && !_hasSubmitted) ...[
            TextField(
              controller: _answerController,
              focusNode: _answerFocusNode,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeYourAnswer,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v ?? false),
                  checkColor: Colors.purple,
                  fillColor: WidgetStateProperty.all(Colors.white),
                ),
                Text(
                  AppLocalizations.of(context)!.storySendAnonymously,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context)!.send, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ] else if (_hasSubmitted) ...[
            const Icon(Icons.check_circle, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.answerSent,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ] else if (widget.isOwner) ...[
            Text(
              AppLocalizations.of(context)!.storyResponseCount(widget.questionBox.totalResponses),
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onViewResponses ??
                  () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.grey[900],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => StoryQuestionResponsesList(responses: widget.questionBox.responses),
                    );
                  },
              child: Text(
                AppLocalizations.of(context)!.storyViewResponses,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sheet content listing question responses. Reusable both for the widget's
/// own default "View responses" action and for callers (e.g. the story
/// viewer) that fetch live responses via `StoriesService.getQuestionResponses`
/// and want to show a loading indicator while the request is in flight.
class StoryQuestionResponsesList extends StatelessWidget {
  final List<StoryQuestionResponse> responses;
  final bool isLoading;

  /// The responses could not be loaded: show an error with [onRetry]
  /// instead of an empty or half-populated list.
  final bool hasError;
  final VoidCallback? onRetry;

  const StoryQuestionResponsesList({
    super.key,
    required this.responses,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)!.storyResponsesTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.somethingWentWrong,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (onRetry != null)
                        TextButton(
                          onPressed: onRetry,
                          child: Text(
                            AppLocalizations.of(context)!.retry,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                )
              : responses.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.storyNoResponsesYet,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: responses.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final response = responses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (response.isAnonymous)
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person, size: 18, color: Colors.white),
                                )
                              else if (response.user != null)
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: response.user!.imageUrls.isNotEmpty
                                      ? NetworkImage(response.user!.imageUrls.first)
                                      : null,
                                  child: response.user!.imageUrls.isEmpty
                                      ? Text(response.user!.name.isNotEmpty ? response.user!.name[0] : '?')
                                      : null,
                                )
                              else
                                // Unpopulated author (a bare id): a neutral
                                // placeholder rather than a blank gap.
                                const CircleAvatar(
                                  key: Key('response-placeholder-avatar'),
                                  radius: 16,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person_outline, size: 18, color: Colors.white),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                response.isAnonymous 
                                    ? AppLocalizations.of(context)!.storyAnonymous
                                    : response.user?.name ?? AppLocalizations.of(context)!.unknown,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            response.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Create question box dialog
class CreateQuestionBoxDialog extends StatefulWidget {
  final Function(StoryQuestionBox) onCreated;

  const CreateQuestionBoxDialog({Key? key, required this.onCreated}) : super(key: key);

  @override
  State<CreateQuestionBoxDialog> createState() => _CreateQuestionBoxDialogState();
}

class _CreateQuestionBoxDialogState extends State<CreateQuestionBoxDialog> {
  final _promptController = TextEditingController(text: 'Ask me anything!');

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.storyQuestionBox,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.yourPrompt,
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _QuickPromptChip('Ask me anything! 🎤', _promptController),
                _QuickPromptChip('Questions? 💬', _promptController),
                _QuickPromptChip('AMA! 🙋', _promptController),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: Colors.grey[400])),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_promptController.text.trim().isEmpty) return;
                    widget.onCreated(StoryQuestionBox(prompt: _promptController.text.trim()));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(AppLocalizations.of(context)!.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final String text;
  final TextEditingController controller;

  const _QuickPromptChip(this.text, this.controller);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () => controller.text = text,
      backgroundColor: Colors.grey[700],
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}

