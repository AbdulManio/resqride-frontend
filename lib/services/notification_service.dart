import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

// ─── Background message handler ──────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // Initialize — call this in main.dart before runApp()
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    // Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 Notification permission: ${settings.authorizationStatus}');

    // Handle foreground messages (just print for now)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground: ${message.notification?.title}');
      print('📩 Body: ${message.notification?.body}');
    });

    // Save FCM token to backend
    await _saveTokenToBackend();

    // Refresh token listener
    _messaging.onTokenRefresh.listen((token) {
      _sendTokenToBackend(token);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save FCM token to backend
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _saveTokenToBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final savedToken = await ApiService.getToken();
      if (savedToken == null) return;

      await ApiService.authPatch('/notifications/fcm-token', {
        'fcmToken': token,
      });
      print('✅ FCM token saved to backend');
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Call this after login to save token
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> saveTokenAfterLogin() async {
    await _saveTokenToBackend();
  }

  static Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  static void onMessageOpenedApp(Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }
}
