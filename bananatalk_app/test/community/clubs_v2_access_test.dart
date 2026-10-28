import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_root/clubs_v2_provider.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';

class _FakeApi extends GatheringApiClient {
  _FakeApi(this.answer);
  final Future<bool> Function() answer;
  @override
  Future<bool> getClubsV2Access() => answer();
}

/// Anything but an explicit `clubsV2: true` means "no access": the new UI
/// must never appear because a request failed.
void main() {
  test('reads clubsV2 from the response', () {
    expect(
      GatheringApiClient.clubsV2AccessFrom(
          ApiResponse(success: true, statusCode: 200, data: {'clubsV2': true})),
      isTrue,
    );
    expect(
      GatheringApiClient.clubsV2AccessFrom(
          ApiResponse(success: true, statusCode: 200, data: {'clubsV2': false})),
      isFalse,
    );
  });

  test('a 404 (switch off or old backend) or an odd body is no access', () {
    expect(
      GatheringApiClient.clubsV2AccessFrom(
          ApiResponse(success: false, statusCode: 404, error: 'Not found')),
      isFalse,
    );
    expect(
      GatheringApiClient.clubsV2AccessFrom(
          ApiResponse(success: true, statusCode: 200, data: 'yes')),
      isFalse,
    );
  });

  test('the provider answers false when the call throws', () async {
    final container = ProviderContainer(overrides: [
      clubsV2ApiProvider.overrideWithValue(_FakeApi(() async => throw Exception('offline'))),
    ]);
    addTearDown(container.dispose);
    expect(await container.read(clubsV2AccessProvider.future), isFalse);
  });

  test('the provider answers true when the server says so', () async {
    final container = ProviderContainer(overrides: [
      clubsV2ApiProvider.overrideWithValue(_FakeApi(() async => true)),
    ]);
    addTearDown(container.dispose);
    expect(await container.read(clubsV2AccessProvider.future), isTrue);
  });
}
