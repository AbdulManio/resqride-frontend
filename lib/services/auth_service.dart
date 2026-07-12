import 'api_service.dart';

class AuthService {
  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: Send OTP to phone
  // Called from: LoginScreen when user taps "Send Code"
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String role, // 'customer' or 'rescuer'
  }) async {
    return await ApiService.post('/auth/send-otp', {
      'phone': phone,
      'role': role,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Verify OTP
  // Called from: OTPScreen when user taps "Verify"
  // Returns: { success, token, isNewUser, user }
  // isNewUser = true  → go to /registration
  // isNewUser = false → go to dashboard
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await ApiService.post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
    });

    // Save token and user if successful
    if (response['success'] == true) {
      await ApiService.saveToken(response['token']);
      await ApiService.saveUser(response['user']);
    }

    return response;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3: Complete registration (name + email)
  // Called from: RegistrationScreen when user taps "Complete Registration"
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    String? vehicleInfo,
    String? address,
  }) async {
    final response = await ApiService.authPost('/auth/register', {
      'name': name,
      'email': email,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      if (address != null) 'address': address,
    });

    // Update saved user with name and email
    if (response['success'] == true) {
      await ApiService.saveUser(response['user']);
    }

    return response;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get current user profile from backend
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMe() async {
    return await ApiService.authGet('/auth/me');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logout — clear saved token and user
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    await ApiService.clearToken();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Check if user is already logged in (app startup)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null;
  }
}
