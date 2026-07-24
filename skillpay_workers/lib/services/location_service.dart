import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Request location permission and return the current [Position].
  /// Throws a descriptive [Exception] if permission is denied or unavailable.
  Future<Position> getCurrentLocation() async {
    // Check if location services are enabled on the device.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS in your device settings.',
      );
    }

    // Check and request permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please allow location access to use this feature.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable it in App Settings.',
      );
    }

    // Get the current position.
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Builds a simple human-readable address label from coordinates.
  String formatCoordinates(Position position) {
    final lat = position.latitude.toStringAsFixed(6);
    final lng = position.longitude.toStringAsFixed(6);
    debugPrint('Device location: $lat, $lng');
    return '$lat, $lng';
  }

  /// Get the actual address placemarks using geocoding.
  Future<List<Placemark>> getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      return placemarks;
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return [];
    }
  }
}
