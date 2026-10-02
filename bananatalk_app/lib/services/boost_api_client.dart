import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/service/endpoints.dart';

enum BoostError { insufficientCoins, alreadyBoosted, capacityFull }

/// Thrown by [BoostApiClient.purchaseProfileBoost] for the three typed
/// refusals; any other failure throws a plain [Exception].
class BoostException implements Exception {
  const BoostException(this.error);
  final BoostError error;
  @override
  String toString() => 'BoostException($error)';
}

/// REST client for `/boosts` (deployed dark behind `boostsEnabled`).
///   POST /boosts {kind:'profile'} -> 201 {data:{boost}} | 402 insufficient_coins
///                                    | 409 already_boosted | 429 capacity_full
///   GET  /boosts/active           -> {data:{boost: Boost|null}}
///   GET  /boosts/history          -> {data:{boosts: [...]}}
class BoostApiClient {
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _body(http.Response r) {
    final body = json.decode(r.body);
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  Future<Boost> purchaseProfileBoost() async {
    final r = await http.post(
      Uri.parse('${Endpoints.baseURL}boosts'),
      headers: await _headers(),
      body: json.encode({'kind': 'profile'}),
    );
    if (r.statusCode == 201 || r.statusCode == 200) {
      final boost = _body(r)['data']?['boost'];
      if (boost is Map<String, dynamic>) return Boost.fromJson(boost);
      throw Exception('Malformed boost response');
    }
    switch (r.statusCode) {
      case 402:
        throw const BoostException(BoostError.insufficientCoins);
      case 409:
        throw const BoostException(BoostError.alreadyBoosted);
      case 429:
        throw const BoostException(BoostError.capacityFull);
    }
    throw Exception('Boost failed (${r.statusCode})');
  }

  Future<Boost?> getActive() async {
    final r = await http.get(
      Uri.parse('${Endpoints.baseURL}boosts/active'),
      headers: await _headers(),
    );
    if (r.statusCode != 200)
      throw Exception('Boost status failed (${r.statusCode})');
    final boost = _body(r)['data']?['boost'];
    return boost is Map<String, dynamic> ? Boost.fromJson(boost) : null;
  }

  Future<List<Boost>> getHistory() async {
    final r = await http.get(
      Uri.parse('${Endpoints.baseURL}boosts/history'),
      headers: await _headers(),
    );
    if (r.statusCode != 200)
      throw Exception('Boost history failed (${r.statusCode})');
    final rows = _body(r)['data']?['boosts'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) Boost.fromJson(row),
    ];
  }
}

final boostApiClientProvider = Provider<BoostApiClient>(
  (ref) => BoostApiClient(),
);
