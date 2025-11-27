class LocationModal {
  final String type;
  final List<double> coordinates; // [longitude, latitude]
  final String formattedAddress;
  final String city;
  final String country;

  const LocationModal({
    required this.type,
    required this.coordinates,
    required this.formattedAddress,
    required this.city,
    required this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates.map((c) => c.toDouble()).toList(), // Ensure all are doubles
      'formattedAddress': formattedAddress,
      'city': city,
      'country': country,
    };
  }
}
