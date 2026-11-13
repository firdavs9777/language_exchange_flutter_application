import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/app_config.dart';

void main() {
  const keys = [
    'storyStickerCorrectionEnabled',
    'storyStickerQuizEnabled',
    'storyStickerWordEnabled',
    'storyInsightsEnabled',
    'storyUploadQueueEnabled',
  ];

  List<bool> read(AppConfig c) => [
        c.storyStickerCorrectionEnabled,
        c.storyStickerQuizEnabled,
        c.storyStickerWordEnabled,
        c.storyInsightsEnabled,
        c.storyUploadQueueEnabled,
      ];

  test('stories feature flags default to false', () {
    expect(read(AppConfig.fromJson({})), everyElement(isFalse));
  });

  test('stories feature flags parse true', () {
    final c = AppConfig.fromJson({for (final k in keys) k: true});
    expect(read(c), everyElement(isTrue));
  });

  test('a malformed value reads as off and does not throw', () {
    final c = AppConfig.fromJson({
      for (final k in keys) k: 'true',
    });
    expect(read(c), everyElement(isFalse));
  });
}
