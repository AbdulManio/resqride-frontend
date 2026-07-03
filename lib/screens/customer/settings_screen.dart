import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ─── Account Section ─────────────────────────────────────────
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: const Text('Profile Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/customer-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: AppColors.primary),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/customer-notifications'),
          ),

          // ─── Privacy Section ─────────────────────────────────────────
          _SectionHeader(title: 'Privacy'),
          ListTile(
            leading: const Icon(Icons.security, color: AppColors.primary),
            title: const Text('Privacy & Security'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-security'),
          ),

          // ─── Support Section ─────────────────────────────────────────
          _SectionHeader(title: 'Support'),
          ListTile(
            leading: const Icon(Icons.help, color: AppColors.primary),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/live-support'),
          ),
          ListTile(
            leading: const Icon(Icons.quiz, color: AppColors.primary),
            title: const Text('FAQs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/help-support'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.primary),
            title: const Text('About ResQRide'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'ResQRide',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.car_repair,
                  color: AppColors.primary, size: 40),
              children: [
                const Text('AI-powered roadside assistance app for Pakistan.'),
              ],
            ),
          ),

          const Divider(),

          // ─── Logout ──────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context, authProvider),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
