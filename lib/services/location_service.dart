import 'package:geolocator/geolocator.dart';

enum LocationResult { success, serviceDisabled, permissionDenied, permissionDeniedForever, error }

class LocationFetchOutcome {
  final LocationResult result;
  final double? latitude;
  final double? longitude;

  LocationFetchOutcome(this.result, {this.latitude, this.longitude});
}

class LocationService {
  static Future<LocationFetchOutcome> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationFetchOutcome(LocationResult.serviceDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationFetchOutcome(LocationResult.permissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationFetchOutcome(LocationResult.permissionDeniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      return LocationFetchOutcome(
        LocationResult.success,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return LocationFetchOutcome(LocationResult.error);
    }
  }
}