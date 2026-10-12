import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'hardcoded_text_scanner.dart';

/// New keys per localization task (plan part 30, L1–L12). Each task adds its entry.
const Map<String, List<String>> _keysByTask = {
  'L1': [
    'chatDailyLimitBody',
    'chatCompressingVideo',
    'chatShareLocationBody',
    'chatTranslationLimitReached',
    'chatTranslateLimitBody',
    'chatReplyingTo',
    'chatSendingMedia',
    'chatEnterUsernameStart',
    'chatSearching',
    'chatDeleteConversationBody',
    'chatQrCode',
    'chatDraft',
    'chatTyping',
    'chatPoweredBy',
    'chatReconnecting',
    'chatShareLocationThisChat',
    'chatReplyingToFallback',
  ],
};

/// Files (under lib/) each task must leave with no English Text literal.
const Map<String, List<String>> _filesByTask = {
  'L1': [
    'pages/chat/chat_screen_wrapper.dart',
    'pages/chat/conversation/chat_conversation_screen.dart',
    'pages/chat/dialogs/translate_unlock_sheet.dart',
    'pages/chat/input/chat_input_bar.dart',
    'pages/chat/input/chat_input_section.dart',
    'pages/chat/list/chat_list_screen.dart',
    'pages/chat/list/chat_list_tile.dart',
    'pages/chat/panels/gif_picker_panel.dart',
    'widgets/connection_status_indicator.dart',
  ],
};

/// Keys whose draft may legitimately equal the English in some locale
/// (loanwords). Add with a one-line reason; empty by default.
const Set<String> _mayMatchEnglish = {
  'chatQrCode', // tl uses the English term
  'chatDraft', // tl uses the English loanword
  'chatReplyingToFallback', // tl uses the English loanword "user"
};

final _placeholder = RegExp(r'\{(\w+)[,}]');

void main() {
  final arbs = <String, Map<String, dynamic>>{
    for (final f in Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb')))
      f.uri.pathSegments.last: jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
  };
  final en = arbs['app_en.arb']!;

  for (final task in _keysByTask.keys) {
    group(task, () {
      test('every key is in all 19 locales, translated, placeholders kept', () {
        expect(arbs.length, 19);
        final problems = <String>[];
        for (final key in _keysByTask[task]!) {
          final source = en[key];
          if (source is! String || source.trim().isEmpty) {
            problems.add('app_en.arb: $key missing');
            continue;
          }
          final names = _placeholder.allMatches(source).map((m) => m.group(1)!).toSet();
          arbs.forEach((file, map) {
            final value = map[key];
            if (value is! String || value.trim().isEmpty) {
              problems.add('$file: $key missing');
              return;
            }
            if (file != 'app_en.arb' && value == source && !_mayMatchEnglish.contains(key)) {
              problems.add('$file: $key left in English');
            }
            for (final n in names) {
              if (!value.contains('{$n')) problems.add('$file: $key lost {$n}');
            }
          });
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });

      test('its files have no English Text literal left', () {
        final left = scanFiles(_filesByTask[task]!.map((f) => 'lib/$f'));
        expect(left, isEmpty, reason: left.join('\n'));
      });
    });
  }
}
