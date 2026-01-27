import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/tracking_provider.dart';

/// Rescuer Navigation Screen - Shows live location of both Rescuer and Customer
/// Uses TrackingProvider for real-time dual location tracking
class NavigationMapScreen extends StatefulWidget {
  const NavigationMapScreen({super.key});

  @override
  State<NavigationMapScreen> createState() => _NavigationMapScreenState();
}

class _NavigationMapScreenState extends State<NavigationMapScreen> {
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
      // For rescuer, user tracking represents rescuer's location
      // and rescuer tracking represents customer's location
      provider.startUserTracking(
          enableBackground:
              true); // Track rescuer (self) with background support
      provider.startRescuerTracking(
          enableBackground:
              true); // Track customer location with background support

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

  /// Center camera to show both rescuer and customer
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

  /// Show OTP prompt dialog
  void _showOTPPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Service OTP'),
        content: const TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Ask customer for 4-digit OTP',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider =
                  Provider.of<TrackingProvider>(context, listen: false);
              provider.stopUserTracking();
              provider.stopRescuerTracking();

              Navigator.pop(ctx);
              context.go('/rescuer-dashboard');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Service completed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Complete Service'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigating to Customer'),
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
                    trackingProvider.errorMessage ??
                        'Initializing navigation...',
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
                  target: trackingProvider.userLatLng!, // Rescuer's location
                  zoom: 13.0,
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

              // Distance indicator at top
              if (trackingProvider.hasRescuerLocation)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.navigation,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Customer is ${trackingProvider.getDistanceBetweenUserAndRescuer()?.toStringAsFixed(2) ?? "N/A"} km away',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                  heroTag: 'center_camera_rescuer',
                  backgroundColor: Colors.white,
                  onPressed: _centerCameraToBothLocations,
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // Customer details bottom sheet
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
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.secondary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usman Ahmed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text('Problem: Battery Jump-start'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Distance: ${trackingProvider.getDistanceBetweenUserAndRescuer()?.toStringAsFixed(2) ?? "N/A"} km',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                trackingProvider.stopUserTracking();
                                trackingProvider.stopRescuerTracking();

                                context.go('/rescuer-dashboard');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request cancelled'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              child: const Text('Cancel Request'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showOTPPrompt(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('I have Arrived'),
                            ),
                          ),
                        ],
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
