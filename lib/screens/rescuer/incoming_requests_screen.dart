import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    // Get rescuer's accepted/in_progress requests
    final response = await ApiService.authGet('/services/rescuer-requests');

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() => _requests = response['requests'] ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No active jobs',
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accepted requests will appear here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    final customer = request['customer'] ?? {};
                    final fare = request['finalFare'] ??
                        request['offeredFare'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                      request['problemType'] ?? 'Request'),
                                  backgroundColor: AppColors.primary,
                                  labelStyle: const TextStyle(
                                      color: Colors.white),
                                ),
                                Text(
                                  'PKR $fare',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 16,
                                    color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text(customer['name'] ?? 'Customer'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16,
                                    color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text(request['location']?['address'] ??
                                    'Customer location'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  context.push('/navigation-map', extra: {
                                'requestId': request['_id'],
                                'customerLat': request['location']
                                        ?['coordinates']?[1] ??
                                    0.0,
                                'customerLng': request['location']
                                        ?['coordinates']?[0] ??
                                    0.0,
                                'customerName':
                                    customer['name'] ?? 'Customer',
                                'problemType':
                                    request['problemType'] ?? '',
                                'finalFare': fare,
                              }),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Navigate to Customer'),
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
