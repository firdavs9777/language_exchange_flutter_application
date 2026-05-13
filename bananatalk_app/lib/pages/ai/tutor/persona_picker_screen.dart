import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/tutor_provider.dart';
import '../../../utils/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';
import 'tutor_home_screen.dart';

class PersonaPickerScreen extends ConsumerStatefulWidget {
  final bool isFirstRun;
  const PersonaPickerScreen({super.key, this.isFirstRun = true});

  @override
  ConsumerState<PersonaPickerScreen> createState() => _PersonaPickerScreenState();
}

class _PersonaPickerScreenState extends ConsumerState<PersonaPickerScreen> {
  String? _selecting;

  Future<void> _pick(String key) async {
    setState(() => _selecting = key);
    try {
      await ref.read(tutorServiceProvider).setPersona(key);
      ref.invalidate(tutorMemoryProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TutorHomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _selecting = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = <_Persona>[
      _Persona('nana', '🐻', 'Nana', 'Warm + encouraging',
          "I'll cheer you on, no pressure."),
      _Persona('sensei', '🤖', 'Sensei', 'Precise + exam-focused',
          'We will master the rules.'),
      _Persona('riko', '🐙', 'Riko', 'Playful + slangy',
          "lol let's vibe and learn"),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick your AI tutor'),
        leading: widget.isFirstRun
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Who do you want to learn with?',
                style: context.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can change this anytime in settings.',
                style: context.bodyMedium.copyWith(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              for (final p in entries) ...[
                _PersonaCard(
                  persona: p,
                  loading: _selecting == p.key,
                  onPick: () => _pick(p.key),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Persona {
  final String key;
  final String avatar;
  final String name;
  final String tagline;
  final String sample;
  _Persona(this.key, this.avatar, this.name, this.tagline, this.sample);
}

class _PersonaCard extends StatelessWidget {
  final _Persona persona;
  final bool loading;
  final VoidCallback onPick;
  const _PersonaCard({
    required this.persona,
    required this.loading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.containerColor,
      borderRadius: AppRadius.borderMD,
      child: InkWell(
        onTap: loading ? null : onPick,
        borderRadius: AppRadius.borderMD,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(persona.avatar, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(persona.name,
                        style: context.titleMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(persona.tagline,
                        style: context.bodySmall
                            .copyWith(color: context.textSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      '"${persona.sample}"',
                      style: context.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
