import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Matches the backend cap on a decline message.
const int kDeclineMessageMax = 200;

/// Two canned replies + a custom one. Resolves to the text, or null if dismissed.
Future<String?> showDeclineMessageSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _DeclineMessageSheet(),
  );
}

class _DeclineMessageSheet extends StatefulWidget {
  const _DeclineMessageSheet();
  @override
  State<_DeclineMessageSheet> createState() => _DeclineMessageSheetState();
}

class _DeclineMessageSheetState extends State<_DeclineMessageSheet> {
  final _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canned = [l10n.callDeclineCannedLater, l10n.callDeclineCannedText];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  l10n.callDeclineSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final text in canned)
                ListTile(
                  title: Text(text),
                  onTap: () => Navigator.pop(context, text),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: kDeclineMessageMax,
                        decoration: InputDecoration(
                          hintText: l10n.callDeclineCustomHint,
                          counterText: '',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _canSend
                          ? () =>
                                Navigator.pop(context, _controller.text.trim())
                          : null,
                      child: Text(l10n.callDeclineSend),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
