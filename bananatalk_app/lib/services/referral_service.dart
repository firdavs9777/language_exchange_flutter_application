import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';

class ReferralInfo {
  final String code;
  final String link;
  final int invited;
  const ReferralInfo({
    required this.code,
    required this.link,
    required this.invited,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => ReferralInfo(
    code: (json['code'] as String?) ?? '',
    link: (json['link'] as String?) ?? '',
    invited: (json['invited'] as num?)?.toInt() ?? 0,
  );
}

class ReferralClaimResult {
  final int inviter;
  final int invitee;
  final bool resumed;
  const ReferralClaimResult({
    required this.inviter,
    required this.invitee,
    this.resumed = false,
  });
}

/// Thrown for a 4xx claim response; the claim will never succeed on retry.
class ReferralRejectedException implements Exception {
  final String message;
  final int? statusCode;

  /// Machine-readable body code (`feature_disabled`, `unknown_code`), if any.
  final String? code;
  const ReferralRejectedException(this.message, {this.statusCode, this.code});
  @override
  String toString() => message;
}

class ReferralService {
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String? _codeOf(http.Response r) {
    try {
      final body = json.decode(r.body);
      if (body is Map && body['code'] is String) return body['code'] as String;
    } catch (_) {}
    return null;
  }

  String _errorOf(http.Response r) {
    try {
      final body = json.decode(r.body);
      if (body is Map && body['error'] is String)
        return body['error'] as String;
    } catch (_) {}
    return 'Request failed (${r.statusCode})';
  }

  Future<ReferralInfo> getMine() async {
    final r = await http.get(
      Uri.parse('${Endpoints.baseURL}referrals/me'),
      headers: await _headers(),
    );
    if (r.statusCode != 200) throw Exception(_errorOf(r));
    final body = json.decode(r.body) as Map<String, dynamic>;
    return ReferralInfo.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 4xx throws [ReferralRejectedException]; network/5xx errors throw other
  /// exceptions (callers keep the pending code for those).
  Future<ReferralClaimResult> claim(String code) async {
    final r = await http.post(
      Uri.parse('${Endpoints.baseURL}referrals/claim'),
      headers: await _headers(),
      body: json.encode({'code': code}),
    );
    if (r.statusCode >= 400 && r.statusCode < 500) {
      throw ReferralRejectedException(
        _errorOf(r),
        statusCode: r.statusCode,
        code: _codeOf(r),
      );
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(_errorOf(r));
    }
    final body = json.decode(r.body) as Map<String, dynamic>;
    final credited =
        (body['data']?['credited'] as Map?)?.cast<String, dynamic>() ?? {};
    return ReferralClaimResult(
      inviter: (credited['inviter'] as num?)?.toInt() ?? 0,
      invitee: (credited['invitee'] as num?)?.toInt() ?? 0,
      resumed: credited['resumed'] == true,
    );
  }
}

final referralServiceProvider = Provider<ReferralService>(
  (ref) => ReferralService(),
);

const pendingReferralPrefsKey = 'pending_referral_code';

/// Body code on the 404 the referrals guard returns while REFERRALS_ENABLED
/// is off.
const referralFeatureDisabledCode = 'feature_disabled';

/// Body code on the 404 for a code that matches no inviter.
const referralUnknownCode = 'unknown_code';

/// Whether a rejected claim should drop the stored code. A 4xx is final —
/// except a 404 meaning "feature unavailable": `code: 'feature_disabled'`, or
/// no code at all (an older server, or one without the route). The code must
/// survive until the feature is on. `unknown_code` and every other 4xx clear.
bool shouldClearPendingReferralOnRejection(ReferralRejectedException e) {
  if (e.statusCode == 404) {
    return e.code != null && e.code != referralFeatureDisabledCode;
  }
  return true;
}

/// Whether the `/invite/:code` deep link should store [code] for a later
/// claim. Not when a session token already exists: an already-registered
/// user can't claim, and a stored code could later be claimed by whichever
/// account registers next on this device.
bool shouldStorePendingReferral({
  required String? code,
  required String? sessionToken,
}) {
  if (code == null || code.isEmpty) return false;
  return sessionToken == null || sessionToken.isEmpty;
}

/// Claims a stored invite code after profile completion. Fire-and-forget:
/// never throws. Clears the key on success or any final 4xx; keeps it on
/// network/5xx failure and on a feature-off 404. Returns coins earned by the
/// invitee (0 if none/failed).
Future<int> claimPendingReferral(ReferralService service) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(pendingReferralPrefsKey);
    if (code == null || code.isEmpty) return 0;
    try {
      final res = await service.claim(code);
      await prefs.remove(pendingReferralPrefsKey);
      return res.invitee;
    } on ReferralRejectedException catch (e) {
      if (shouldClearPendingReferralOnRejection(e)) {
        await prefs.remove(pendingReferralPrefsKey);
      }
    }
  } catch (_) {}
  return 0;
}
