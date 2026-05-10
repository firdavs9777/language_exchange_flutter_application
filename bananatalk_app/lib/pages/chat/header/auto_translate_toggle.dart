import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/translation_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Bottom-sheet body showing a per-conversation auto-translate switch.
///
/// Open via [showModalBottomSheet] from the chat app-bar overflow menu.
/// State is persisted in SharedPreferences under the key
/// `auto_translate_chat_<conversationId>`.
class AutoTranslateBottomSheet extends StatefulWidget {
  final String conversationId;

  const AutoTranslateBottomSheet({super.key, required this.conversationId});

  @override
  State<AutoTranslateBottomSheet> createState() =>
      _AutoTranslateBottomSheetState();
}

class _AutoTranslateBottomSheetState extends State<AutoTranslateBottomSheet> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await TranslationService.isAutoTranslateChatEnabled(
      widget.conversationId,
    );
    if (!mounted) return;
    setState(() => _enabled = v);
  }

  Future<void> _toggle(bool v) async {
    setState(() => _enabled = v);
    await TranslationService.setAutoTranslateChatForConversation(
      widget.conversationId,
      v,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SwitchListTile(
          secondary: const Icon(Icons.translate_rounded),
          title: Text(l10n.autoTranslate),
          subtitle: Text(l10n.autoTranslateChatHint),
          value: _enabled ?? false,
          onChanged: _enabled == null ? null : _toggle,
        ),
      ),
    );
  }
}
