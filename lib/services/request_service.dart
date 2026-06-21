import 'api_service.dart';

class RequestService {
  // ─────────────────────────────────────────────────────────────────────────
  // Create a new service request
  // Called from: CreateRequestScreen when customer taps "Find Rescuers"
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createRequest({
    required String problemType,
    required int offeredFare,
    required double lat,
    required double lng,
    String description = '',
    String address = '',
    int? estimatedPrice,
  }) async {
    return await ApiService.authPost('/services/request', {
      'problemType': problemType,
      'offeredFare': offeredFare,
      'lat': lat,
      'lng': lng,
      'description': description,
      'address': address,
      if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get all offers for a request
  // Called from: OffersScreen to show rescuer offers
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getOffers(String requestId) async {
    return await ApiService.authGet('/offers/$requestId');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Accept a rescuer's offer
  // Called from: OffersScreen when customer taps "Accept"
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> acceptOffer(String offerId) async {
    return await ApiService.authPatch('/offers/$offerId/accept', {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get customer's active request
  // Called from: CustomerDashboardScreen on load
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getActiveRequest() async {
    return await ApiService.authGet('/services/active');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get customer's request history
  // Called from: HistoryScreen
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyRequests() async {
    return await ApiService.authGet('/services/my-requests');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cancel a request
  // Called from: CustomerDashboardScreen or TrackingScreen
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> cancelRequest(String requestId) async {
    return await ApiService.authPatch('/services/$requestId/cancel', {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get nearby rescuers (for map display on dashboard)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getNearbyRescuers({
    required double lat,
    required double lng,
  }) async {
    return await ApiService.authGet(
        '/services/nearby-rescuers?lat=$lat&lng=$lng');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submit rating after job completion
  // Called from: RatingScreen when customer taps "Submit"
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitRating({
    required String requestId,
    required int stars,
    String comment = '',
  }) async {
    return await ApiService.authPost('/ratings', {
      'requestId': requestId,
      'stars': stars,
      'comment': comment,
    });
  }
}

class RescuerService {
  // ─────────────────────────────────────────────────────────────────────────
  // Send a fare offer on a customer's request
  // Called from: RescuerDashboardScreen → FareOfferScreen
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendOffer({
    required String requestId,
    required int counterFare,
    double? distanceKm,
    int? etaMinutes,
  }) async {
    return await ApiService.authPost('/offers', {
      'requestId': requestId,
      'counterFare': counterFare,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (etaMinutes != null) 'etaMinutes': etaMinutes,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mark job as complete
  // Called from: RescuerNavigationMapScreen when job is done
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> completeJob(String requestId) async {
    return await ApiService.authPatch('/services/$requestId/complete', {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Toggle online/offline
  // Called from: RescuerDashboardScreen toggle switch
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> toggleOnline(bool isOnline) async {
    return await ApiService.authPatch('/users/toggle-online', {
      'isOnline': isOnline,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submit rescuer profile setup (documents, services)
  // Called from: ProfileSetupScreen
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> setupProfile({
    required List<String> services,
    required bool isShopOwner,
    String? vehicleInfo,
    String? cnicPhoto,
    String? licensePhoto,
  }) async {
    return await ApiService.authPut('/users/rescuer-setup', {
      'services': services,
      'isShopOwner': isShopOwner,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      if (cnicPhoto != null) 'cnicPhoto': cnicPhoto,
      if (licensePhoto != null) 'licensePhoto': licensePhoto,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get earnings summary
  // Called from: EarningsScreen
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEarnings() async {
    return await ApiService.authGet('/users/earnings');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Update GPS location (called periodically while online)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateLocation({
    required double lat,
    required double lng,
  }) async {
    return await ApiService.authPatch('/users/location', {
      'lat': lat,
      'lng': lng,
    });
  }
}
