import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

/// The waves badge and the Chats intro strip read one shared request. They
/// used to call `community/waves` twice per launch (limit=1 for the count,
/// limit=20 for the list) and the 20-row answer already carries the count.
class _FakeCommunity implements CommunityService {
  _FakeCommunity({this.unreadCount = 3, this.fail = false});
  int unreadCount;
  bool fail;
  int calls = 0;

  @override
  Future<UnreadWaves> getUnreadWaves({int limit = 20}) async {
    calls++;
    if (fail) throw Exception('offline');
    return (waves: parseWavesList(const {'data': {'waves': []}}), unreadCount: unreadCount);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

ProviderContainer _container(_FakeCommunity fake) {
  final c = ProviderContainer(overrides: [
    communityServiceProvider.overrideWithValue(fake),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('badge and intro strip together make ONE request', () async {
    final fake = _FakeCommunity(unreadCount: 7);
    final c = _container(fake);

    final results = await Future.wait([
      c.read(wavesUnreadProvider.future),
      c.read(pendingIntrosProvider.future),
    ]);
    expect(results[0], 7);
    expect(results[1], isEmpty);
    expect(fake.calls, 1);
  });

  test('invalidating the shared provider refreshes both', () async {
    final fake = _FakeCommunity(unreadCount: 2);
    final c = _container(fake);
    // Keep both derived providers alive, as the badge and strip do.
    c.listen(wavesUnreadProvider, (_, __) {});
    c.listen(pendingIntrosProvider, (_, __) {});
    expect(await c.read(wavesUnreadProvider.future), 2);

    fake.unreadCount = 0;
    c.invalidate(unreadWavesProvider);
    expect(await c.read(wavesUnreadProvider.future), 0);
    await c.read(pendingIntrosProvider.future);
    expect(fake.calls, 2);
  });

  test('a failed load hides the badge but is an error for the strip', () async {
    final c = _container(_FakeCommunity(fail: true));
    expect(await c.read(wavesUnreadProvider.future), 0);
    await expectLater(c.read(pendingIntrosProvider.future), throwsException);
  });

  test('parseWavesList accepts both response shapes and nothing else', () {
    expect(parseWavesList({'data': {'waves': []}}), isEmpty);
    expect(parseWavesList({'data': []}), isEmpty);
    expect(parseWavesList(null), isEmpty);
    expect(parseWavesList({'data': 'x'}), isEmpty);
  });
}
