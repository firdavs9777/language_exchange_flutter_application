import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/tabs/waves_tab.dart';
import 'package:flutter/material.dart';

/// The waves inbox, opened from the Community header's wave icon (it was
/// the last of eight tabs).
class WavesScreen extends StatelessWidget {
  const WavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.waves)),
      body: const WavesTab(),
    );
  }
}
