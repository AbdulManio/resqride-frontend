import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/request_service.dart';

class CustomerNotificationScreen extends StatefulWidget {
  const CustomerNotificationScreen({super.key});

  @override
  State<CustomerNotificationScreen> createState() =>
      _CustomerNotificationScreenState();
}

class _CustomerNotificationScreenState
    extends State<CustomerNotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final activeRes = await RequestService.getActiveRequest();
      final historyRes = await RequestService.getMyRequests();

      List<Map<String, dynamic>> requestsList = [];
      if (activeRes['success'] == true && activeRes['request'] != null) {
        requestsList.add(activeRes['request']);
      }
      if (historyRes['success'] == true && historyRes['requests'] != null) {
        final history = List<Map<String, dynamic>>.from(historyRes['requests']);
        for (var r in history) {
          if (!requestsList.any((existing) => existing['_id'] == r['_id'])) {
            requestsList.add(r);
          }
        }
      }

      List<Map<String, dynamic>> notificationsList = [];

      // Add Welcome notification using user registration date
      final user = await ApiService.getSavedUser();
      DateTime? welcomeTime;
      if (user != null && user['createdAt'] != null) {
        welcomeTime = DateTime.parse(user['createdAt']).toLocal();
      }

      for (var request in requestsList) {
        final status = request['status'] ?? 'pending';
        final problemType = request['problemType'] ?? 'Service Request';
        final rescuerName = request['rescuer'] != null
            ? (request['rescuer']['name'] ?? 'Rescuer')
            : 'Rescuer';
        final updatedAtStr = request['updatedAt'] ?? request['createdAt'];
        final time = updatedAtStr != null
            ? DateTime.parse(updatedAtStr).toLocal()
            : DateTime.now();

        if (status == 'completed') {
          notificationsList.add({
            'title': 'Service Completed',
            'body':
                'Your rescue request for $problemType has been completed successfully.',
            'dateTime': time,
            'icon': Icons.check_circle,
            'color': Colors.green,
          });
        } else if (status == 'accepted') {
          notificationsList.add({
            'title': 'Rescuer Assigned',
            'body':
                '$rescuerName is on his way to help you with your ${problemType.toLowerCase()}.',
            'dateTime': time,
            'icon': Icons.person,
            'color': AppColors.primary,
          });
        } else if (status == 'cancelled') {
          notificationsList.add({
            'title': 'Request Cancelled',
            'body': 'Your rescue request for $problemType was cancelled.',
            'dateTime': time,
            'icon': Icons.cancel,
            'color': Colors.red,
          });
        } else if (status == 'pending') {
          notificationsList.add({
            'title': 'Searching for Rescuers',
            'body':
                'We are looking for nearby rescuers for your $problemType request.',
            'dateTime': time,
            'icon': Icons.search,
            'color': AppColors.accent,
          });
        }
      }

      // Add welcome notification
      notificationsList.add({
        'title': 'Welcome to Rescue Ride',
        'body':
            'Thank you for choosing Rescue Ride for your vehicle assistance needs.',
        'dateTime':
            welcomeTime ?? DateTime.now().subtract(const Duration(days: 2)),
        'icon': Icons.celebration,
        'color': AppColors.accent,
      });

      // Sort by dateTime descending
      notificationsList
          .sort((a, b) => (b['dateTime'] as DateTime).compareTo(a['dateTime'] as DateTime));

      setState(() {
        _notifications = notificationsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatElapsedTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute(s) ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day(s) ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final color = notification['color'] as Color;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(
                        notification['icon'] as IconData,
                        color: color,
                      ),
                    ),
                    title: Text(
                      notification['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification['body'] as String),
                        const SizedBox(height: 4),
                        Text(
                          _formatElapsedTime(notification['dateTime'] as DateTime),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
