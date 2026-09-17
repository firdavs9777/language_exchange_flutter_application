import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/video_sound_preference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VideoSoundPreference.instance.resetForTest();
  });

  test('with no stored choice, each surface keeps its own default', () async {
    // The tri-state exists for this: reels starts unmuted because opening one
    // is deliberate; a story autoplays off a ring tap and starts muted.
    // Collapsing to one boolean would overrule one of those.
    expect(await VideoSoundPreference.instance.load(), isNull);
    expect(VideoSoundPreference.instance.hasExplicitChoice, isFalse);
    expect(VideoSoundPreference.instance.isMutedOr(fallback: true), isTrue);
    expect(VideoSoundPreference.instance.isMutedOr(fallback: false), isFalse);
  });

  test('once chosen, the choice overrides every surface default', () async {
    SharedPreferences.setMockInitialValues({'video_muted': false});
    VideoSoundPreference.instance.resetForTest();
    await VideoSoundPreference.instance.load();

    expect(VideoSoundPreference.instance.hasExplicitChoice, isTrue);
    expect(VideoSoundPreference.instance.isMutedOr(fallback: true), isFalse,
        reason: 'an explicit choice beats the surface default');
  });

  test('setting persists and updates immediately', () async {
    await VideoSoundPreference.instance.load();
    await VideoSoundPreference.instance.setMuted(false);

    expect(VideoSoundPreference.instance.isMuted, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('video_muted'), isFalse);
  });

  test('the first toggle flips away from the surface default', () async {
    await VideoSoundPreference.instance.load();
    // Nothing stored, so the first tap has to flip from what the screen is
    // currently doing, not from an arbitrary constant.
    expect(await VideoSoundPreference.instance.toggle(fallback: false), isTrue);
    expect(await VideoSoundPreference.instance.toggle(fallback: false), isFalse);
  });

  test('it is usable before load, without awaiting', () async {
    // Consulted on every page change in a scrolling feed; it must never block.
    VideoSoundPreference.instance.resetForTest();
    expect(VideoSoundPreference.instance.isMutedOr(fallback: false), isFalse);
  });

  test('load is idempotent and does not re-read', () async {
    await VideoSoundPreference.instance.load();
    await VideoSoundPreference.instance.setMuted(false);
    // A second load must not overwrite the choice just made.
    expect(await VideoSoundPreference.instance.load(), isFalse);
  });
}
