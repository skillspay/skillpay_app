import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' show Geocoding, Placemark;

class LocationService {
  LocationService();
  static final LocationService instance = LocationService();

  Position? _lastKnownPosition;
  String? _lastKnownAddress;

  Position? get lastKnownPosition => _lastKnownPosition;
  String? get lastKnownAddress => _lastKnownAddress;

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
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    _lastKnownPosition = pos;
    return pos;
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

  /// Reverse geocode coordinates to a clean human-readable city/area string.
  Future<String> getReadableAddress(double latitude, double longitude) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality ?? place.subLocality ?? place.subAdministrativeArea;
        final adminArea = place.administrativeArea;
        final name = place.name ?? place.street;

        if (locality != null && locality.isNotEmpty && adminArea != null && adminArea.isNotEmpty) {
          final addr = '$locality, $adminArea';
          _lastKnownAddress = addr;
          return addr;
        } else if (name != null && name.isNotEmpty) {
          _lastKnownAddress = name;
          return name;
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Geocoding error: $e');
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Calculates straight-line distance in kilometers between two points using Haversine.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0;
  }
}
