import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfileHometownEdit extends ConsumerStatefulWidget {
  const ProfileHometownEdit({Key? key, required String currentAddress})
      : super(key: key);

  @override
  ConsumerState<ProfileHometownEdit> createState() =>
      _ProfileHometownEditState();
}

class _ProfileHometownEditState extends ConsumerState<ProfileHometownEdit> {
  bool isFetchingLocation = false;
  bool isSaving = false;
  String? country;
  String? city;
  double? latitude;
  double? longitude;

  // Check location permission
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location services are disabled. Please enable them.'),
      ));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are denied'),
        ));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location permissions are permanently denied.'),
      ));
      return false;
    }

    return true;
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() {
      isFetchingLocation = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      final placemarks = await placemarkFromCoordinates(latitude!, longitude!);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          country = place.country ?? 'Unknown';
          city = place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'Unknown';
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Detected: $city, $country'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to get location: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isFetchingLocation = false;
      });
    }
  }

  Future<void> saveHometown() async {
    if (country == null || city == null) return;

    setState(() => isSaving = true);
    try {
      final response = await ref.read(authServiceProvider).updateUserHometown(
            city: city!,
            country: country!,
            latitude: latitude,
            longitude: longitude,
          );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved hometown: $city, $country'),
        backgroundColor: Colors.green,
      ));

      Navigator.pop(context, '$city, $country');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hometown'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use Current Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: isFetchingLocation ? null : getCurrentLocation,
              icon: isFetchingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                  isFetchingLocation ? 'Detecting...' : 'Get Current Location'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),

            // Display results
            if (country != null || city != null) ...[
              Text('Country: ${country ?? '-'}',
                  style: const TextStyle(fontSize: 16)),
              Text('City: ${city ?? '-'}',
                  style: const TextStyle(fontSize: 16)),
              if (latitude != null && longitude != null)
                Text(
                  'Coordinates: ${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
            ] else
              const Text(
                'No location detected yet.',
                style: TextStyle(color: Colors.grey),
              ),

            const Spacer(),

            ElevatedButton(
              onPressed: (country != null && city != null && !isSaving)
                  ? saveHometown
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text('Save', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
