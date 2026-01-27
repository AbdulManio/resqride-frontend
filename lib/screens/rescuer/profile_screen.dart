import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RescuerProfileScreen extends StatelessWidget {
  const RescuerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rescuer Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () => _showLogoutDialog(context, authProvider),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.name ?? 'Ali Khan',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Verified Rescuer',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 32),
                _buildInfoSection(context, authProvider),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.push('/profile-setup'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Update Profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        _buildInfoTile(Icons.phone, 'Phone',
            authProvider.phoneNumber ?? '+92 312 9876543'),
        _buildInfoTile(Icons.directions_car, 'Vehicle',
            authProvider.vehicleInfo ?? 'Suzuki Carry (LET-1234)'),
        _buildInfoTile(Icons.star, 'Total Rating', '4.8 (120 reviews)'),
        _buildInfoTile(Icons.location_on, 'Service Area',
            authProvider.address ?? 'Islamabad & Rawalpindi'),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.secondary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
              context.go('/role-selection');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
