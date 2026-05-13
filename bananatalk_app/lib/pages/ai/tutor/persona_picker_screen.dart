import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/ai/tutor/tutor_home_screen.dart';

class PersonaPickerScreen extends ConsumerStatefulWidget {
  final bool isFirstRun;

  /// Optional widget to navigate to after a persona is picked.
  /// When null, falls back to [TutorHomeScreen] (the original behavior).
  /// Used by AI Tools tab chips so a first-time tap on, say, 🎭 Roleplay
  /// lands the user in Roleplay after picking — not on TutorHome.
  final Widget? destinationAfterPick;

  const PersonaPickerScreen({
    super.key,
    this.isFirstRun = true,
    this.destinationAfterPick,
  });

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
        MaterialPageRoute(
          builder: (_) => widget.destinationAfterPick ?? const TutorHomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _selecting = null);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiTutorPickerSaveError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <_Persona>[
      _Persona('nana', '🐻', 'Nana', l10n.aiTutorPersonaNanaTagline,
          l10n.aiTutorPersonaNanaSample),
      _Persona('sensei', '🤖', 'Sensei', l10n.aiTutorPersonaSenseiTagline,
          l10n.aiTutorPersonaSenseiSample),
      _Persona('riko', '🐙', 'Riko', l10n.aiTutorPersonaRikoTagline,
          l10n.aiTutorPersonaRikoSample),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiTutorPickerTitle),
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
                l10n.aiTutorPickerHeader,
                style: context.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.aiTutorPickerSubtitle,
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
