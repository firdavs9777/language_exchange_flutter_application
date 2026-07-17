import 'package:bananatalk_app/pages/learning/vocabulary/vocab_pack_practice_screen.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocab_packs_providers.dart';
import 'package:bananatalk_app/services/learning_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a pack's words and lets the user add them to their personal vocabulary
/// or start a practice session over the pack's exercises.
class VocabPackDetailScreen extends ConsumerStatefulWidget {
  final String packId;
  final String topic;
  const VocabPackDetailScreen(
      {super.key, required this.packId, required this.topic});

  @override
  ConsumerState<VocabPackDetailScreen> createState() =>
      _VocabPackDetailScreenState();
}

class _VocabPackDetailScreenState extends ConsumerState<VocabPackDetailScreen> {
  bool _adding = false;

  Future<void> _addToVocabulary() async {
    setState(() => _adding = true);
    try {
      final result = await LearningService.addVocabPack(widget.packId);
      if (!mounted) return;
      final added = result['added'] ?? 0;
      final alreadyHad = result['alreadyHad'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added == 0
              ? 'All ${result['totalWords'] ?? ''} words are already in your vocabulary'
              : 'Added $added words to your vocabulary'
                  '${alreadyHad > 0 ? ' ($alreadyHad already saved)' : ''}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add pack: $e')),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packAsync = ref.watch(vocabPackDetailProvider(widget.packId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.topic)),
      body: packAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load pack'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(vocabPackDetailProvider(widget.packId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (pack) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: pack.words.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, i) {
                  final w = pack.words[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(w.word,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (w.translationHint != null &&
                              w.translationHint!.isNotEmpty)
                            Flexible(
                              child: Text(
                                w.translationHint!,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(w.definition, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('“${w.example}”',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.8))),
                    ],
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _adding ? null : _addToVocabulary,
                        icon: _adding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.bookmark_add_outlined),
                        label: const Text('Add to my vocab'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: pack.exercises.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  AppPageRoute(
                                    builder: (_) => VocabPackPracticeScreen(
                                      topic: pack.topic,
                                      exercises: pack.exercises,
                                    ),
                                  ),
                                ),
                        icon: const Icon(Icons.fitness_center_rounded),
                        label: Text(pack.exercises.isEmpty
                            ? 'No exercises'
                            : 'Practice (${pack.exercises.length})'),
                      ),
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
