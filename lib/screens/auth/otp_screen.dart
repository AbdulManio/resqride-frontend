import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../../services/notification_service.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit code')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final phone = authProvider.phoneNumber ?? '';

    setState(() => _isLoading = true);

    final response = await AuthService.verifyOtp(
      phone: phone,
      otp: _otpCode,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      final user = response['user'] as Map<String, dynamic>?;
      final bool isNewUser = response['isNewUser'] ?? true;

      final String userName = user != null ? (user['name'] ?? '') : '';
      final String userEmail = user != null ? (user['email'] ?? '') : '';
      final String userPhone = user != null ? (user['phone'] ?? phone) : phone;
      final String? userAddress = user != null ? user['address'] : null;
      final String? userVehicle = user != null ? user['vehicleInfo'] : null;

      // Update local auth provider with real user data
      authProvider.login(
        name: userName,
        email: userEmail,
        phoneNumber: userPhone,
        address: userAddress,
        vehicleInfo: userVehicle,
      );

      // Connect socket with real userId
      if (user != null && user['_id'] != null) {
        await SocketService.connect(user['_id']);
      }

      await NotificationService.saveTokenAfterLogin();

      if (isNewUser || userName.isEmpty || userEmail.isEmpty) {
        // New user or incomplete profile → complete profile
        context.push('/registration');
      } else {
        // Returning user → go to dashboard
        final role = user != null ? user['role'] : '';
        if (role == 'rescuer') {
          final status = user != null ? user['accountStatus'] : 'pending';
          if (status == 'pending') {
            context.go('/account-status');
          } else {
            context.go('/rescuer-dashboard');
          }
        } else {
          context.go('/customer-dashboard');
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Invalid OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    final authProvider = context.read<AuthProvider>();
    final phone = authProvider.phoneNumber ?? '';
    final role = authProvider.role == UserRole.rescuer ? 'rescuer' : 'customer';

    final response = await AuthService.sendOtp(phone: phone, role: role);

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['otp'] != null
              ? 'Dev OTP: ${response['otp']}'
              : 'OTP resent successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Enter verification code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Code sent to ${authProvider.phoneNumber ?? ''}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (index) => Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        // Auto-verify when all 4 digits entered
                        if (_otpCode.length == 4) {
                          _verifyOtp();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: AppColors.secondary)
                    : const Text('Verify',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
