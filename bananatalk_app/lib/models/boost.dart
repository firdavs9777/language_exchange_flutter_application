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
  });

  final String id;
  final String kind;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int impressions;
  final int coinsSpent;
  final String status;

  bool get isLive =>
      endsAt != null && endsAt!.isAfter(DateTime.now()) && status != 'expired';

  factory Boost.fromJson(Map<String, dynamic> json) {
    DateTime? date(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    int count(dynamic v) => v is num ? v.toInt() : 0;
    return Boost(
      id: json['_id']?.toString() ?? '',
      kind: json['kind'] is String ? json['kind'] as String : 'profile',
      startsAt: date(json['startsAt']),
      endsAt: date(json['endsAt']),
      impressions: count(json['impressions']),
      coinsSpent: count(json['coinsSpent']),
      status: json['status'] is String ? json['status'] as String : '',
    );
  }
}
