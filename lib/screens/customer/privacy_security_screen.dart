import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              icon: Icons.location_on,
              title: 'Location Data',
              content:
                  'ResQRide uses your GPS location only during active rescue sessions. Your location is shared with rescuers only when you create a service request. We do not track or store your location history.',
            ),
            _buildSection(
              icon: Icons.lock,
              title: 'Data Encryption',
              content:
                  'All your personal data including phone number, name and location is encrypted using industry-standard AES-256 encryption. Your data is transmitted over secure HTTPS connections.',
            ),
            _buildSection(
              icon: Icons.share,
              title: 'Data Sharing',
              content:
                  'We do not sell your personal data to third parties. Your information is only shared with rescuers during active service requests and with payment processors for transactions.',
            ),
            _buildSection(
              icon: Icons.phone_android,
              title: 'Phone Number',
              content:
                  'Your phone number is used for OTP verification and emergency contact only. It is never shared publicly or used for marketing purposes.',
            ),
            _buildSection(
              icon: Icons.delete,
              title: 'Data Deletion',
              content:
                  'You can request deletion of your account and all associated data by contacting our support team at support@resqride.pk. Data will be deleted within 30 days.',
            ),
            _buildSection(
              icon: Icons.security,
              title: 'Account Security',
              content:
                  'ResQRide uses OTP-based authentication for secure login. We recommend never sharing your OTP with anyone including ResQRide staff.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last updated: June 2026\nFor questions contact: privacy@resqride.pk',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(content,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
