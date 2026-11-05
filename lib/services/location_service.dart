import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? errorMessage;

  LocationResult({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.errorMessage,
  });

  bool get isSuccess => latitude != null && longitude != null;

  String get formattedCoordinates {
    if (!isSuccess) return 'Location unavailable';
    final latSign = latitude! >= 0 ? 'N' : 'S';
    final lngSign = longitude! >= 0 ? 'E' : 'W';
    return '${latitude!.abs().toStringAsFixed(5)}° $latSign, ${longitude!.abs().toStringAsFixed(5)}° $lngSign';
  }
}

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(errorMessage: 'Location services are disabled on device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(errorMessage: 'Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          errorMessage: 'Location permissions are permanently denied. Please enable in Settings.',
        );
      }

      // Try fetching high accuracy GPS with timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        // Fallback to last known position
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );
      } else {
        return LocationResult(errorMessage: 'Unable to acquire GPS fix. Please ensure clear sky view.');
      }
    } catch (e) {
      return LocationResult(errorMessage: 'Error fetching location: $e');
    }
  }
}
