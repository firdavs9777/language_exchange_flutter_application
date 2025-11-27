import 'package:bananatalk_app/providers/provider_models/community_model.dart';

class PrivacyUtils {
  /// Get formatted location text based on privacy settings
  /// Returns empty string if location should be hidden
  static String getLocationText(Community user) {
    final privacy = user.privacySettings;
    final location = user.location;

    // If no privacy settings, show everything (default behavior)
    if (privacy == null) {
      if (location.city.isNotEmpty && location.country.isNotEmpty) {
        return '${location.city}, ${location.country}';
      } else if (location.country.isNotEmpty) {
        return location.country;
      }
      return 'Location not set';
    }

    // Check if country/region should be shown
    final showCountry = privacy.showCountryRegion;
    final showCity = privacy.showCity;

    if (!showCountry && !showCity) {
      return ''; // Hide location completely
    }

    if (showCity && location.city.isNotEmpty) {
      if (showCountry && location.country.isNotEmpty) {
        return '${location.city}, ${location.country}';
      }
      return location.city;
    }

    if (showCountry && location.country.isNotEmpty) {
      return location.country;
    }

    return 'Location not set';
  }

  /// Get age if privacy settings allow it
  /// Returns null if age should be hidden
  static int? getAge(Community user, int calculatedAge) {
    if (calculatedAge <= 0) return null;

    final privacy = user.privacySettings;
    // If no privacy settings, show age (default behavior)
    if (privacy == null) return calculatedAge;

    // Check if age should be shown
    if (!privacy.showAge) return null;

    return calculatedAge;
  }

  /// Check if age should be displayed
  static bool shouldShowAge(Community user) {
    final privacy = user.privacySettings;
    if (privacy == null) return true; // Default: show age
    return privacy.showAge;
  }

  /// Check if location should be displayed
  static bool shouldShowLocation(Community user) {
    final privacy = user.privacySettings;
    if (privacy == null) return true; // Default: show location
    
    return privacy.showCountryRegion || privacy.showCity;
  }

  /// Check if zodiac should be displayed
  static bool shouldShowZodiac(Community user) {
    final privacy = user.privacySettings;
    if (privacy == null) return true; // Default: show zodiac
    return privacy.showZodiac;
  }

  /// Check if online status should be displayed
  static bool shouldShowOnlineStatus(Community user) {
    final privacy = user.privacySettings;
    if (privacy == null) return true; // Default: show online status
    return privacy.showOnlineStatus;
  }

  /// Check if gifting level should be displayed
  static bool shouldShowGiftingLevel(Community user) {
    final privacy = user.privacySettings;
    if (privacy == null) return true; // Default: show gifting level
    return privacy.showGiftingLevel;
  }
}

