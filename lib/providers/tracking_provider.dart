import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

/// Provider for managing dual location tracking (User + Rescuer)
/// Handles real-time location updates, polyline routing, and ETA calculations
class TrackingProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  // User location data
  Position? _userPosition;
  LatLng? _userLatLng;

  // Rescuer location data (can be from backend/Firebase in production)
  Position? _rescuerPosition;
  LatLng? _rescuerLatLng;

  // Map elements
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Tracking state
  bool _isTrackingUser = false;
  bool _isTrackingRescuer = false;
  String? _errorMessage;

  // Route and ETA data
  final List<LatLng> _routePoints = [];
  double _distanceInKm = 0.0;
  int _estimatedArrivalTimeSeconds = 0; // ETA in seconds
  double _averageSpeed = 0.0; // Speed in km/h

  // Simulation and timing
  Timer? _rescuerSimulationTimer;
  DateTime? _trackingStartTime;

  // Getters
  Position? get userPosition => _userPosition;
  LatLng? get userLatLng => _userLatLng;
  Position? get rescuerPosition => _rescuerPosition;
  LatLng? get rescuerLatLng => _rescuerLatLng;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  bool get isTrackingUser => _isTrackingUser;
  bool get isTrackingRescuer => _isTrackingRescuer;
  String? get errorMessage => _errorMessage;
  bool get hasUserLocation => _userLatLng != null;
  bool get hasRescuerLocation => _rescuerLatLng != null;
  double get distanceInKm => _distanceInKm;
  int get estimatedArrivalTimeSeconds => _estimatedArrivalTimeSeconds;
  String get formattedETA => _formatETA(_estimatedArrivalTimeSeconds);
  String get formattedDistance => '${_distanceInKm.toStringAsFixed(2)} km';
  double get averageSpeed => _averageSpeed;
  String get formattedSpeed => '${_averageSpeed.toStringAsFixed(1)} km/h';
  List<LatLng> get routePoints => _routePoints;

  /// Initialize and request location permissions
  /// Sets up location service with proper error handling
  Future<bool> initialize() async {
    try {
      debugPrint('🚀 TrackingProvider: Initializing location service...');

      // Set up error callbacks
      _locationService.onPermissionDenied = () {
        _errorMessage =
            'Location permission denied. Please grant permission in settings.';
        notifyListeners();
      };

      _locationService.onServiceDisabled = () {
        _errorMessage = 'Location services are disabled. Please enable GPS.';
        notifyListeners();
      };

      _locationService.onError = (error) {
        _errorMessage = 'Location tracking error: ${error.toString()}';
        debugPrint('❌ TrackingProvider: Location service error: $error');
        notifyListeners();
      };

      // Check location service
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled. Please enable GPS.';
        notifyListeners();
        return false;
      }

      // Request permission
      bool hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        _errorMessage = 'Location permission denied. Please grant permission.';
        notifyListeners();
        return false;
      }

      // Get initial position
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        _updateUserPosition(position);
        _trackingStartTime = DateTime.now();
      }

      _errorMessage = null;
      debugPrint('✅ TrackingProvider: Initialized successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to initialize location service: $e';
      debugPrint('❌ TrackingProvider: Initialization error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Format ETA in human-readable format (minutes or hours:minutes)
  String _formatETA(int seconds) {
    if (seconds <= 0) return "Arriving";

    final minutes = (seconds / 60).round();

    if (minutes < 60) {
      return "$minutes min${minutes == 1 ? '' : 's'}";
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return "$hours hr${hours == 1 ? '' : 's'} ${remainingMinutes}min";
    }
  }

  /// Calculate distance and ETA between two points
  /// Updates distance, ETA, and average speed
  void _calculateRouteMetrics() {
    if (_userLatLng == null || _rescuerLatLng == null) {
      _distanceInKm = 0.0;
      _estimatedArrivalTimeSeconds = 0;
      _averageSpeed = 0.0;
      return;
    }

    // Calculate distance in meters, then convert to kilometers
    double distanceInMeters = _locationService.calculateDistance(
      _userLatLng!.latitude,
      _userLatLng!.longitude,
      _rescuerLatLng!.latitude,
      _rescuerLatLng!.longitude,
    );

    _distanceInKm = distanceInMeters / 1000.0;

    // Estimate arrival time (assuming average speed of 30 km/h for rescue vehicles)
    // In real implementation, this would use actual traffic data
    const averageRescueSpeedKmh = 30.0; // km/h
    _estimatedArrivalTimeSeconds =
        (_distanceInKm / averageRescueSpeedKmh * 3600).round();

    // Calculate average speed if we have tracking duration
    if (_trackingStartTime != null && _routePoints.length > 1) {
      final duration = DateTime.now().difference(_trackingStartTime!).inSeconds;
      if (duration > 0) {
        // Calculate total distance traveled by rescuer
        double totalDistanceTraveled = 0.0;
        for (int i = 1; i < _routePoints.length; i++) {
          totalDistanceTraveled += Geolocator.distanceBetween(
            _routePoints[i - 1].latitude,
            _routePoints[i - 1].longitude,
            _routePoints[i].latitude,
            _routePoints[i].longitude,
          );
        }
        _averageSpeed = (totalDistanceTraveled / 1000.0) / (duration / 3600.0);
      }
    }

    debugPrint(
        '📊 Route Metrics - Distance: ${_distanceInKm.toStringAsFixed(2)}km, ETA: ${_formatETA(_estimatedArrivalTimeSeconds)}, Speed: ${_averageSpeed.toStringAsFixed(1)}km/h');
  }

  /// Update polyline route between user and rescuer
  void _updatePolyline() {
    _polylines.clear();

    if (_userLatLng != null && _rescuerLatLng != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: [_rescuerLatLng!, _userLatLng!],
          color: const Color(0xFF2196F3), // Blue color
          width: 5,
          geodesic: true, // Curved line following Earth's surface
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    // Add route history polyline if we have multiple points
    if (_routePoints.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_history'),
          points: _routePoints,
          color: const Color(0xFF4CAF50), // Green color for history
          width: 3,
          geodesic: true,
          jointType: JointType.round,
        ),
      );
    }
  }

  /// Start tracking user's live location with background support
  void startUserTracking({bool enableBackground = false}) {
    if (_isTrackingUser) return;

    debugPrint(
        '🚀 TrackingProvider: Starting user location tracking... Background: $enableBackground');
    _isTrackingUser = true;

    _locationService.startLocationTracking((Position position) {
      _updateUserPosition(position);
    }, enableBackground: enableBackground);

    notifyListeners();
  }

  /// Stop tracking user's location
  void stopUserTracking() {
    debugPrint('🛑 TrackingProvider: Stopping user location tracking...');
    _isTrackingUser = false;
    _locationService.stopLocationTracking();
    notifyListeners();
  }

  /// Update user position and marker
  void _updateUserPosition(Position position) {
    _userPosition = position;
    _userLatLng = LatLng(position.latitude, position.longitude);
    _updateMarkers();
    _updatePolyline();
    _calculateRouteMetrics();
    notifyListeners();
    debugPrint(
        '📍 TrackingProvider: User position updated - ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
  }

  /// Start simulating rescuer location (replace with real backend in production)
  /// In real app, this would listen to Firebase/WebSocket for rescuer's location
  /// enableBackground: Set to true for continuous tracking when app is in background
  void startRescuerTracking(
      {LatLng? initialLocation, bool enableBackground = false}) {
    if (_isTrackingRescuer) return;

    debugPrint(
        '🚀 TrackingProvider: Starting rescuer location tracking... Background: $enableBackground');
    _isTrackingRescuer = true;

    // Set initial rescuer location
    if (initialLocation != null) {
      _rescuerLatLng = initialLocation;
    } else if (_userLatLng != null) {
      // Place rescuer 0.01 degrees away from user (approximately 1km)
      _rescuerLatLng = LatLng(
        _userLatLng!.latitude + 0.01,
        _userLatLng!.longitude + 0.01,
      );
    }

    // Initialize route tracking
    if (_rescuerLatLng != null) {
      _routePoints.add(_rescuerLatLng!);
    }

    _updateMarkers();
    _updatePolyline();
    _calculateRouteMetrics();
    notifyListeners();

    // Simulate rescuer moving towards user every 3 seconds for more realistic tracking
    _rescuerSimulationTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_userLatLng != null && _rescuerLatLng != null) {
        _simulateRescuerMovement();
      }
    });
  }

  /// Stop tracking rescuer
  void stopRescuerTracking() {
    debugPrint('🛑 TrackingProvider: Stopping rescuer location tracking...');
    _isTrackingRescuer = false;
    _rescuerSimulationTimer?.cancel();
    _rescuerSimulationTimer = null;
    notifyListeners();
  }

  /// Simulate rescuer movement towards user with route tracking
  /// Replace this with real backend data in production
  /// Updates route history and recalculates metrics
  void _simulateRescuerMovement() {
    if (_rescuerLatLng == null || _userLatLng == null) return;

    // Calculate step (5% of distance towards user for smoother movement)
    double latStep = (_userLatLng!.latitude - _rescuerLatLng!.latitude) * 0.05;
    double lngStep =
        (_userLatLng!.longitude - _rescuerLatLng!.longitude) * 0.05;

    // Update rescuer location
    _rescuerLatLng = LatLng(
      _rescuerLatLng!.latitude + latStep,
      _rescuerLatLng!.longitude + lngStep,
    );

    // Add to route history
    _routePoints.add(_rescuerLatLng!);

    // Limit route history to last 50 points for performance
    if (_routePoints.length > 50) {
      _routePoints.removeAt(0);
    }

    _updateMarkers();
    _updatePolyline();
    _calculateRouteMetrics();
    notifyListeners();

    debugPrint(
        '📍 TrackingProvider: Rescuer position simulated - ${_rescuerLatLng!.latitude.toStringAsFixed(6)}, ${_rescuerLatLng!.longitude.toStringAsFixed(6)}');
    debugPrint(
        '📊 Route Points: ${_routePoints.length}, Distance: ${_distanceInKm.toStringAsFixed(2)}km, ETA: ${_formatETA(_estimatedArrivalTimeSeconds)}');
  }

  /// Update rescuer location manually (for backend integration)
  void updateRescuerLocation(LatLng location) {
    _rescuerLatLng = location;
    _updateMarkers();
    notifyListeners();
  }

  /// Update map markers for both user and rescuer with custom styling
  void _updateMarkers() {
    _markers.clear();

    // Add user marker (Blue with custom icon)
    if (_userLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet:
                'Customer • Accuracy: ${_userPosition?.accuracy.toStringAsFixed(0) ?? 'N/A'}m',
          ),
          flat: true,
          anchor: const Offset(0.5, 0.5),
          draggable: false,
        ),
      );
    }

    // Add rescuer marker (Green with custom icon and rotation)
    if (_rescuerLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('rescuer_location'),
          position: _rescuerLatLng!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Rescuer Location',
            snippet: 'On the way • \$formattedETA • \$formattedDistance',
          ),
          flat: true,
          anchor: const Offset(0.5, 0.5),
          draggable: false,
        ),
      );
    }
  }

  /// Calculate distance between user and rescuer in kilometers
  double? getDistanceBetweenUserAndRescuer() {
    if (_userLatLng == null || _rescuerLatLng == null) return null;

    double distanceInMeters = _locationService.calculateDistance(
      _userLatLng!.latitude,
      _userLatLng!.longitude,
      _rescuerLatLng!.latitude,
      _rescuerLatLng!.longitude,
    );

    return distanceInMeters / 1000; // Convert to kilometers
  }

  /// Get camera position to show both markers
  CameraPosition? getCameraPositionForBothLocations() {
    if (_userLatLng == null || _rescuerLatLng == null) {
      if (_userLatLng != null) {
        return CameraPosition(target: _userLatLng!, zoom: 15.0);
      }
      if (_rescuerLatLng != null) {
        return CameraPosition(target: _rescuerLatLng!, zoom: 15.0);
      }
      return null;
    }

    // Calculate center point between user and rescuer
    double centerLat = (_userLatLng!.latitude + _rescuerLatLng!.latitude) / 2;
    double centerLng = (_userLatLng!.longitude + _rescuerLatLng!.longitude) / 2;

    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: 14.0,
    );
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🗑️ TrackingProvider: Disposing and cleaning up resources...');
    stopUserTracking();
    stopRescuerTracking();
    _locationService.dispose();

    // Clear all data
    _userPosition = null;
    _userLatLng = null;
    _rescuerPosition = null;
    _rescuerLatLng = null;
    _markers.clear();
    _polylines.clear();
    _routePoints.clear();
    _trackingStartTime = null;

    super.dispose();
  }
}
