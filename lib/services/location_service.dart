import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service to handle location permissions and real-time GPS tracking
/// Optimized for battery efficiency and high accuracy with background support
class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastKnownPosition;
  bool _isTrackingInBackground = false;

  // Callback for location permission denied scenarios
  Function()? onPermissionDenied;
  Function()? onServiceDisabled;
  Function(Position)? onLocationUpdate;
  Function(dynamic)? onError;

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions from the user
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission;

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ LocationService: Location services are disabled');
        onServiceDisabled?.call();
        return false;
      }

      // Check current permission status
      permission = await Geolocator.checkPermission();
      debugPrint('📍 LocationService: Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        // Request permission from user
        permission = await Geolocator.requestPermission();
        debugPrint(
            '📍 LocationService: Permission request result: $permission');

        if (permission == LocationPermission.denied) {
          debugPrint('❌ LocationService: Location permission denied by user');
          onPermissionDenied?.call();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ LocationService: Location permission denied forever');
        onPermissionDenied?.call();
        return false;
      }

      debugPrint('✅ LocationService: Location permission granted');
      return true;
    } catch (e) {
      debugPrint('❌ LocationService: Error requesting permission: $e');
      return false;
    }
  }

  /// Get current location of the user with high accuracy
  /// Caches last known position for better performance
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ LocationService: Location services are disabled');
        // Return cached position if available
        return _lastKnownPosition;
      }

      // Check and request permission
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        debugPrint('❌ LocationService: No location permission');
        return _lastKnownPosition;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add timeout
      );

      _lastKnownPosition = position;
      debugPrint(
          '✅ LocationService: Got current position - Lat: ${position.latitude}, Lng: ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ LocationService: Error getting current location: $e');
      // Return last known position as fallback
      return _lastKnownPosition;
    }
  }

  /// Get last known position without making new request
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Get address from coordinates
  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.subLocality}, ${place.locality}";
      }
      return "Unknown Address";
    } catch (e) {
      debugPrint('Error getting address: $e');
      return "Address not found";
    }
  }

  /// Search location by address name
  Future<Location?> getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations[0];
      }
      return null;
    } catch (e) {
      debugPrint('Error searching address: $e');
      return null;
    }
  }

  /// Stream location updates in real-time with high accuracy
  /// Optimized for both Android and iOS with platform-specific settings
  /// Supports background tracking for continuous location updates
  Stream<Position> getLocationStream({bool enableBackground = false}) {
    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
        intervalDuration: const Duration(
            seconds: 2), // Update every 2 seconds for real-time tracking
        forceLocationManager:
            false, // Use FusedLocationProvider for better accuracy
        foregroundNotificationConfig: enableBackground
            ? const ForegroundNotificationConfig(
                notificationText:
                    "Rescue Ride is tracking your location for safety",
                notificationTitle: "Location Service Active",
                enableWakeLock: true,
              )
            : null,
      );
      debugPrint(
          '📍 LocationService: Android settings configured ${enableBackground ? "(background mode)" : "(foreground mode)"}');
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.best, // Best accuracy for iOS
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically:
            !enableBackground, // Don't pause in background mode
        showBackgroundLocationIndicator:
            enableBackground, // Show indicator when in background
        activityType:
            ActivityType.automotiveNavigation, // Optimize for vehicle movement
      );
      debugPrint(
          '📍 LocationService: iOS settings configured ${enableBackground ? "(background mode)" : "(foreground mode)"}');
    } else {
      // Web and other platforms
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
      debugPrint('📍 LocationService: Web/Default settings configured');
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Start listening to location updates with background support
  /// Provides real-time position updates via callback
  /// enableBackground: Set to true for continuous tracking even when app is in background
  void startLocationTracking(Function(Position) onLocationUpdate,
      {bool enableBackground = false}) {
    debugPrint(
        '🚀 LocationService: Starting location tracking... Background mode: $enableBackground');
    _isTrackingInBackground = enableBackground;
    this.onLocationUpdate = onLocationUpdate;

    _positionStreamSubscription?.cancel(); // Cancel existing subscription

    _positionStreamSubscription =
        getLocationStream(enableBackground: enableBackground).listen(
      (Position position) {
        _lastKnownPosition = position;
        debugPrint(
            '📍 LocationService: Position update - Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}, Accuracy: ${position.accuracy.toStringAsFixed(2)}m');
        onLocationUpdate(position);
      },
      onError: (error) {
        debugPrint('❌ LocationService: Location tracking error: $error');
        onError?.call(error);
      },
      cancelOnError: false, // Keep listening even after errors
    );
  }

  /// Stop listening to location updates and clean up resources
  /// Properly handles background service cleanup
  void stopLocationTracking() {
    debugPrint(
        '🛑 LocationService: Stopping location tracking... Background mode was: $_isTrackingInBackground');
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTrackingInBackground = false;
    onLocationUpdate = null;
    onError = null;
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
  }
}
