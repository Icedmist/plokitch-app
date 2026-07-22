import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'api_service.dart';

class LocationService {
  LocationService._();

  static Future<Position> getCurrentPosition() async {
    // Fallback for platforms not supported by geolocator (like Linux)
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
      return Position(
        latitude: 10.2896,
        longitude: 11.1679,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      // Return default Gombe coords if plugin fails
      return Position(
        latitude: 10.2896,
        longitude: 11.1679,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  /// Reverse geocode coordinates to a simple address map.
  static Future<Map<String, dynamic>> reverseGeocode(Position pos) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isEmpty) return {'street': '', 'city': '', 'state': ''};
      final p = placemarks.first;
      final street = [p.street, p.subLocality].where((s) => s != null && s.isNotEmpty).join(', ');
      return {
        'street': street.isNotEmpty ? street : (p.name ?? ''),
        'city': p.locality ?? p.subAdministrativeArea ?? '',
        'state': p.administrativeArea ?? p.country ?? '',
        'lat': pos.latitude,
        'lng': pos.longitude,
      };
    } catch (e) {
      return {
        'street': 'Gombe City Center',
        'city': 'Gombe',
        'state': 'Gombe State',
        'lat': pos.latitude,
        'lng': pos.longitude,
      };
    }
  }

  /// Get current position and reverse-geocode it. Returns address map.
  static Future<Map<String, dynamic>> locateAndReverse() async {
    final pos = await getCurrentPosition();
    final addr = await reverseGeocode(pos);
    return addr;
  }

  /// Forward geocode a place name/address string into LatLng coordinates.
  static Future<Map<String, dynamic>?> forwardGeocode(String query) async {
    try {
      final locations = await Geocoding().locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return {
          'lat': loc.latitude,
          'lng': loc.longitude,
          'name': query,
        };
      }
    } catch (_) {}
    return null;
  }

  /// Save an address payload to the user's profile via API.
  static Future<void> saveAddress(Map<String, dynamic> addressPayload) async {
    final payload = {'address': addressPayload};
    await ApiService.saveUserLocation(payload);
  }
}
