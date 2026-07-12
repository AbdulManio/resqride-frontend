import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static const String _serverUrl = 'https://rescueride-backend.vercel.app';
  // On real device use your WiFi IP: 'http://192.168.x.x:5000'

  // ─────────────────────────────────────────────────────────────────────────
  // Connect to socket server and register userId
  // Call this right after login/OTP verification
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> connect(String userId) async {
    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Socket connected');
      // Register this user so server knows which socket = which userId
      _socket!.emit('register', {'userId': userId});
    });

    _socket!.onDisconnect((_) => print('🔴 Socket disconnected'));
    _socket!.onError((err) => print('❌ Socket error: $err'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Join a request room (both customer & rescuer call this)
  // Call after offer is accepted
  // ─────────────────────────────────────────────────────────────────────────
  static void joinRequest(String requestId) {
    _socket?.emit('join:request', {'requestId': requestId});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESCUER: Send live location update
  // Call this every few seconds from TrackingProvider
  // ─────────────────────────────────────────────────────────────────────────
  static void updateRescuerLocation({
    required String rescuerId,
    required String requestId,
    required double lat,
    required double lng,
  }) {
    _socket?.emit('rescuer:location-update', {
      'rescuerId': rescuerId,
      'requestId': requestId,
      'lat': lat,
      'lng': lng,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CUSTOMER: Send live location update
  // ─────────────────────────────────────────────────────────────────────────
  static void updateCustomerLocation({
    required String customerId,
    required String requestId,
    required double lat,
    required double lng,
  }) {
    _socket?.emit('customer:location-update', {
      'customerId': customerId,
      'requestId': requestId,
      'lat': lat,
      'lng': lng,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESCUER: Toggle online/offline
  // ─────────────────────────────────────────────────────────────────────────
  static void toggleOnline(String rescuerId, bool isOnline) {
    _socket?.emit('rescuer:toggle-online', {
      'rescuerId': rescuerId,
      'isOnline': isOnline,
    });
  }

  // ─── Listeners ───────────────────────────────────────────────────────────

  // RESCUER: Listen for new customer requests
  static void onNewRequest(Function(Map<String, dynamic>) callback) {
    _socket?.on(
        'new:request', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // CUSTOMER: Listen for rescuer offers coming in
  static void onNewOffer(Function(Map<String, dynamic>) callback) {
    _socket?.on(
        'new:offer', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // RESCUER: Listen for offer accepted by customer
  static void onOfferAccepted(Function(Map<String, dynamic>) callback) {
    _socket?.on(
        'offer:accepted', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // RESCUER: Listen for offer rejected
  static void onOfferRejected(Function(Map<String, dynamic>) callback) {
    _socket?.on(
        'offer:rejected', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // CUSTOMER: Listen for rescuer's live location (TrackingScreen)
  static void onRescuerLocation(Function(double lat, double lng) callback) {
    _socket?.on('rescuer:location', (data) {
      callback(data['lat'].toDouble(), data['lng'].toDouble());
    });
  }

  // CUSTOMER: Listen for job completion → triggers RatingScreen
  static void onRequestCompleted(Function(Map<String, dynamic>) callback) {
    _socket?.on('request:completed',
        (data) => callback(Map<String, dynamic>.from(data)));
  }

  // RESCUER: Listen for request cancellation by customer
  static void onRequestCancelled(Function(Map<String, dynamic>) callback) {
    _socket?.on('request:cancelled',
        (data) => callback(Map<String, dynamic>.from(data)));
  }

  // ─── Remove a specific listener ──────────────────────────────────────────
  static void off(String event) {
    _socket?.off(event);
  }

  // ─── Disconnect socket ───────────────────────────────────────────────────
  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static void onSupportReply(Function(Map<String, dynamic>) callback) {
    _socket?.on(
        'support:reply', (data) => callback(Map<String, dynamic>.from(data)));
  }

  static bool get isConnected => _socket?.connected ?? false;
}
