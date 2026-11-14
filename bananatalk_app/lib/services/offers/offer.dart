/// The surfaces a server offer can name (`GET /offers` → `surface`).
class OfferSurface {
  OfferSurface._();
  static const visitorRecall = 'visitor_recall';
  static const profileBanner = 'profile_banner';
  static const momentsChip = 'moments_chip';
  static const matchesEmpty = 'matches_empty';

  static const all = {visitorRecall, profileBanner, momentsChip, matchesEmpty};
}

/// What an offer leads with (`GET /offers` → `lead`).
class OfferLead {
  OfferLead._();
  static const coins = 'coins';
  static const vip = 'vip';
}

/// The server's single daily offer: which passive upsell element may show,
/// and until when.
class Offer {
  const Offer({
    required this.id,
    required this.surface,
    required this.placement,
    required this.lead,
    required this.validUntil,
  });

  final String id;
  final String surface;
  final String placement;
  final String lead;
  final DateTime validUntil;

  /// Null on any missing or malformed field (unknown surface or lead too).
  static Offer? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final surface = json['surface'];
    final placement = json['placement'];
    final lead = json['lead'];
    final until = json['validUntil'];
    if (id is! String || id.isEmpty) return null;
    if (surface is! String || !OfferSurface.all.contains(surface)) return null;
    if (placement is! String || placement.isEmpty) return null;
    if (lead != OfferLead.coins && lead != OfferLead.vip) return null;
    if (until is! String) return null;
    final validUntil = DateTime.tryParse(until);
    if (validUntil == null) return null;
    return Offer(
      id: id,
      surface: surface,
      placement: placement,
      lead: lead as String,
      validUntil: validUntil,
    );
  }

  /// False once [validUntil] has passed.
  bool isValid(DateTime now) => now.isBefore(validUntil);
}
