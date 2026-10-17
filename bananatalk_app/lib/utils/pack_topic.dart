import 'package:flutter/widgets.dart';

/// A vocabulary pack topic as shown to the reader.
///
/// Non-English packs store their topic as "<target-language name> (<English
/// gloss>)", e.g. "규칙과 예절 (Rules and manners)". The gloss is English
/// whatever the app language, so an Arabic or Korean UI showed an English
/// bracket. The gloss stays for an English UI and is dropped otherwise: the
/// learner reads the topic in the language they are learning.
String packTopicForLocale(String topic, Locale locale) {
  if (locale.languageCode == 'en') return topic;
  final m = RegExp(r'^(.*\S)\s*\(([A-Za-z][^()]*)\)\s*$').firstMatch(topic);
  return m == null ? topic : m.group(1)!;
}

extension PackTopicContext on BuildContext {
  String packTopic(String topic) =>
      packTopicForLocale(topic, Localizations.localeOf(this));
}
