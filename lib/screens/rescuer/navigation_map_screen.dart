import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/tracking_provider.dart';
import '../../services/request_service.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';

class NavigationMapScreen extends StatefulWidget {
  final String requestId;
  final double customerLat;
  final double customerLng;
  final String customerName;
  final String problemType;
  final int finalFare;

  const NavigationMapScreen({
    super.key,
    required this.requestId,
    required this.customerLat,
    required this.customerLng,
    required this.customerName,
    required this.problemType,
    required this.finalFare,
  });

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
      _startSendingLocation();
    });
  }

  Future<void> _initializeTracking() async {
    final provider = Provider.of<TrackingProvider>(context, listen: false);
    bool success = await provider.initialize();

    if (success) {
      provider.startUserTracking(enableBackground: true);

      double targetLat = widget.customerLat;
      double targetLng = widget.customerLng;

      // Fallback: fetch active job coordinates if missing
      if (targetLat == 0.0 || targetLng == 0.0) {
        final res = await ApiService.authGet('/services/my-active-job');
        if (res['success'] == true &&
            res['requests'] != null &&
            (res['requests'] as List).isNotEmpty) {
          final job = res['requests'][0];
          final coords = job['location']?['coordinates'];
          if (coords != null && coords.length > 1) {
            targetLat = (coords[1] as num).toDouble();
            targetLng = (coords[0] as num).toDouble();
          }
        }
      }

      if (targetLat != 0.0 && targetLng != 0.0) {
        provider.updateRescuerLocation(LatLng(targetLat, targetLng));
      }

      setState(() => _isInitialized = true);
      _centerCameraToBothLocations();
    } else {
      if (mounted) {
        setState(() => _isInitialized = true);
        if (provider.errorMessage != null) {
          _showErrorDialog('Error', provider.errorMessage!);
        }
      }
    }
  }

  // Send rescuer location to customer via socket every 5 seconds
  void _startSendingLocation() async {
    final user = await ApiService.getSavedUser();
    if (user == null) return;

    final provider = Provider.of<TrackingProvider>(context, listen: false);

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;

      final location = provider.userLatLng;
      if (location != null) {
        SocketService.updateRescuerLocation(
          rescuerId: user['_id'],
          requestId: widget.requestId,
          lat: location.latitude,
          lng: location.longitude,
        );
      }
      return mounted;
    });
  }

  void _centerCameraToBothLocations() {
    final provider = Provider.of<TrackingProvider>(context, listen: false);
    final cameraPosition = provider.getCameraPositionForBothLocations();
    if (cameraPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

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

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Service'),
        content: const Text('Mark this job as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await RescuerService.completeJob(widget.requestId);

              if (mounted) {
                final provider =
                    Provider.of<TrackingProvider>(context, listen: false);
                provider.stopUserTracking();
                provider.stopRescuerTracking();
                context.go('/rescuer-dashboard');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Service completed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Complete'),
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeTracking,
                    child: const Text('Retry Navigation'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // ─── Google Map ───────────────────────────────────────────
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: trackingProvider.userLatLng!,
                  zoom: 13.0,
                ),
                markers: trackingProvider.markers,
                polylines: trackingProvider.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _centerCameraToBothLocations();
                },
              ),

              // ─── Distance Info ────────────────────────────────────────
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
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Customer is ${trackingProvider.formattedDistance} away',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Center Button ────────────────────────────────────────
              Positioned(
                right: 16,
                top: 90,
                child: FloatingActionButton.small(
                  heroTag: 'center_nav',
                  backgroundColor: Colors.white,
                  onPressed: _centerCameraToBothLocations,
                  child: const Icon(Icons.center_focus_strong,
                      color: AppColors.primary),
                ),
              ),

              // ─── Bottom Sheet ─────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.secondary,
                            child:
                                Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.customerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text('Problem: ${widget.problemType}'),
                              ],
                            ),
                          ),
                          Text(
                            'PKR ${widget.finalFare}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary),
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
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                    color: AppColors.error),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _showCompleteDialog,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary),
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
