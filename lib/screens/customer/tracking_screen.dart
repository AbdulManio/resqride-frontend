import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/tracking_provider.dart';

/// Customer Tracking Screen - Shows live location of both User and Rescuer
/// Uses TrackingProvider for real-time dual location tracking
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTracking();
    });
  }

  /// Initialize tracking provider and start location services
  Future<void> _initializeTracking() async {
    final provider = Provider.of<TrackingProvider>(context, listen: false);

    bool success = await provider.initialize();

    if (success) {
      // Start tracking both user and rescuer with background support
      provider.startUserTracking(enableBackground: true);
      provider.startRescuerTracking(enableBackground: true);

      setState(() => _isInitialized = true);

      // Center camera to show both markers
      _centerCameraToBothLocations();
    } else {
      // Show error if initialization failed
      if (mounted && provider.errorMessage != null) {
        _showErrorDialog('Initialization Error', provider.errorMessage!);
      }
    }
  }

  /// Center camera to show both user and rescuer
  void _centerCameraToBothLocations() {
    final provider = Provider.of<TrackingProvider>(context, listen: false);
    final cameraPosition = provider.getCameraPositionForBothLocations();

    if (cameraPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

  /// Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    // Provider is disposed automatically by MultiProvider in main.dart
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescuer is on the way'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<TrackingProvider>(
        builder: (context, trackingProvider, child) {
          // Show loading state
          if (!_isInitialized || !trackingProvider.hasUserLocation) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    trackingProvider.errorMessage ?? 'Initializing map...',
                    textAlign: TextAlign.center,
                  ),
                  if (trackingProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _initializeTracking(),
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            );
          }

          // Show map with both locations
          return Stack(
            children: [
              // Google Map with live markers and polylines
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: trackingProvider.userLatLng!,
                  zoom: 14.0,
                ),
                markers: trackingProvider.markers,
                polylines: trackingProvider.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _centerCameraToBothLocations();
                },
              ),

              // Enhanced status bar with distance, ETA, and speed
              if (trackingProvider.hasRescuerLocation)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary status row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_car,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Rescuer is ${trackingProvider.formattedDistance} away',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Secondary info row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _InfoChip(
                              icon: Icons.access_time,
                              label: trackingProvider.formattedETA,
                              color: Colors.orange,
                            ),
                            _InfoChip(
                              icon: Icons.speed,
                              label: trackingProvider.formattedSpeed,
                              color: Colors.green,
                            ),
                            _InfoChip(
                              icon: Icons.location_on,
                              label:
                                  '${trackingProvider.distanceInKm.toStringAsFixed(2)} km',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Center camera button
              Positioned(
                right: 16,
                top: 90,
                child: FloatingActionButton.small(
                  heroTag: 'center_camera',
                  backgroundColor: Colors.white,
                  onPressed: _centerCameraToBothLocations,
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // Rescuer info bottom sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ali Khan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Arriving soon (Toyota Corolla)',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Call rescuer functionality
                            },
                            icon: const Icon(
                              Icons.call,
                              color: AppColors.accent,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OTP: 1234',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Stop tracking
                              trackingProvider.stopUserTracking();
                              trackingProvider.stopRescuerTracking();

                              context.go('/customer-dashboard');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request cancelled'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            },
                            child: const Text(
                              'Cancel Request',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Stop tracking before navigating
                          trackingProvider.stopUserTracking();
                          trackingProvider.stopRescuerTracking();

                          context.push('/rating');
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Service Completed'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom info chip widget for displaying tracking metrics
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
