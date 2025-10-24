import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/fcm_token_service.dart';

/// Đồng bộ FCM token với users/{uid}/fcmTokens/{token}
/// - Gọi trong main.dart ngay sau Firebase.initializeApp()
class PushBootstrap {
  static void start() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;

      // Bật auto-init để FCM tự sinh token
      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      // Xin quyền (Android 13+/iOS). Android <13 sẽ luôn granted.
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Lấy token với retry (tránh trường hợp null sau khi deleteToken)
      final token = await _getTokenWithRetry();
      if (token != null) {
        await FcmTokenService().saveDeviceToken(token);
      }

      // Lưu khi token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        FcmTokenService().saveDeviceToken(t);
      });
    });
  }

  static Future<String?> _getTokenWithRetry() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) return token;

    // Thử “force refresh” một lần nếu vẫn null
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    // Retry tối đa 3 lần, cách nhau 1s
    for (int i = 0; i < 3; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      token = await FirebaseMessaging.instance.getToken();
      if (token != null) return token;
    }
    return null;
  }
}
