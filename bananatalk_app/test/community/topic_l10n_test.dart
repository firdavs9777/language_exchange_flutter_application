import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';

void main() {
  final ru = lookupAppLocalizations(const Locale('ru'));

  test('every built-in topic and category has a translated name', () {
    for (final t in Topic.defaultTopics) {
      expect(t.localizedName(ru), isNot(t.id), reason: t.id);
    }
    for (final c in Topic.categories) {
      expect(Topic.getCategoryLabel(c, ru), isNot(c), reason: c);
    }
    expect(Topic.defaultTopics.first.localizedName(ru), 'Кулинария');
  });

  test('a server topic with an unknown id keeps its own name', () {
    const t = Topic(id: 'philosophy', name: 'Philosophy', icon: '', category: '');
    expect(t.localizedName(ru), 'Philosophy');
  });
}
