import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class RescuerProfileScreen extends StatefulWidget {
  const RescuerProfileScreen({super.key});

  @override
  State<RescuerProfileScreen> createState() => _RescuerProfileScreenState();
}

class _RescuerProfileScreenState extends State<RescuerProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final response = await AuthService.getMe();
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() => _userData = response['user']);
    }
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final name = _userData?['name'] ?? authProvider.name ?? 'Rescuer';
        final phone = _userData?['phone'] ?? authProvider.phoneNumber ?? 'N/A';
        final rating = _userData?['rating'] ?? 0;
        final totalRatings = _userData?['totalRatings'] ?? 0;
        final vehicleInfo = _userData?['vehicleInfo'] ?? 'Not set';
        final services =
            (_userData?['services'] as List?)?.join(', ') ?? 'Not set';
        final accountStatus = _userData?['accountStatus'] ?? 'pending';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rescuer Profile'),
            actions: [
              IconButton(
                  icon: const Icon(Icons.refresh), onPressed: _loadProfile),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () => _showLogoutDialog(context, authProvider),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.secondary,
                        child:
                            Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: accountStatus == 'approved'
                              ? Colors.green
                              : accountStatus == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          accountStatus == 'approved'
                              ? '✅ Verified Rescuer'
                              : accountStatus == 'rejected'
                                  ? '❌ Account Rejected'
                                  : '⏳ Pending Approval',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildInfoTile(Icons.phone, 'Phone', phone),
                      _buildInfoTile(
                          Icons.star,
                          'Rating',
                          totalRatings > 0
                              ? '$rating ⭐ ($totalRatings reviews)'
                              : 'No ratings yet'),
                      _buildInfoTile(
                          Icons.directions_car, 'Vehicle', vehicleInfo),
                      _buildInfoTile(Icons.build, 'Services', services),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => context.push('/profile-setup'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50)),
                        child: const Text('Update Profile'),
                      ),
                    ],
                  ),
                ),
        );
      },
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
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
