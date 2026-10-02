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
  const ReferralRejectedException(this.message);
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
      throw ReferralRejectedException(_errorOf(r));
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

/// Claims a stored invite code after profile completion. Fire-and-forget:
/// never throws. Clears the key on success or any 4xx; keeps it on network
/// failure. Returns coins earned by the invitee (0 if none/failed).
Future<int> claimPendingReferral(ReferralService service) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(pendingReferralPrefsKey);
    if (code == null || code.isEmpty) return 0;
    try {
      final res = await service.claim(code);
      await prefs.remove(pendingReferralPrefsKey);
      return res.invitee;
    } on ReferralRejectedException {
      await prefs.remove(pendingReferralPrefsKey);
    }
  } catch (_) {}
  return 0;
}
