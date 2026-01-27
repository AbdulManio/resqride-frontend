import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CustomerNotificationScreen extends StatelessWidget {
  const CustomerNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final notifications = [
            {
              'title': 'Service Completed',
              'body':
                  'Your rescue request #1004 has been completed successfully.',
              'time': '2 hours ago',
              'icon': Icons.check_circle,
              'color': Colors.green,
            },
            {
              'title': 'Rescuer Assigned',
              'body':
                  'Ali Khan is on his way to help you with your tire repair.',
              'time': '1 day ago',
              'icon': Icons.person,
              'color': AppColors.primary,
            },
            {
              'title': 'Welcome to Rescue Ride',
              'body':
                  'Thank you for choosing Rescue Ride for your vehicle assistance needs.',
              'time': '2 days ago',
              'icon': Icons.celebration,
              'color': AppColors.accent,
            },
          ];

          final notification = notifications[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  (notification['color'] as Color).withValues(alpha: 0.1),
              child: Icon(notification['icon'] as IconData,
                  color: notification['color'] as Color),
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
                  notification['time'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
