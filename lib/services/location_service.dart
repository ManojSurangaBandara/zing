import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/sri_lanka_data.dart';

class LocationService {
  /// Request location permission and get current device position
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Get fallback coordinates for a district if device GPS is unavailable
  static (double, double) getDistrictCoordinates(String district) {
    if (SriLankaData.districtCoordinates.containsKey(district)) {
      return SriLankaData.districtCoordinates[district]!;
    }
    // Default to Colombo center
    return (6.9271, 79.8612);
  }

  /// Calculate distance in Kilometers between two coordinates
  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return distanceInMeters / 1000.0;
  }
}
