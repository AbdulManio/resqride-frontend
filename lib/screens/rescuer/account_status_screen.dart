import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 100, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Application Pending',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your rescuer account application is currently under review. This usually takes 24-48 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/rescuer-dashboard'),
                child: const Text('Go to Dashboard (Preview Mode)'),
              ),
              const SizedBox(height: 16),
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
