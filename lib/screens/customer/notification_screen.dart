import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class CustomerNotificationScreen extends StatefulWidget {
  const CustomerNotificationScreen({super.key});

  @override
  State<CustomerNotificationScreen> createState() =>
      _CustomerNotificationScreenState();
}

class _CustomerNotificationScreenState
    extends State<CustomerNotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final response = await ApiService.authGet('/notifications');

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() => _notifications = response['notifications'] ?? []);
      // Mark as read
      await ApiService.authPatch('/notifications/mark-read', {});
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_offer':
        return Icons.local_offer;
      case 'offer_accepted':
        return Icons.check_circle;
      case 'new_request':
        return Icons.notifications_active;
      case 'job_completed':
        return Icons.task_alt;
      case 'account_approved':
        return Icons.verified;
      case 'account_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'new_offer':
        return AppColors.primary;
      case 'offer_accepted':
        return Colors.green;
      case 'new_request':
        return Colors.orange;
      case 'job_completed':
        return Colors.green;
      case 'account_approved':
        return Colors.green;
      case 'account_rejected':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatElapsedTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr).toLocal();
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You\'ll see updates about your\nrequests here',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final type = n['type'] ?? 'default';
                      final color = _colorForType(type);
                      final isRead = n['isRead'] ?? false;

                      return ListTile(
                        tileColor:
                            isRead ? null : AppColors.primary.withOpacity(0.04),
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(_iconForType(type), color: color),
                        ),
                        title: Text(
                          n['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(n['body'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              n['createdAt'] != null
                                  ? _formatElapsedTime(n['createdAt'])
                                  : '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
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
