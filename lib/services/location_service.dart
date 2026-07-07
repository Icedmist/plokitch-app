import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'api_service.dart';

class LocationService {
  LocationService._();

  static Future<Position> getCurrentPosition() async {
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
  }

  /// Reverse geocode coordinates to a simple address map.
  static Future<Map<String, dynamic>> reverseGeocode(Position pos) async {
    final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
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
  }

  /// Get current position and reverse-geocode it. Returns address map.
  static Future<Map<String, dynamic>> locateAndReverse() async {
    final pos = await getCurrentPosition();
    final addr = await reverseGeocode(pos);
    return addr;
  }

  /// Save an address payload to the user's profile via API.
  static Future<void> saveAddress(Map<String, dynamic> addressPayload) async {
    final payload = {'address': addressPayload};
    await ApiService.saveUserLocation(payload);
  }
}
