import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';

void main() {
  test('pack endpoints are wired to the study routes', () {
    expect(Endpoints.dailyPackURL, 'study/pack');
    expect(Endpoints.dailyPackCompleteURL('grammar'), 'study/pack/grammar/complete');
    expect(Endpoints.placementURL, 'study/placement');
    expect(Endpoints.masteryURL, 'learning/mastery');
  });

  test('the pack locale tag follows the daily-drop mapping', () {
    // Content is authored in en, zh-Hans and ar; anything else degrades to en.
    expect(packLocaleTag(const Locale('ar')), 'ar');
    expect(packLocaleTag(const Locale('zh')), 'zh-Hans');
    expect(packLocaleTag(const Locale('ko')), 'en');
  });
}
