import 'package:geolocator/geolocator.dart';
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

  /// Get current position and save to server as user address (patch)
  static Future<void> locateAndSave({String? street, String? city, String? state}) async {
    final pos = await getCurrentPosition();
    final payload = {
      'address': {
        'street': street ?? '',
        'city': city ?? '',
        'state': state ?? '',
        'lat': pos.latitude,
        'lng': pos.longitude,
      }
    };
    await ApiService.saveUserLocation(payload);
  }
}
