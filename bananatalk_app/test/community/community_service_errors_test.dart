import 'dart:convert';

import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Community errors used to be wrapped twice ("Failed to load community:
/// Exception: Failed to load user: 500"), which friendlyErrorMessage could
/// not read. The server's own message comes through once now.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 't', 'userId': 'u1'});
  });

  final server = MockClient(
    (req) async => http.Response(jsonEncode({'error': 'Server down'}), 500),
  );

  test('a profile load error carries the server message, once', () async {
    Object? error;
    await http.runWithClient(() async {
      try {
        await CommunityService().getSingleCommunity(id: 'x');
      } catch (e) {
        error = e;
      }
    }, () => server);
    expect(error.toString(), contains('Server down'));
    expect(error.toString(), isNot(contains('Failed to load community')));
  });

  test('a list page error carries the server message, once', () async {
    Object? error;
    await http.runWithClient(() async {
      try {
        await CommunityService().getUsersPage({'page': '1'});
      } catch (e) {
        error = e;
      }
    }, () => server);
    expect(error.toString(), contains('Server down'));
    expect(error.toString(), isNot(contains('Exception: Exception')));
  });
}
