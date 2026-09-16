/// 모임 — Clubs and Gatherings.
///
/// A [Club] is the primary entity: a standing group keyed on a language plus
/// an optional free-text interest. A [Gathering] is a scheduled thing a club
/// hosts — or, for the first ones seeded by hand, a thing that stands alone.
///
/// Why the club leads: an empty list of events reads as abandoned, which is
/// exactly the impression that killed voice rooms 93 times. "Korean Learners
/// Club · 49 members" looks alive with nothing scheduled at all.
///
/// Both mirror the backend's public shape (`present()` in
/// `controllers/gatherings.js` and `controllers/clubs.js`) — notably the
/// quorum fields, which are public on purpose: "2 more needed to confirm"
/// turns an RSVP from a gamble into a contribution.
library;

import 'package:bananatalk_app/utils/string_sanitizer.dart';

/// The person who owns a club or hosts a gathering, as the backend populates
/// them (`name username images`). Shared by both entities because both render
/// the same little avatar-and-name row.
class GatheringHost {
  final String id;
  final String name;
  final String username;
  final String avatar;

  const GatheringHost({
    this.id = '',
    this.name = '',
    this.username = '',
    this.avatar = '',
  });

  /// Accepts either a populated object or a bare id string — list endpoints
  /// populate, but some write endpoints echo back the raw ObjectId.
  factory GatheringHost.fromJson(dynamic json) {
    if (json is String) return GatheringHost(id: json);
    if (json is! Map) return const GatheringHost();
    final map = Map<String, dynamic>.from(json);
    var avatar = '';
    final images = map['images'];
    if (images is List && images.isNotEmpty) {
      avatar = images.first?.toString() ?? '';
    }
    return GatheringHost(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      name: sanitize(map['name']),
      username: sanitize(map['username']),
      avatar: avatar,
    );
  }
}

/// The five-state machine from the spec. `live` is reachable only once Task 7
/// (start → VoiceRoom) lands, so it is parsed but never produced by the app.
enum GatheringStatus { scheduled, confirmed, live, ended, cancelled }

GatheringStatus _statusFrom(String? raw) {
  switch (raw) {
    case 'confirmed':
      return GatheringStatus.confirmed;
    case 'live':
      return GatheringStatus.live;
    case 'ended':
      return GatheringStatus.ended;
    case 'cancelled':
      return GatheringStatus.cancelled;
    default:
      return GatheringStatus.scheduled;
  }
}

class Gathering {
  final String id;
  final String type;
  final GatheringHost host;
  final String title;
  final String description;

  /// The base code the backend matched on (`matchKey`), not what the host
  /// typed. Never render this — render [languageLabel].
  final String language;

  /// What the host typed. Display only.
  final String languageLabel;

  /// Optional CEFR band, so beginners are not dropped into a C1 conversation.
  final String? level;

  final DateTime startsAt;
  final int durationMinutes;

  /// The host's IANA zone. Rendered *beneath* the viewer's own local time —
  /// an ambiguous time across Shanghai/Seoul/Europe is a guaranteed no-show.
  final String? hostTimezone;

  final int capacity;
  final int quorum;
  final String joinMode;
  final GatheringStatus status;

  /// Public quorum state. [needed] is how many more `going` RSVPs would flip
  /// this to confirmed; zero once [quorumMet].
  final int going;
  final int needed;
  final bool quorumMet;

  final String? repeatedFrom;
  final bool viewerIsAttending;
  final bool viewerIsHost;

  const Gathering({
    required this.id,
    required this.title,
    required this.startsAt,
    this.type = 'online_event',
    this.host = const GatheringHost(),
    this.description = '',
    this.language = '',
    this.languageLabel = '',
    this.level,
    this.durationMinutes = 60,
    this.hostTimezone,
    this.capacity = 6,
    this.quorum = 3,
    this.joinMode = 'open',
    this.status = GatheringStatus.scheduled,
    this.going = 0,
    this.needed = 0,
    this.quorumMet = false,
    this.repeatedFrom,
    this.viewerIsAttending = false,
    this.viewerIsHost = false,
  });

  factory Gathering.fromJson(Map<String, dynamic> json) {
    return Gathering(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'online_event',
      host: GatheringHost.fromJson(json['host']),
      title: sanitize(json['title']),
      description: sanitize(json['description']),
      language: json['language']?.toString() ?? '',
      languageLabel: sanitize(json['languageLabel']),
      level: json['level']?.toString(),
      startsAt:
          DateTime.tryParse(json['startsAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
      hostTimezone: json['hostTimezone']?.toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 6,
      quorum: (json['quorum'] as num?)?.toInt() ?? 3,
      joinMode: json['joinMode']?.toString() ?? 'open',
      status: _statusFrom(json['status']?.toString()),
      going: (json['going'] as num?)?.toInt() ?? 0,
      needed: (json['needed'] as num?)?.toInt() ?? 0,
      quorumMet: json['quorumMet'] == true,
      repeatedFrom: json['repeatedFrom']?.toString(),
      viewerIsAttending: json['viewerIsAttending'] == true,
      viewerIsHost: json['viewerIsHost'] == true,
    );
  }

  /// Display label, preferring what the host typed over the match key.
  String get displayLanguage =>
      languageLabel.isNotEmpty ? languageLabel : language;

  /// Whether there is still a seat. The backend is the authority — this only
  /// decides whether to grey the button before the round trip.
  bool get isFull => going >= capacity;

  bool get isOpenForRsvp =>
      status == GatheringStatus.scheduled || status == GatheringStatus.confirmed;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes));

  Gathering copyWith({
    GatheringStatus? status,
    int? going,
    int? needed,
    bool? quorumMet,
    bool? viewerIsAttending,
  }) {
    return Gathering(
      id: id,
      type: type,
      host: host,
      title: title,
      description: description,
      language: language,
      languageLabel: languageLabel,
      level: level,
      startsAt: startsAt,
      durationMinutes: durationMinutes,
      hostTimezone: hostTimezone,
      capacity: capacity,
      quorum: quorum,
      joinMode: joinMode,
      status: status ?? this.status,
      going: going ?? this.going,
      needed: needed ?? this.needed,
      quorumMet: quorumMet ?? this.quorumMet,
      repeatedFrom: repeatedFrom,
      viewerIsAttending: viewerIsAttending ?? this.viewerIsAttending,
      viewerIsHost: viewerIsHost,
    );
  }
}

/// A standing group. [memberCount] leads the card because it is the
/// cold-start signal — the number that makes the list look alive when nothing
/// is scheduled.
class Club {
  final String id;
  final String name;
  final String description;
  final String language;
  final String languageLabel;

  /// Free text: "running", "cycling", "HSK4", "K-pop". The thing that makes a
  /// club a club rather than a language filter.
  final String interest;

  final GatheringHost owner;
  final int memberCount;
  final String status;
  final bool viewerIsMember;
  final bool viewerIsOwner;

  /// Populated by the detail endpoint only (`GET /clubs/:id`); empty in lists.
  final List<Gathering> gatherings;

  const Club({
    required this.id,
    required this.name,
    this.description = '',
    this.language = '',
    this.languageLabel = '',
    this.interest = '',
    this.owner = const GatheringHost(),
    this.memberCount = 0,
    this.status = 'active',
    this.viewerIsMember = false,
    this.viewerIsOwner = false,
    this.gatherings = const [],
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: sanitize(json['name']),
      description: sanitize(json['description']),
      language: json['language']?.toString() ?? '',
      languageLabel: sanitize(json['languageLabel']),
      interest: sanitize(json['interest']),
      owner: GatheringHost.fromJson(json['owner']),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'active',
      viewerIsMember: json['viewerIsMember'] == true,
      viewerIsOwner: json['viewerIsOwner'] == true,
      gatherings:
          (json['gatherings'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((g) => Gathering.fromJson(Map<String, dynamic>.from(g)))
              .toList() ??
          const [],
    );
  }

  String get displayLanguage =>
      languageLabel.isNotEmpty ? languageLabel : language;

  Club copyWith({int? memberCount, bool? viewerIsMember}) {
    return Club(
      id: id,
      name: name,
      description: description,
      language: language,
      languageLabel: languageLabel,
      interest: interest,
      owner: owner,
      memberCount: memberCount ?? this.memberCount,
      status: status,
      viewerIsMember: viewerIsMember ?? this.viewerIsMember,
      viewerIsOwner: viewerIsOwner,
      gatherings: gatherings,
    );
  }
}
