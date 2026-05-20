import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class AccountStatusScreen extends StatefulWidget {
  const AccountStatusScreen({super.key});

  @override
  State<AccountStatusScreen> createState() => _AccountStatusScreenState();
}

class _AccountStatusScreenState extends State<AccountStatusScreen> {
  String _status = 'pending';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final response = await AuthService.getMe();
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() {
        _status = response['user']['accountStatus'] ?? 'pending';
      });

      // If approved, go to dashboard automatically
      if (_status == 'approved' && mounted) {
        context.go('/rescuer-dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ─── Status Icon ───────────────────────────────────
                    Icon(
                      _status == 'approved'
                          ? Icons.check_circle
                          : _status == 'rejected'
                              ? Icons.cancel
                              : Icons.timer_outlined,
                      size: 100,
                      color: _status == 'approved'
                          ? Colors.green
                          : _status == 'rejected'
                              ? Colors.red
                              : AppColors.primary,
                    ),
                    const SizedBox(height: 24),

                    // ─── Status Title ──────────────────────────────────
                    Text(
                      _status == 'approved'
                          ? '🎉 Account Approved!'
                          : _status == 'rejected'
                              ? '❌ Application Rejected'
                              : '⏳ Application Pending',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // ─── Status Message ────────────────────────────────
                    Text(
                      _status == 'approved'
                          ? 'Your account has been approved! You can now go online and start receiving requests.'
                          : _status == 'rejected'
                              ? 'Your application was rejected. Please resubmit your documents with clearer photos.'
                              : 'Your rescuer account application is currently under review. This usually takes 24-48 hours.',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 48),

                    // ─── Check Again Button ────────────────────────────
                    ElevatedButton.icon(
                      onPressed: _checkStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check Status Again'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_status == 'rejected') ...[
                      ElevatedButton(
                        onPressed: () => context.go('/profile-setup'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Resubmit Documents'),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextButton(
                      onPressed: () => context.go('/role-selection'),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
