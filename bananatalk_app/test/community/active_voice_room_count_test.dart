import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/active_voice_room_count_provider.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';

/// `activeVoiceRoomCountProvider` is `autoDispose` and its body does an
/// immediate `fetchCount()` before the 30s periodic stream. `community_app_bar`
/// watches it, so every dispose -> recreate paid another `GET /voicerooms`.
///
/// A device log on 2026-10-09 caught ~14 back-to-back requests ~570ms apart,
/// still firing during an active call, instead of one per 30 seconds.
///
/// `autoDispose` is deliberate -- polling must stop when nothing is watching.
/// What must NOT happen is a network round trip per re-subscribe.
class _CountingNotifier extends VoiceRoomNotifier {
  int fetches = 0;

  @override
  Future<List<VoiceRoom>> fetchRooms({
    String? language,
    String? topic,
    String? category,
  }) async {
    fetches++;
    return const [];
  }
}

void main() {
  test('a re-subscribe shortly after the last listener leaves does not refetch',
      () async {
    final fake = _CountingNotifier();
    final container = ProviderContainer(
      overrides: [voiceRoomProvider.overrideWith((ref) => fake)],
    );
    addTearDown(container.dispose);

    var first = container.listen(activeVoiceRoomCountProvider, (_, __) {});
    await container.read(activeVoiceRoomCountProvider.future);
    expect(fake.fetches, 1, reason: 'the first subscribe fetches once');

    // The app bar rebuilding: the last listener goes away and comes straight
    // back. The pump between them matters -- autoDispose disposes on a later
    // tick, so without it the provider never actually tears down and the test
    // would pass for the wrong reason.
    for (var i = 0; i < 5; i++) {
      first.close();
      await Future<void>.delayed(Duration.zero);
      first = container.listen(activeVoiceRoomCountProvider, (_, __) {});
      await container.read(activeVoiceRoomCountProvider.future);
    }
    addTearDown(first.close);

    expect(
      fake.fetches,
      1,
      reason: 'rapid re-subscribes must reuse the cached count, not refetch',
    );
  });

  test('the first subscribe still fetches', () async {
    final fake = _CountingNotifier();
    final container = ProviderContainer(
      overrides: [voiceRoomProvider.overrideWith((ref) => fake)],
    );
    addTearDown(container.dispose);

    final sub = container.listen(activeVoiceRoomCountProvider, (_, __) {});
    addTearDown(sub.close);
    final count = await container.read(activeVoiceRoomCountProvider.future);

    expect(fake.fetches, 1);
    expect(count, 0);
  });
}
