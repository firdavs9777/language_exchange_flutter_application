import 'package:bananatalk_app/models/learning/vocab_pack_model.dart';
import 'package:bananatalk_app/pages/learning/vocabulary/vocab_pack_detail_screen.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocab_packs_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Browse curated vocabulary packs (intermediate / advanced), each with words
/// and practice exercises.
class VocabPacksScreen extends ConsumerWidget {
  const VocabPacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(vocabPackLevelFilterProvider);
    final packsAsync = ref.watch(vocabPacksProvider(level));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary Packs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _LevelChip(
                  label: 'All',
                  selected: level == null,
                  onTap: () =>
                      ref.read(vocabPackLevelFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                _LevelChip(
                  label: 'Intermediate',
                  selected: level == 'intermediate',
                  onTap: () => ref
                      .read(vocabPackLevelFilterProvider.notifier)
                      .state = 'intermediate',
                ),
                const SizedBox(width: 8),
                _LevelChip(
                  label: 'Advanced',
                  selected: level == 'advanced',
                  onTap: () => ref
                      .read(vocabPackLevelFilterProvider.notifier)
                      .state = 'advanced',
                ),
              ],
            ),
          ),
          Expanded(
            child: packsAsync.when(
              data: (packs) {
                if (packs.isEmpty) {
                  return const Center(child: Text('No packs available yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(vocabPacksProvider(level)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: packs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _PackCard(pack: packs[i]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.error, size: 40),
                      const SizedBox(height: 12),
                      Text('Could not load packs',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(vocabPacksProvider(level)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Capitalizes the first letter; safe on empty strings.
String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class _LevelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LevelChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    // Filled accent when selected, outlined otherwise — clear contrast in
    // both light and dark themes (the default ChoiceChip washed out).
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent
                : theme.dividerColor.withValues(alpha: 0.6),
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final VocabPackSummary pack;
  const _PackCard({required this.pack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdvanced = pack.level == 'advanced';
    final accent = isAdvanced ? const Color(0xFFEC4899) : const Color(0xFF6366F1);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => VocabPackDetailScreen(
            packId: pack.id,
            topic: pack.topic,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.style_rounded, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(pack.topic,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      // Prominent level badge so the pack's level is obvious.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _capitalize(pack.level),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pack.wordCount} words · ${pack.exerciseCount} exercises',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
