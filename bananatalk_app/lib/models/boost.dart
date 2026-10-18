/// A Profile Boost row from `/boosts` (see backend `models/Boost.js`).
/// Per-field tolerant: a missing or mistyped field never throws.
class Boost {
  const Boost({
    required this.id,
    this.kind = 'profile',
    this.startsAt,
    this.endsAt,
    this.impressions = 0,
    this.coinsSpent = 0,
    this.status = '',
    this.fromPartners = 0,
    this.fromMatches = 0,
    this.fromMoments = 0,
  });

  final String id;
  final String kind;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int impressions;
  final int coinsSpent;
  final String status;

  /// Where [impressions] happened (`impressionsBySource`; zero on boosts
  /// from before the server counted it).
  final int fromPartners;
  final int fromMatches;
  final int fromMoments;

  /// Share of the boost window already used, 0..1.
  double progressAt(DateTime now) {
    if (startsAt == null || endsAt == null) return 0;
    final total = endsAt!.difference(startsAt!).inSeconds;
    if (total <= 0) return 1;
    return (now.difference(startsAt!).inSeconds / total).clamp(0.0, 1.0);
  }

  bool get isLive =>
      endsAt != null && endsAt!.isAfter(DateTime.now()) && status != 'expired';

  factory Boost.fromJson(Map<String, dynamic> json) {
    DateTime? date(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    int count(dynamic v) => v is num ? v.toInt() : 0;
    final bySource = json['impressionsBySource'] is Map
        ? json['impressionsBySource'] as Map
        : const {};
    return Boost(
      id: json['_id']?.toString() ?? '',
      kind: json['kind'] is String ? json['kind'] as String : 'profile',
      startsAt: date(json['startsAt']),
      endsAt: date(json['endsAt']),
      impressions: count(json['impressions']),
      coinsSpent: count(json['coinsSpent']),
      status: json['status'] is String ? json['status'] as String : '',
      fromPartners: count(bySource['partners']),
      fromMatches: count(bySource['matches']),
      fromMoments: count(bySource['moments']),
    );
  }
}
