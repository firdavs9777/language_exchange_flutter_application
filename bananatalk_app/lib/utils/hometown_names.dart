import 'package:bananatalk_app/providers/provider_models/community_model.dart';

/// City and country to save with a new GPS position. Reverse geocoding can
/// fail (offline, iOS throttling) or return no locality; an unresolved name
/// keeps the stored one instead of saving it blank.
({String city, String country}) resolveHometownNames({
  String? city,
  String? country,
  Location? stored,
}) {
  String pick(String? fresh, String? old) =>
      (fresh != null && fresh.trim().isNotEmpty) ? fresh : (old ?? '');
  return (
    city: pick(city, stored?.city),
    country: pick(country, stored?.country),
  );
}
