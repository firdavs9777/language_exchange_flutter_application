import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/moment_fixture.dart';

/// A change on one card (save, like, edit, delete) must land in the feed
/// list: cards are rebuilt from it after scrolling away, and a deleted
/// moment must not stay tappable.
void main() {
  late ProviderContainer container;
  late AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>> provider;

  setUp(() async {
    provider = AsyncNotifierProvider<PagedMomentsFeedNotifier, List<Moments>>(
      () => PagedMomentsFeedNotifier((ref, page) async => MomentsFeedPage(
            [buildMoment(id: 'a'), buildMoment(id: 'b'), buildMoment(id: 'c')],
            hasMore: false,
          )),
    );
    container = ProviderContainer();
    await container.read(provider.future);
  });
  tearDown(() => container.dispose());

  List<String> ids() =>
      container.read(provider).value!.map((m) => m.id).toList();

  test('patchMoment replaces that moment only', () {
    container
        .read(provider.notifier)
        .patchMoment('b', (m) => m.copyWith(savedBy: ['me']));
    final list = container.read(provider).value!;
    expect(list[1].savedBy, ['me']);
    expect(list[0].savedBy, isNot(contains('me')));
    expect(ids(), ['a', 'b', 'c']);
  });

  test('removeMoment drops it and keeps the order', () {
    container.read(provider.notifier).removeMoment('b');
    expect(ids(), ['a', 'c']);
  });

  test('an id that is not loaded changes nothing', () {
    final before = container.read(provider).value;
    container.read(provider.notifier).removeMoment('zzz');
    container.read(provider.notifier).patchMoment('zzz', (m) => m);
    expect(identical(container.read(provider).value, before), isTrue);
  });
}
