import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AiApiService {
  static const String baseUrl = 'https://manioshaikh1.pythonanywhere.com';

  // ─── Fetch All Hotspots ───────────────────────────────────────────────────
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
        debugPrint('❌ Failed to fetch hotspots: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error calling getHotspots: $e');
      return [];
    }
  }

  // ─── Predict Single Hotspot ───────────────────────────────────────────────
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
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error calling predictSingleHotspot: $e');
      return null;
    }
  }

  // ─── Predict Service Price ────────────────────────────────────────────────
  static Future<int?> predictPrice({
    required String serviceType,
    required String vehicleType,
    required double distance,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/price/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'serviceType': serviceType,
          'vehicleType': vehicleType,
          'distance': distance,
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['estimatedPrice'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error calling predictPrice: $e');
      return null;
    }
  }
}
