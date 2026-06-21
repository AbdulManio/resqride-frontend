import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AiApiService {
  // ─── AI Service Base URL ──────────────────────────────────────────────────
  // Use http://10.0.2.2:8000 for Android emulator
  // Use http://localhost:8000 for iOS simulator / Flutter Web
  // Use http://192.168.x.x:8000 for real device testing (your local IP)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // Android emulator connects to host via 10.0.2.2
    // iOS simulator connects to host via localhost/127.0.0.1
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  // ─── Fetch All Hotspots ────────────────────────────────────────────────────
  // Calls GET /api/hotspot/all to fetch list of hotspots with predicted risk levels
  // ───────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getHotspots() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/hotspot/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('❌ Failed to fetch hotspots: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error calling getHotspots: $e');
      return [];
    }
  }

  // ─── Fetch Single Coordinate Risk ──────────────────────────────────────────
  // Calls POST /api/hotspot/predict
  // ───────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> predictSingleHotspot({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/hotspot/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('❌ Failed hotspot predict: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error calling predictSingleHotspot: $e');
      return null;
    }
  }

  // ─── Predict Service Price ──────────────────────────────────────────────────
  // Calls POST /api/price/predict
  // ───────────────────────────────────────────────────────────────────────────
  static Future<int?> predictPrice({
    required String serviceType,
    required String vehicleType,
    required double distance,
    required double lat,
    required double lng,
  }) async {
    try {
      final body = jsonEncode({
        'serviceType': serviceType,
        'vehicleType': vehicleType,
        'distance': distance,
        'latitude': lat,
        'longitude': lng,
      });
      
      debugPrint('Calling predictPrice with body: $body');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/price/predict'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['estimatedPrice'] as int?;
      } else {
        debugPrint('❌ Failed price predict: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error calling predictPrice: $e');
      return null;
    }
  }
}
