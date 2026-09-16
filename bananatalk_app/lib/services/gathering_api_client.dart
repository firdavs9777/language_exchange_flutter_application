import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// Outcome of a write. Mutations here carry *meaningful* refusals — "this
/// gathering is full", "join the club before hosting for it", "you have
/// cancelled or missed too many of your own gatherings" — so unlike the read
/// paths they must not collapse to null. The host who cannot create needs to
/// be told why, not shown a silent no-op.
class GatheringResult<T> {
  final T? value;
  final String? error;

  const GatheringResult.ok(this.value) : error = null;
  const GatheringResult.failed(this.error) : value = null;

  bool get success => error == null;
}

/// The result of an RSVP: the gathering with its new quorum state, plus
/// whether this landed as a pending *request* (join mode `approval`) rather
/// than a seat.
class GatheringRsvp {
  final Gathering gathering;
  final bool pending;

  const GatheringRsvp({required this.gathering, this.pending = false});
}

/// REST client for 모임 (`/api/v1/gatherings` and `/api/v1/clubs`).
///
/// Thin wrapper over [ApiClient], which already owns auth headers, token
/// refresh and rate-limit handling — same shape as `RoomApiClient`.
///
/// Every endpoint here sits behind the server's `GATHERINGS_ENABLED` switch
/// and 404s as a block when it is off, so a flipped switch degrades to an
/// empty list rather than an error state.
class GatheringApiClient {
  final ApiClient _apiClient = ApiClient();

  // ---------------------------------------------------------------- gatherings

  /// GET /gatherings — the default view is "starting soon, in a language I
  /// speak or am learning". Passing no [language] and leaving [scope] at
  /// `mine` is what produces it; `scope: 'all'` widens to every language,
  /// which is the manual escape hatch, not the default.
  Future<List<Gathering>> getGatherings({
    String? language,
    String? level,
    String scope = 'mine',
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        'gatherings',
        queryParams: {
          if (language != null && language.isNotEmpty) 'language': language,
          if (level != null && level.isNotEmpty) 'level': level,
          'scope': scope,
          'page': page.toString(),
        },
      );
      if (!response.success) {
        debugPrint('[GatheringApiClient] getGatherings: ${response.error}');
        return [];
      }
      return _listOf(response.data)
          .map((g) => Gathering.fromJson(Map<String, dynamic>.from(g as Map)))
          .toList();
    } catch (e) {
      debugPrint('[GatheringApiClient] getGatherings error: $e');
      return [];
    }
  }

  /// GET /gatherings/:id
  Future<Gathering?> getGathering(String id) async {
    try {
      final response = await _apiClient.get('gatherings/$id');
      if (!response.success) return null;
      final data = _mapOf(response.data);
      return data == null ? null : Gathering.fromJson(data);
    } catch (e) {
      debugPrint('[GatheringApiClient] getGathering error: $e');
      return null;
    }
  }

  /// POST /gatherings. [language] is sent as the host typed it; the backend
  /// stores the matched base code and keeps the raw string for display.
  Future<GatheringResult<Gathering>> createGathering({
    required String title,
    required String language,
    required DateTime startsAt,
    String description = '',
    String? level,
    int durationMinutes = 60,
    int capacity = 6,
    int quorum = 3,
    String joinMode = 'open',
    String? clubId,
  }) async {
    try {
      final response = await _apiClient.post(
        'gatherings',
        body: {
          'title': title,
          'language': language,
          // UTC on the wire; every render converts back to the viewer's zone.
          'startsAt': startsAt.toUtc().toIso8601String(),
          'description': description,
          if (level != null && level.isNotEmpty) 'level': level,
          'durationMinutes': durationMinutes,
          'capacity': capacity,
          'quorum': quorum,
          'joinMode': joinMode,
          if (clubId != null && clubId.isNotEmpty) 'club': clubId,
        },
      );
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not create');
      }
      final data = _mapOf(response.data);
      if (data == null) return const GatheringResult.failed('Could not create');
      return GatheringResult.ok(Gathering.fromJson(data));
    } catch (e) {
      debugPrint('[GatheringApiClient] createGathering error: $e');
      return GatheringResult.failed(e.toString());
    }
  }

  /// POST /gatherings/:id/rsvp — the transition that is the whole product.
  /// The returned gathering carries the new quorum state, including a
  /// `scheduled` → `confirmed` flip this RSVP may have caused.
  ///
  /// On an `approval` gathering the RSVP lands as a *request*, which the
  /// gathering itself cannot express (`viewerIsAttending` stays false either
  /// way), so the backend's `pending` flag is carried out separately. Without
  /// it, asking to join an approval gathering looks identical to the tap
  /// having done nothing.
  Future<GatheringResult<GatheringRsvp>> rsvp(String id) async {
    try {
      final response = await _apiClient.post('gatherings/$id/rsvp');
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not RSVP');
      }
      final body = response.data;
      final data = _mapOf(body);
      if (data == null) return const GatheringResult.failed('Could not RSVP');
      return GatheringResult.ok(
        GatheringRsvp(
          gathering: Gathering.fromJson(data),
          pending: body is Map && body['pending'] == true,
        ),
      );
    } catch (e) {
      debugPrint('[GatheringApiClient] rsvp error: $e');
      return GatheringResult.failed(e.toString());
    }
  }

  /// DELETE /gatherings/:id/rsvp
  Future<GatheringResult<Gathering>> cancelRsvp(String id) =>
      _mutate('gatherings/$id/rsvp', method: 'DELETE');

  /// DELETE /gatherings/:id — host cancels. Every attendee is notified by
  /// push *and* email: they arranged their evening around it.
  Future<GatheringResult<Gathering>> cancelGathering(String id) =>
      _mutate('gatherings/$id', method: 'DELETE');

  /// POST /gatherings/:id/decision — the T-2h question, answered out loud.
  /// [runAnyway] false cancels it.
  Future<GatheringResult<Gathering>> hostDecision(
    String id, {
    required bool runAnyway,
  }) => _mutate('gatherings/$id/decision', body: {'run': runAnyway});

  /// POST /gatherings/:id/end — produces the attendee card. Attendee ids come
  /// back alongside the gathering, so they are returned separately.
  Future<GatheringResult<List<String>>> endGathering(String id) async {
    try {
      final response = await _apiClient.post('gatherings/$id/end');
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not end');
      }
      final body = response.data;
      final attendees = body is Map ? body['attendees'] : null;
      return GatheringResult.ok(
        attendees is List
            ? attendees.map((a) => a.toString()).toList()
            : const <String>[],
      );
    } catch (e) {
      debugPrint('[GatheringApiClient] endGathering error: $e');
      return GatheringResult.failed(e.toString());
    }
  }

  /// POST /gatherings/:id/requests/:userId — approve or deny, for
  /// `approval` join mode.
  Future<GatheringResult<Gathering>> decideJoinRequest(
    String id,
    String userId, {
    required bool approve,
  }) => _mutate(
    'gatherings/$id/requests/$userId',
    body: {'approve': approve},
  );

  /// DELETE /gatherings/:id/attendees/:userId — host removes someone.
  Future<GatheringResult<Gathering>> removeParticipant(
    String id,
    String userId,
  ) => _mutate('gatherings/$id/attendees/$userId', method: 'DELETE');

  // --------------------------------------------------------------------- clubs

  /// GET /clubs — active clubs in a language the viewer speaks or is
  /// learning, busiest first.
  Future<List<Club>> getClubs({
    String? language,
    String? interest,
    String scope = 'mine',
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        'clubs',
        queryParams: {
          if (language != null && language.isNotEmpty) 'language': language,
          if (interest != null && interest.isNotEmpty) 'interest': interest,
          'scope': scope,
          'page': page.toString(),
        },
      );
      if (!response.success) {
        debugPrint('[GatheringApiClient] getClubs: ${response.error}');
        return [];
      }
      return _listOf(response.data)
          .map((c) => Club.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    } catch (e) {
      debugPrint('[GatheringApiClient] getClubs error: $e');
      return [];
    }
  }

  /// GET /clubs/:id — the club plus what it has coming up.
  Future<Club?> getClub(String id) async {
    try {
      final response = await _apiClient.get('clubs/$id');
      if (!response.success) return null;
      final data = _mapOf(response.data);
      return data == null ? null : Club.fromJson(data);
    } catch (e) {
      debugPrint('[GatheringApiClient] getClub error: $e');
      return null;
    }
  }

  /// POST /clubs — the creator is member #1.
  Future<GatheringResult<Club>> createClub({
    required String name,
    required String language,
    String description = '',
    String interest = '',
  }) async {
    try {
      final response = await _apiClient.post(
        'clubs',
        body: {
          'name': name,
          'language': language,
          'description': description,
          'interest': interest,
        },
      );
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not create');
      }
      final data = _mapOf(response.data);
      if (data == null) return const GatheringResult.failed('Could not create');
      return GatheringResult.ok(Club.fromJson(data));
    } catch (e) {
      debugPrint('[GatheringApiClient] createClub error: $e');
      return GatheringResult.failed(e.toString());
    }
  }

  /// POST /clubs/:id/join — one tap, no approval. Membership is deliberately
  /// cheap and is NOT a capability: it never exempts anyone from the
  /// conversation cap. Only attending a gathering does that.
  Future<GatheringResult<Club>> joinClub(String id) async =>
      _mutateClub('clubs/$id/join');

  /// DELETE /clubs/:id/join
  Future<GatheringResult<Club>> leaveClub(String id) async =>
      _mutateClub('clubs/$id/join', method: 'DELETE');

  // ------------------------------------------------------------------- helpers

  Future<GatheringResult<Gathering>> _mutate(
    String endpoint, {
    String method = 'POST',
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = method == 'DELETE'
          ? await _apiClient.delete(endpoint, body: body)
          : await _apiClient.post(endpoint, body: body);
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Something went wrong');
      }
      final data = _mapOf(response.data);
      if (data == null) {
        return const GatheringResult.failed('Something went wrong');
      }
      return GatheringResult.ok(Gathering.fromJson(data));
    } catch (e) {
      debugPrint('[GatheringApiClient] $endpoint error: $e');
      return GatheringResult.failed(e.toString());
    }
  }

  Future<GatheringResult<Club>> _mutateClub(
    String endpoint, {
    String method = 'POST',
  }) async {
    try {
      final response = method == 'DELETE'
          ? await _apiClient.delete(endpoint)
          : await _apiClient.post(endpoint);
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Something went wrong');
      }
      final data = _mapOf(response.data);
      if (data == null) {
        return const GatheringResult.failed('Something went wrong');
      }
      return GatheringResult.ok(Club.fromJson(data));
    } catch (e) {
      debugPrint('[GatheringApiClient] $endpoint error: $e');
      return GatheringResult.failed(e.toString());
    }
  }

  List<dynamic> _listOf(dynamic body) {
    if (body is Map && body['data'] is List) return body['data'] as List;
    if (body is List) return body;
    return const [];
  }

  Map<String, dynamic>? _mapOf(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }
}
