import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location Service - Handles location permissions and distance calculations
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  DateTime? _lastFetchTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get current user position (with caching)
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    // Return cached position if still valid
    if (!forceRefresh && _currentPosition != null && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      if (elapsed < _cacheTimeout) {
        return _currentPosition;
      }
    }

    try {
      // Check permission (checkAndRequestPermission logs the specific reason)
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        return null;
      }

      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Get position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      _lastFetchTime = DateTime.now();

      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  /// Check and request location permission
  Future<bool> checkAndRequestPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isPermanentlyDenied) {
      return false;
    }

    if (!status.isGranted) {
      return false;
    }

    return true;
  }

  /// Get permission status
  Future<PermissionStatus> getPermissionStatus() async {
    return await Permission.locationWhenInUse.status;
  }

  /// Open app settings (for permanently denied permissions)
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  /// Get distance between current position and a target point
  Future<double?> getDistanceToPoint({
    required double targetLat,
    required double targetLon,
  }) async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    return calculateDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: targetLat,
      lon2: targetLon,
    );
  }

  /// Clear cached position
  void clearCache() {
    _currentPosition = null;
    _lastFetchTime = null;
  }

  /// Get cached position (without fetching)
  Position? get cachedPosition => _currentPosition;
}
