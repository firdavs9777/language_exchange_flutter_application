import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bananatalk_app/providers/provider_models/location_modal.dart';
import 'package:bananatalk_app/providers/provider_models/users_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/service/endpoints.dart';

User _user(String email) => User(
      name: 'Ann',
      password: 'Password1',
      email: email,
      bio: '',
      images: const [],
      birth_day: '04',
      birth_month: '07',
      gender: 'female',
      birth_year: '1995',
      native_language: 'Korean',
      language_to_learn: 'English',
      location: LocationModal(
        type: 'Point',
        coordinates: const [0.0, 0.0],
        formattedAddress: '',
        city: '',
        country: '',
      ),
    );

/// verify-code answers [verifyBody]; /register records its body and refuses
/// (keeps the success path's socket/prefs side effects out of the test).
Future<Map<String, dynamic>> _registerBodyAfterVerify(
  Map<String, dynamic> verifyBody, {
  String verifiedEmail = 'ann@example.com',
  String registerEmail = 'ann@example.com',
}) async {
  Map<String, dynamic>? sent;
  final auth = AuthService();
  await http.runWithClient(() async {
    await auth.verifyEmailCode(email: verifiedEmail, code: '123456');
    await auth.register(_user(registerEmail));
  }, () => MockClient((req) async {
        if (req.url.path.endsWith(Endpoints.verifyEmailCode)) {
          return http.Response(jsonEncode(verifyBody), 200);
        }
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'message': 'no'}), 400);
      }));
  return sent!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the token from verify-code is sent with /register', () async {
    final body = await _registerBodyAfterVerify(
        {'success': true, 'registrationToken': 'reg-jwt'});
    expect(body['registrationToken'], 'reg-jwt');
  });

  test('a token nested under data is picked up too', () async {
    final body = await _registerBodyAfterVerify({
      'success': true,
      'data': {'registrationToken': 'reg-jwt-2'},
    });
    expect(body['registrationToken'], 'reg-jwt-2');
  });

  test('an older server sends none, and nothing is sent back', () async {
    final body = await _registerBodyAfterVerify({'success': true});
    expect(body.containsKey('registrationToken'), isFalse);
  });

  test('the token is bound to the verified email', () async {
    final body = await _registerBodyAfterVerify(
      {'success': true, 'registrationToken': 'reg-jwt'},
      verifiedEmail: 'Ann@Example.com ',
      registerEmail: 'other@example.com',
    );
    expect(body.containsKey('registrationToken'), isFalse);
  });
}
