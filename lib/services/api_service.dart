import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ Change this to your machine's IP when testing on a real phone
  // For emulator: http://10.0.2.2:5000/api
  // For real device: http://192.168.x.x:5000/api  ← your WiFi IP
  // For Railway (production)
  // static const String baseUrl = 'https://adventurous-growth-production-bb4a.up.railway.app/api';

  // For Emulator (local testing)
  static const String baseUrl = 'https://rescueride-backend.vercel.app/api';
  // ─── Save JWT token ──────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ─── Get saved JWT token ─────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ─── Delete token on logout ──────────────────────────────────────────────
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ─── Save user data ──────────────────────────────────────────────────────
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  // ─── Get saved user ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  // ─── Headers without auth ────────────────────────────────────────────────
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ─── Headers with JWT ────────────────────────────────────────────────────
  static Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── POST (no auth) ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── POST (with auth) ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> authPost(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _authHeaders,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── GET (with auth) ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> authGet(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _authHeaders,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── PATCH (with auth) ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> authPatch(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _authHeaders,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── PUT (with auth) ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> authPut(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _authHeaders,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
