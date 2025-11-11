import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';

class LocationService {
  /// Check and request location permissions
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // Still denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Cannot request permission, open settings
      await openAppSettings();
      return false;
    }

    return true; // Granted: while in use OR always
  }

  /// Get current user location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two positions in kilometers
  static double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000; // Convert meters to kilometers
  }

  /// Get workshop position from lat/lng stored in workshop model
  static Position? getWorkshopPosition(WorkshopModel workshop) {
    // Check if workshop has valid lat/lng coordinates
    if (workshop.lat == null ||
        workshop.lng == null ||
        workshop.lat!.isEmpty ||
        workshop.lng!.isEmpty) {
      return null;
    }

    try {
      final latitude = double.parse(workshop.lat!);
      final longitude = double.parse(workshop.lng!);

      // Validate coordinates are within valid ranges
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        return null;
      }

      return Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Filter workshops by radius from user location using stored lat/lng
  static Future<List<WorkshopWithDistance>> filterWorkshopsByRadius({
    required List<WorkshopModel> workshops,
    required Position userLocation,
    required double radiusKm,
  }) async {
    List<WorkshopWithDistance> workshopsWithDistance = [];

    for (WorkshopModel workshop in workshops) {
      Position? workshopPosition = getWorkshopPosition(workshop);

      if (workshopPosition != null) {
        double distance = calculateDistance(userLocation, workshopPosition);

        if (distance <= radiusKm) {
          workshopsWithDistance.add(
            WorkshopWithDistance(
              workshop: workshop,
              distance: distance,
              location: workshopPosition,
            ),
          );
        }
      } else {
        // Log workshops without valid coordinates for debugging
      }
    }

    // Sort by distance (closest first)
    workshopsWithDistance.sort((a, b) => a.distance.compareTo(b.distance));

    return workshopsWithDistance;
  }

  /// Get coordinates from address using geocoding package (fallback method)
  static Future<Position?> getLocationFromAddress(String address) async {
    try {
      if (address.trim().isEmpty) return null;

      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get workshop location from address components (fallback method)
  static Future<Position?> getWorkshopLocationFromAddress(
    WorkshopModel workshop,
  ) async {
    // First try to use stored coordinates
    Position? storedPosition = getWorkshopPosition(workshop);
    if (storedPosition != null) {
      return storedPosition;
    }

    // Fallback to geocoding if no stored coordinates
    List<String> addressParts = [];

    if (workshop.street != null && workshop.street!.isNotEmpty) {
      addressParts.add(workshop.street!);
    }
    if (workshop.number != null && workshop.number!.isNotEmpty) {
      addressParts.add(workshop.number!);
    }
    if (workshop.city != null && workshop.city!.isNotEmpty) {
      addressParts.add(workshop.city!);
    }
    if (workshop.postalCode != null && workshop.postalCode!.isNotEmpty) {
      addressParts.add(workshop.postalCode!);
    }

    if (addressParts.isEmpty) return null;

    String fullAddress = addressParts.join(', ');
    return await getLocationFromAddress(fullAddress);
  }
}

class WorkshopWithDistance {
  final WorkshopModel workshop;
  final double distance;
  final Position? location;

  WorkshopWithDistance({
    required this.workshop,
    required this.distance,
    this.location,
  });

  String get distanceString {
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  /// Get formatted address string
  String get addressString {
    List<String> parts = [];
    if (workshop.street?.isNotEmpty == true) parts.add(workshop.street!);
    if (workshop.number?.isNotEmpty == true) parts.add(workshop.number!);
    if (workshop.city?.isNotEmpty == true) parts.add(workshop.city!);

    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }
}
