import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

/// The Topics filter in the sheet was saved but never sent: the partner list
/// stayed the same. It must reach /auth/users the way the sheet's live count
/// sends it (comma-separated topics + topicsAtLeast).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({'token': 'jwt'}));

  Future<Uri> requestFor({List<String> topics = const [], int atLeast = 0}) async {
    late Uri seen;
    await http.runWithClient(
      () => CommunityService().getUsersPage(
        PartnerFilterParams(topics: topics, topicsAtLeast: atLeast)
            .toQuery(page: 1, limit: 20),
      ),
      () => MockClient((req) async {
        seen = req.url;
        return http.Response(
            jsonEncode({'success': true, 'data': [], 'total': 0, 'pages': 1}),
            200);
      }),
    );
    return seen;
  }

  test('selected topics and the minimum go to the list request', () async {
    final url = await requestFor(topics: ['travel', 'music'], atLeast: 2);
    expect(url.queryParameters['topics'], 'travel,music');
    expect(url.queryParameters['topicsAtLeast'], '2');
  });

  test('no topics: neither parameter is sent', () async {
    final url = await requestFor();
    expect(url.queryParameters.containsKey('topics'), isFalse);
    expect(url.queryParameters.containsKey('topicsAtLeast'), isFalse);
  });

  test('changing topics is a filter change (the list reloads)', () {
    expect(const PartnerFilterParams(topics: ['travel']),
        isNot(const PartnerFilterParams()));
    expect(const PartnerFilterParams(topicsAtLeast: 2),
        isNot(const PartnerFilterParams()));
    expect(PartnerFilterParams(topics: ['travel'].toList()),
        const PartnerFilterParams(topics: ['travel']));
  });
}
