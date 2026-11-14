import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/offers/offer.dart';
import 'package:bananatalk_app/services/offers/offers_api.dart';
import 'package:bananatalk_app/services/offers/offers_provider.dart';

class _FakeApi implements OffersApi {
  int calls = 0;
  Offer? next;
  Object? error;

  @override
  Future<Offer?> fetch() async {
    calls++;
    if (error != null) throw error!;
    return next;
  }
}

final _flag = StateProvider<bool>((ref) => false);

final _t0 = DateTime.utc(2026, 11, 14, 9);

Offer _offer({
  String id = 'o1',
  String surface = OfferSurface.momentsChip,
  String lead = OfferLead.vip,
  Duration validFor = const Duration(hours: 1),
}) => Offer(
  id: id,
  surface: surface,
  placement: 'vip_entry',
  lead: lead,
  validUntil: _t0.add(validFor),
);

const _surfaces = [
  OfferSurface.visitorRecall,
  OfferSurface.profileBanner,
  OfferSurface.momentsChip,
  OfferSurface.matchesEmpty,
];

void main() {
  late _FakeApi api;
  late DateTime now;
  late ProviderContainer container;

  ProviderContainer make({bool engine = true, DateTime Function()? clock}) {
    final c = ProviderContainer(
      overrides: [
        offerEngineEnabledProvider.overrideWith((ref) => ref.watch(_flag)),
        offersApiProvider.overrideWithValue(api),
        offersClockProvider.overrideWithValue(clock ?? () => now),
      ],
    );
    c.read(_flag.notifier).state = engine;
    return c;
  }

  OfferGate gate(String surface) => container.read(offerGateProvider(surface));

  setUp(() {
    api = _FakeApi();
    now = _t0;
    resetOfferProcessStateForTest();
  });

  test('engine off: refresh makes no request and every gate is Legacy', () async {
    container = make(engine: false);
    addTearDown(container.dispose);
    api.next = _offer();
    await container.read(offersProvider.notifier).refresh();
    await container.read(offersProvider.notifier).refresh(force: true);
    expect(api.calls, 0);
    for (final s in _surfaces) {
      expect(gate(s), isA<OfferGateLegacy>(), reason: s);
    }
  });

  test('a valid offer shows its surface and hides the other three', () async {
    container = make();
    addTearDown(container.dispose);
    api.next = _offer(surface: OfferSurface.momentsChip);
    await container.read(offersProvider.notifier).refresh();
    expect(api.calls, 1);
    final shown = gate(OfferSurface.momentsChip);
    expect(shown, isA<OfferGateShow>());
    expect((shown as OfferGateShow).offer.id, 'o1');
    for (final s in _surfaces.where((s) => s != OfferSurface.momentsChip)) {
      expect(gate(s), isA<OfferGateHidden>(), reason: s);
    }
  });

  test('two refreshes inside 2 minutes make one request; force makes a second',
      () async {
    container = make();
    addTearDown(container.dispose);
    api.next = _offer();
    final n = container.read(offersProvider.notifier);
    await n.refresh();
    now = _t0.add(const Duration(seconds: 119));
    await n.refresh();
    expect(api.calls, 1);
    await n.refresh(force: true);
    expect(api.calls, 2);
    now = now.add(const Duration(minutes: 2));
    await n.refresh();
    expect(api.calls, 3);
  });

  test('a failed or malformed answer leaves every gate Hidden and does not throw',
      () async {
    container = make();
    addTearDown(container.dispose);
    final n = container.read(offersProvider.notifier);
    api.next = _offer();
    await n.refresh();
    expect(gate(OfferSurface.momentsChip), isA<OfferGateShow>());

    api.error = Exception('boom');
    await expectLater(n.refresh(force: true), completes);
    expect(container.read(offersProvider), isNull);
    for (final s in _surfaces) {
      expect(gate(s), isA<OfferGateHidden>(), reason: s);
    }

    api.error = null;
    api.next = null; // malformed / non-200 / empty all reach here as null
    await n.refresh(force: true);
    for (final s in _surfaces) {
      expect(gate(s), isA<OfferGateHidden>(), reason: s);
    }
  });

  test('an offer past validUntil is Hidden without a new request', () {
    fakeAsync((async) {
      container = make(clock: () => _t0.add(async.elapsed));
      final seen = <OfferGate>[];
      container.listen<OfferGate>(
        offerGateProvider(OfferSurface.momentsChip),
        (_, next) => seen.add(next),
        fireImmediately: true,
      );
      api.next = _offer(validFor: const Duration(minutes: 10));
      container.read(offersProvider.notifier).refresh();
      async.elapse(Duration.zero);
      expect(seen.last, isA<OfferGateShow>());

      async.elapse(const Duration(minutes: 9, seconds: 59));
      expect(seen.last, isA<OfferGateShow>());
      async.elapse(const Duration(seconds: 2));
      expect(seen.last, isA<OfferGateHidden>());
      expect(container.read(offersProvider), isNull);
      expect(api.calls, 1);
      container.dispose();
    });
  });

  test('an offer already past validUntil is never shown', () async {
    container = make();
    addTearDown(container.dispose);
    api.next = _offer(validFor: const Duration(minutes: -1));
    await container.read(offersProvider.notifier).refresh();
    expect(gate(OfferSurface.momentsChip), isA<OfferGateHidden>());
  });

  test('sign-out drops the offer and its expiry timer', () {
    fakeAsync((async) {
      container = make(clock: () => _t0.add(async.elapsed));
      api.next = _offer();
      container.read(offersProvider.notifier).refresh();
      async.elapse(Duration.zero);
      expect(container.read(offersProvider), isNotNull);
      bool expiryPending() =>
          async.pendingTimers.any((t) => t.duration > Duration.zero);
      expect(expiryPending(), isTrue);

      container.invalidate(offersProvider); // what resetUserSession does
      expect(container.read(offersProvider), isNull);
      async.elapse(Duration.zero);
      expect(expiryPending(), isFalse);
      container.dispose();
    });
  });

  test('the engine turning on fetches the offer once', () async {
    container = make(engine: false);
    addTearDown(container.dispose);
    api.next = _offer();
    container.read(offersProvider); // created before app-config arrived
    await container.read(offersProvider.notifier).refresh();
    expect(api.calls, 0);
    container.read(_flag.notifier).state = true;
    await Future<void>.delayed(Duration.zero);
    expect(api.calls, 1);
    expect(gate(OfferSurface.momentsChip), isA<OfferGateShow>());
  });

  test('Offer.fromJson returns null for a missing id, unknown shape or bad date',
      () {
    final good = {
      'id': 'o1',
      'surface': 'moments_chip',
      'placement': 'vip_entry',
      'lead': 'coins',
      'validUntil': '2026-11-14T10:00:00.000Z',
    };
    final parsed = Offer.fromJson(good)!;
    expect(parsed.id, 'o1');
    expect(parsed.lead, 'coins');
    expect(parsed.validUntil, DateTime.utc(2026, 11, 14, 10));

    expect(Offer.fromJson({...good}..remove('id')), isNull);
    expect(Offer.fromJson({...good, 'id': ''}), isNull);
    expect(Offer.fromJson({...good, 'surface': 'home_banner'}), isNull);
    expect(Offer.fromJson({...good, 'lead': 'ads'}), isNull);
    expect(Offer.fromJson({...good}..remove('placement')), isNull);
    expect(Offer.fromJson({...good, 'validUntil': 'tomorrow'}), isNull);
    expect(Offer.fromJson({...good, 'validUntil': 123}), isNull);
    expect(Offer.fromJson('o1'), isNull);
    expect(Offer.fromJson(null), isNull);
    expect(Offer.fromJson([good]), isNull);
  });

  test('offerFromResponse reads the first offer of a 200 only', () {
    final item = {
      'id': 'o1',
      'surface': 'matches_empty',
      'placement': 'matches_empty',
      'lead': 'vip',
      'validUntil': '2026-11-14T10:00:00.000Z',
    };
    ApiResponse res(int code, Object? data) =>
        ApiResponse(success: code == 200, statusCode: code, data: data);
    expect(
      offerFromResponse(res(200, {'success': true, 'offers': [item]}))?.id,
      'o1',
    );
    expect(offerFromResponse(res(200, {'success': true, 'offers': []})), isNull);
    expect(offerFromResponse(res(200, {'success': true})), isNull);
    expect(offerFromResponse(res(200, 'nope')), isNull);
    expect(offerFromResponse(res(404, {'success': false})), isNull);
  });

  test('one flow per offer id: same flowId across reads, new id for a new offer',
      () async {
    container = make();
    addTearDown(container.dispose);
    final n = container.read(offersProvider.notifier);
    api.next = _offer(id: 'o1');
    await n.refresh();
    final a = gate(OfferSurface.momentsChip) as OfferGateShow;
    await n.refresh(force: true); // same offer again: a new Offer object
    final b = gate(OfferSurface.momentsChip) as OfferGateShow;
    expect(b.flow.flowId, a.flow.flowId);
    expect(a.flow.offerId, 'o1');
    expect(a.flow.placement, 'vip_entry');
    expect(a.flow.detail, OfferSurface.momentsChip);

    api.next = _offer(id: 'o2');
    await n.refresh(force: true);
    final c = gate(OfferSurface.momentsChip) as OfferGateShow;
    expect(c.flow.offerId, 'o2');
    expect(c.flow.flowId, isNot(a.flow.flowId));

    // The flow outlives the container (process-wide), e.g. across sign-out.
    container.invalidate(offersProvider);
    api.next = _offer(id: 'o1');
    await container.read(offersProvider.notifier).refresh(force: true);
    final d = gate(OfferSurface.momentsChip) as OfferGateShow;
    expect(d.flow.flowId, a.flow.flowId);
  });
}
