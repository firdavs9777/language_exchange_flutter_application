import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/tutor_provider.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import 'story_reader_screen.dart';

class StorySetupScreen extends ConsumerStatefulWidget {
  const StorySetupScreen({super.key});

  @override
  ConsumerState<StorySetupScreen> createState() => _StorySetupScreenState();
}

class _StorySetupScreenState extends ConsumerState<StorySetupScreen> {
  int _wordCount = 5;
  String _theme = 'free';
  bool _generating = false;

  static const _themes = <_ThemeOption>[
    _ThemeOption('free', '🎲', 'Free'),
    _ThemeOption('adventure', '🗺️', 'Adventure'),
    _ThemeOption('mystery', '🔍', 'Mystery'),
    _ThemeOption('romance', '💌', 'Romance'),
    _ThemeOption('sci_fi', '🚀', 'Sci-fi'),
    _ThemeOption('slice_of_life', '☕', 'Slice of life'),
  ];

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final story = await ref
          .read(tutorServiceProvider)
          .generateStory(wordCount: _wordCount, theme: _theme);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StoryReaderScreen(story: story)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate: $e')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Read a story')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Length',
                  style: context.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final n in [3, 5, 10]) ...[
                    Expanded(
                      child: _ChoiceTile(
                        label: '$n words',
                        selected: _wordCount == n,
                        onTap: () => setState(() => _wordCount = n),
                      ),
                    ),
                    if (n != 10) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Text('Theme',
                  style: context.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _themes)
                    _ThemeChip(
                      option: t,
                      selected: _theme == t.id,
                      onTap: () => setState(() => _theme = t.id),
                    ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_stories),
                  label: Text(_generating ? 'Writing…' : 'Generate story'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMD),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The AI will use up to $_wordCount words from your vocab list.',
                style: context.bodySmall.copyWith(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption {
  final String id;
  final String emoji;
  final String label;
  const _ThemeOption(this.id, this.emoji, this.label);
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : context.containerColor,
      borderRadius: AppRadius.borderMD,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMD,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final _ThemeOption option;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : context.containerColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : context.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji),
            const SizedBox(width: 6),
            Text(
              option.label,
              style: TextStyle(
                color: selected ? Colors.white : context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
