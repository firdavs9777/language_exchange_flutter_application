import 'package:geocoding/geocoding.dart';

/// The address line for a reverse-geocoded place, or null when the place
/// has nothing to show.
///
/// Null rather than a placeholder: the composer used to fill the gap with
/// "Location added" (English UI text) or ", ", which then went to the server
/// as the moment's address. The composer shows its own localized label when
/// this is null.
String? placemarkAddress(Placemark place) {
  final parts = [
    place.street,
    place.locality,
    place.administrativeArea,
    place.postalCode,
    place.country,
  ].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);
  return parts.isEmpty ? null : parts.join(', ');
}

/// The `location` body for POST /moments (GeoJSON order: [lng, lat]).
///
/// `formattedAddress` is optional on the backend (Moment.location is not
/// required beyond coordinates), so it is left out when there is none
/// instead of sending UI text as data.
Map<String, dynamic> momentLocationPayload({
  required double latitude,
  required double longitude,
  String? formattedAddress,
}) {
  final address = formattedAddress?.trim();
  return {
    'coordinates': [longitude, latitude],
    if (address != null && address.isNotEmpty) 'formattedAddress': address,
  };
}
