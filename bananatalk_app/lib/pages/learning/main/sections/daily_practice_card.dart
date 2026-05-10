import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/pages/learning/widgets/learning_snackbar.dart';

final dailyPracticeProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return LearningService.getDailyPractice();
});

class DailyPracticeCard extends ConsumerWidget {
  const DailyPracticeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final practice = ref.watch(dailyPracticeProvider);

    return practice.when(
      data: (data) {
        final sentence = data['sentence']?.toString();
        if (sentence == null || sentence.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: InkWell(
            onTap: () => _open(context, ref, data),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: theme.colorScheme.tertiary),
                      const SizedBox(width: 8),
                      const Text(
                        'Daily Practice',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          color: theme.colorScheme.outline),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sentence,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Translate this sentence',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _open(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyPracticeScreen(initialData: data),
      ),
    );
  }
}

class DailyPracticeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData;
  const DailyPracticeScreen({super.key, required this.initialData});

  @override
  ConsumerState<DailyPracticeScreen> createState() =>
      _DailyPracticeScreenState();
}

class _DailyPracticeScreenState extends ConsumerState<DailyPracticeScreen> {
  final _controller = TextEditingController();
  bool _grading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_controller.text.trim().isEmpty) return;
    setState(() => _grading = true);
    try {
      final result = await LearningService.gradeDailyPractice(
        sentenceNative: widget.initialData['sentence'].toString(),
        userTranslation: _controller.text.trim(),
        expectedTranslation:
            widget.initialData['expectedTranslation']?.toString(),
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (_) {
      if (!mounted) return;
      showLearningSnackBar(context, l10n.learningErrorGeneric);
    } finally {
      if (mounted) setState(() => _grading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.initialData;
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Practice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Translate this:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      data['sentence']?.toString() ?? '',
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    if ((data['difficultyHint']?.toString() ?? '').isNotEmpty)
                      ...[
                      const SizedBox(height: 12),
                      Text(
                        '${data['difficultyHint']}',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.tertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Your translation',
                border: OutlineInputBorder(),
              ),
              enabled: result == null,
            ),
            const SizedBox(height: 12),
            if (result == null)
              FilledButton.icon(
                onPressed: _grading ? null : _submit,
                icon: _grading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Submit'),
              )
            else
              _buildResult(theme, result),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(ThemeData theme, Map<String, dynamic> result) {
    final score = result['score'] is int ? result['score'] as int : 0;
    final isCorrect = result['isCorrect'] == true;
    final feedback = result['feedback']?.toString() ?? '';
    final suggested = result['suggestedTranslation']?.toString() ?? '';
    final color = isCorrect ? Colors.green : Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isCorrect ? Icons.check_circle : Icons.info,
                        color: color),
                    const SizedBox(width: 8),
                    Text(
                      'Score: $score / 100',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16),
                    ),
                  ],
                ),
                if (feedback.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(feedback,
                      style:
                          const TextStyle(fontSize: 14, height: 1.4)),
                ],
                if (suggested.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Suggested:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(suggested,
                      style: const TextStyle(
                          fontSize: 14, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
