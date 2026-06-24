import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/tracking_provider.dart';
import '../../services/socket_service.dart';
import '../../services/request_service.dart';

class TrackingScreen extends StatefulWidget {
  final String requestId;
  final int finalFare;

  const TrackingScreen({
    super.key,
    required this.requestId,
    required this.finalFare,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  bool _isInitialized = false;
  String _rescuerName = 'Rescuer';
  String _rescuerVehicle = '';
  String? _rescuerProfileUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTracking();
      _listenToRescuerLocation();
      _listenForCompletion();
    });
  }

  Future<void> _initializeTracking() async {
    final provider = Provider.of<TrackingProvider>(context, listen: false);
    bool success = await provider.initialize();

    if (success) {
      provider.startUserTracking(enableBackground: true);
      provider.startRescuerTracking(enableBackground: true);
      setState(() => _isInitialized = true);
      _centerCameraToBothLocations();
      _loadActiveRequestDetails();
    } else {
      if (mounted && provider.errorMessage != null) {
        _showErrorDialog('Initialization Error', provider.errorMessage!);
      }
    }
  }

  Future<void> _loadActiveRequestDetails() async {
    final response = await RequestService.getActiveRequest();
    if (response['success'] == true && mounted) {
      final request = response['request'];
      if (request != null && request['rescuer'] != null) {
        final rescuer = request['rescuer'];
        setState(() {
          _rescuerName = rescuer['name'] ?? 'Rescuer';
          _rescuerProfileUrl = rescuer['profilePicture'] ??
              rescuer['avatar'] ??
              rescuer['profileImage'] ??
              rescuer['profilePic'] ??
              rescuer['profilePhoto'] ??
              rescuer['profile'];
        });
      }
    }
  }

  // Listen for rescuer live location via Socket.io
  void _listenToRescuerLocation() {
    SocketService.onRescuerLocation((lat, lng) {
      final provider = Provider.of<TrackingProvider>(context, listen: false);
      provider.updateRescuerLocation(LatLng(lat, lng));

      // Center camera
      if (_mapController != null) {
        _centerCameraToBothLocations();
      }
    });

    // Listen for job completion
    SocketService.onRequestCompleted((data) {
      if (mounted) {
        final provider = Provider.of<TrackingProvider>(context, listen: false);
        provider.stopUserTracking();
        provider.stopRescuerTracking();
        context.push('/rating');
      }
    });
  }

  // Listen for job completion notification
  void _listenForCompletion() {
    SocketService.onRequestCompleted((data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job completed! Please rate your rescuer.'),
            backgroundColor: Colors.green,
          ),
        );
        final provider = Provider.of<TrackingProvider>(context, listen: false);
        provider.stopUserTracking();
        provider.stopRescuerTracking();
        context.push('/rating');
      }
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

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await RequestService.cancelRequest(widget.requestId);
      if (mounted) {
        final provider = Provider.of<TrackingProvider>(context, listen: false);
        provider.stopUserTracking();
        provider.stopRescuerTracking();
        context.go('/customer-dashboard');
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    SocketService.off('rescuer:location');
    SocketService.off('request:completed');
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
                      onPressed: _initializeTracking,
                      child: const Text('Retry'),
                    ),
                  ],
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

              // ─── Distance & ETA Info ──────────────────────────────────
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car,
                                color: AppColors.primary, size: 24),
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
                              icon: Icons.payments,
                              label: 'PKR ${widget.finalFare}',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // ─── Center Camera Button ─────────────────────────────────
              Positioned(
                right: 16,
                top: 90,
                child: FloatingActionButton.small(
                  heroTag: 'center_camera',
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
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                           CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            backgroundImage: (_rescuerProfileUrl != null &&
                                    _rescuerProfileUrl!.isNotEmpty)
                                ? NetworkImage(_rescuerProfileUrl!)
                                : null,
                            child: (_rescuerProfileUrl == null ||
                                    _rescuerProfileUrl!.isEmpty)
                                ? const Icon(Icons.person,
                                    size: 30, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _rescuerName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Final fare: PKR ${widget.finalFare}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.call,
                                color: AppColors.primary, size: 30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Request ID: ${widget.requestId.substring(0, 8)}...',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: _cancelRequest,
                            child: const Text('Cancel Request',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
