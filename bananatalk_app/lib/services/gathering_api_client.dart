import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart' show lookupMimeType;
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
    String? topic,
    String? when,
    bool hasSeat = false,
  }) async {
    try {
      final response = await _apiClient.get(
        'gatherings',
        queryParams: {
          if (language != null && language.isNotEmpty) 'language': language,
          if (level != null && level.isNotEmpty) 'level': level,
          'scope': scope,
          if (topic != null && topic.isNotEmpty) 'topic': topic,
          if (when != null && when.isNotEmpty) 'when': when,
          // Only sent when on: the server treats anything but 'true' as off,
          // and an always-present 'false' is noise in the request log.
          if (hasSeat) 'hasSeat': 'true',
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
    String? topic,
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
          if (topic != null && topic.isNotEmpty) 'topic': topic,
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

  /// PUT /gatherings/:id — host edits their own gathering.
  ///
  /// Partial: only the fields passed are sent, so a caller changing the time
  /// cannot accidentally blank the description. Sent as PUT rather than PATCH
  /// because ApiClient has no patch verb; the route accepts both.
  Future<GatheringResult<Gathering>> updateGathering(
    String id, {
    String? title,
    String? description,
    String? language,
    String? level,
    DateTime? startsAt,
    int? durationMinutes,
    int? capacity,
    String? joinMode,
    String? topic,
  }) async {
    try {
      final response = await _apiClient.put(
        'gatherings/$id',
        body: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (language != null) 'language': language,
          if (level != null) 'level': level,
          // UTC on the wire; every render converts back to the viewer's zone.
          if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (capacity != null) 'capacity': capacity,
          if (joinMode != null) 'joinMode': joinMode,
          // Sent whenever the caller passed the field at all, including null,
          // because null is how a topic is CLEARED.
          if (topic != null) 'topic': topic,
        },
      );
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not save');
      }
      final data = _mapOf(response.data);
      if (data == null) return const GatheringResult.failed('Could not save');
      return GatheringResult.ok(Gathering.fromJson(data));
    } catch (e) {
      debugPrint('[GatheringApiClient] updateGathering error: $e');
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
  }) => _mutate('gatherings/$id/requests/$userId', body: {'approve': approve});

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
      return _listOf(
        response.data,
      ).map((c) => Club.fromJson(Map<String, dynamic>.from(c as Map))).toList();
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

  /// PUT /clubs/:id — owner or organizer.
  ///
  /// Language is deliberately absent: it is the discovery spine, and every
  /// member joined a club in a language they chose.
  Future<GatheringResult<Club>> updateClub(
    String id, {
    String? name,
    String? description,
    String? interest,
    String? city,
    String? placeName,
    String? placeAddress,
  }) async {
    try {
      final response = await _apiClient.put('clubs/$id', body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (interest != null) 'interest': interest,
        if (city != null) 'city': city,
        if (placeName != null || placeAddress != null)
          'place': {'name': placeName, 'address': placeAddress},
      });
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not save');
      }
      final data = _mapOf(response.data);
      if (data == null) return const GatheringResult.failed('Could not save');
      return GatheringResult.ok(Club.fromJson(data));
    } catch (e) {
      debugPrint('[GatheringApiClient] updateClub error: $e');
      return const GatheringResult.failed('Could not save');
    }
  }

  /// POST /clubs/:id/cover — owner or organizer.
  ///
  /// Optional everywhere: a club without a cover is normal, so failure here
  /// never blocks anything the user was doing — it reports and leaves the club
  /// exactly as it was.
  Future<GatheringResult<String>> uploadClubCover(String id, File image) =>
      _uploadCover('clubs/$id/cover', image);

  /// DELETE /clubs/:id/cover
  Future<GatheringResult<bool>> removeClubCover(String id) =>
      _removeCover('clubs/$id/cover');

  /// POST /gatherings/:id/cover — host only.
  Future<GatheringResult<String>> uploadGatheringCover(String id, File image) =>
      _uploadCover('gatherings/$id/cover', image);

  /// DELETE /gatherings/:id/cover
  Future<GatheringResult<bool>> removeGatheringCover(String id) =>
      _removeCover('gatherings/$id/cover');

  /// Shared so clubs and gatherings cannot drift: the field name, the response
  /// shape and the failure handling are identical on both, and two copies of
  /// that is how they stop being identical.
  Future<GatheringResult<String>> _uploadCover(String path, File image) async {
    try {
      // MultipartFile.fromPath defaults to application/octet-stream, which
      // multer's fileFilter rejects outright — and that rejection surfaces as
      // a 500, not a 400, so it looks like a server fault. Sniff the real type
      // from the extension, exactly as the pronunciation upload does.
      final mime = lookupMimeType(image.path) ?? 'image/jpeg';
      final response = await _apiClient.postMultipart(
        path,
        fields: const {},
        files: [
          await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: MediaType.parse(mime),
          ),
        ],
      );
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not upload');
      }
      final data = _mapOf(response.data);
      final url = data?['coverImage']?.toString();
      if (url == null || url.isEmpty) {
        return const GatheringResult.failed('Could not upload');
      }
      return GatheringResult.ok(url);
    } catch (e) {
      debugPrint('[GatheringApiClient] uploadCover error: $e');
      return const GatheringResult.failed('Could not upload');
    }
  }

  Future<GatheringResult<bool>> _removeCover(String path) async {
    try {
      final response = await _apiClient.delete(path);
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not remove');
      }
      return const GatheringResult.ok(true);
    } catch (e) {
      debugPrint('[GatheringApiClient] removeCover error: $e');
      return const GatheringResult.failed('Could not remove');
    }
  }

  /// DELETE /clubs/:id — owner only. Its gatherings are detached, not
  /// cancelled: people have already RSVP'd to them.
  Future<GatheringResult<bool>> deleteClub(String id) async {
    try {
      final response = await _apiClient.delete('clubs/$id');
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not delete');
      }
      return const GatheringResult.ok(true);
    } catch (e) {
      debugPrint('[GatheringApiClient] deleteClub error: $e');
      return const GatheringResult.failed('Could not delete');
    }
  }

  /// DELETE /clubs/:id/members/:userId — owner or organizer.
  Future<GatheringResult<bool>> removeClubMember(String clubId, String userId) async {
    try {
      final response = await _apiClient.delete('clubs/$clubId/members/$userId');
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not remove');
      }
      return const GatheringResult.ok(true);
    } catch (e) {
      debugPrint('[GatheringApiClient] removeClubMember error: $e');
      return const GatheringResult.failed('Could not remove');
    }
  }

  /// PUT /clubs/:id/members/:userId — owner only.
  Future<GatheringResult<bool>> setClubMemberRole(
    String clubId,
    String userId, {
    required String role,
  }) async {
    try {
      final response = await _apiClient.put(
        'clubs/$clubId/members/$userId',
        body: {'role': role},
      );
      if (!response.success) {
        return GatheringResult.failed(response.error ?? 'Could not update role');
      }
      return const GatheringResult.ok(true);
    } catch (e) {
      debugPrint('[GatheringApiClient] setClubMemberRole error: $e');
      return const GatheringResult.failed('Could not update role');
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
