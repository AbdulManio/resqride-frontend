import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/request_service.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class RescuerDashboardScreen extends StatefulWidget {
  const RescuerDashboardScreen({super.key});

  @override
  State<RescuerDashboardScreen> createState() => _RescuerDashboardScreenState();
}

class _RescuerDashboardScreenState extends State<RescuerDashboardScreen> {
  bool _isOnline = false;
  bool _isTogglingOnline = false;
  List<Map<String, dynamic>> _requests = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _listenForNewRequests();
    _startPolling();
  }

  Future<void> _checkForAcceptedJob() async {
    final response = await ApiService.authGet('/services/my-active-job');
    if (response['success'] == true && mounted) {
      final jobs = List<Map<String, dynamic>>.from(response['requests'] ?? []);
      if (jobs.isNotEmpty) {
        _pollTimer?.cancel();
        final job = jobs.first;
        final coords = job['location']?['coordinates'];
        final double customerLat = (coords != null && coords.length > 1)
            ? (coords[1] as num).toDouble()
            : 0.0;
        final double customerLng = (coords != null && coords.length > 0)
            ? (coords[0] as num).toDouble()
            : 0.0;

        context.push('/navigation-map', extra: {
          'requestId': job['_id'] ?? '',
          'customerLat': customerLat,
          'customerLng': customerLng,
          'customerName': job['customer']?['name'] ?? 'Customer',
          'problemType': job['problemType'] ?? 'Roadside Assistance',
          'finalFare': job['finalFare'] ?? job['offeredFare'] ?? 0,
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_isOnline && mounted) await _pollForRequests();
      await _checkForAcceptedJob();
    });
    _pollForRequests();
  }

  void _startLocationUpdates() async {
    await _sendCurrentLocation(); // Send immediately

    // Then every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_isOnline && mounted) {
        await _sendCurrentLocation();
      }
    });
  }

  Future<void> _sendCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      await RescuerService.updateLocation(
        lat: position.latitude,
        lng: position.longitude,
      );
      print('📍 Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Location error: $e');
    }
  }

  Future<void> _pollForRequests() async {
    final response = await ApiService.authGet('/services/nearby-requests');

    if (response['success'] == true && mounted) {
      final newRequests =
          List<Map<String, dynamic>>.from(response['requests'] ?? []);

      final newIds = newRequests.map((r) => r['_id'].toString()).toList();

      setState(() {
        // Remove requests that are no longer available
        _requests.removeWhere(
          (r) => !newIds.contains(r['requestId']),
        );

        // Add new requests
        for (var req in newRequests) {
          final exists = _requests.any(
            (r) => r['requestId'] == req['_id'],
          );

          if (!exists) {
            _requests.insert(0, {
              'requestId': req['_id'],
              'problemType': req['problemType'],
              'offeredFare': req['offeredFare'],
              'address': req['location']?['address'] ?? 'Customer location',
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService.off('new:request');
    super.dispose();
  }

  // Listen for new requests via Socket.io
  void _listenForNewRequests() {
    SocketService.onNewRequest((data) {
      if (mounted && _isOnline) {
        setState(() {
          final exists =
              _requests.any((r) => r['requestId'] == data['requestId']);
          if (!exists) {
            _requests.insert(0, data);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'New request: ${data['problemType']} — PKR ${data['offeredFare']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  // Toggle online/offline
  Future<void> _toggleOnline(bool value) async {
    setState(() {
      _isOnline = value;
      if (!value) {
        _requests.clear();
        _pollTimer?.cancel();
      }
      if (value) {
        _startPolling();
        _startLocationUpdates(); // ← add this
      }
    });
    if (value) _startPolling();

    final response = await RescuerService.toggleOnline(value);

    setState(() => _isTogglingOnline = false);

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _isOnline = value;
        if (!value) _requests.clear();
      });

      // Update socket
      final user = await ApiService.getSavedUser();
      if (user != null) {
        SocketService.toggleOnline(user['_id'], value);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(value ? '🟢 You are now Online!' : '🔴 You are now Offline'),
          backgroundColor: value ? Colors.green : Colors.grey,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 0) return;
    if (index == 1) context.push('/rescuer-earnings');
    if (index == 2) context.push('/rescuer-profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescuer Dashboard'),
        actions: [
          Row(
            children: [
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _isTogglingOnline
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : Switch(
                      value: _isOnline,
                      onChanged: _toggleOnline,
                      activeThumbColor: AppColors.accent,
                    ),
            ],
          ),
        ],
      ),
      body: _isOnline
          ? _RequestsListView(
              requests: _requests,
              onDecline: (requestId) {
                setState(() =>
                    _requests.removeWhere((r) => r['requestId'] == requestId));
              },
              onRefresh: _pollForRequests,
            )
          : const _OfflineView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onBottomNavTap,
        selectedItemColor: AppColors.secondary,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Requests'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'You are currently offline',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text('Go online to start receiving rescue requests'),
        ],
      ),
    );
  }
}

class _RequestsListView extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final Function(String) onDecline;
  final Future<void> Function() onRefresh;

  const _RequestsListView({
    required this.requests,
    required this.onDecline,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Waiting for requests...',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text('New requests will appear here automatically'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(request['problemType'] ?? 'Request'),
                        backgroundColor: AppColors.primary,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'PKR ${request['offeredFare'] ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (request['estimatedPrice'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Est: PKR ${request['estimatedPrice']}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(request['address'] ?? 'Customer location'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            onDecline(request['requestId'] ?? '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Request declined'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          },
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push(
                            '/fare-offer',
                            extra: {
                              'requestId': request['requestId'] ?? '',
                              'offeredFare': request['offeredFare'] ?? 0,
                              'problemType': request['problemType'] ?? '',
                            },
                          ),
                          child: const Text('Send Offer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
