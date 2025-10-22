import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushServiceMin {
  static final PushServiceMin _i = PushServiceMin._();
  factory PushServiceMin() => _i;
  PushServiceMin._();

  final _messaging = FirebaseMessaging.instance;
  final _flnp = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // trùng với server nếu có set
    'High importance',
    description: 'High importance notifications',
    importance: Importance.high,
  );

  bool _inited = false;

  Future<void> init({required BuildContext context}) async {
    if (_inited) return;
    _inited = true;

    // 1) Xin quyền
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2) Khởi tạo plugin + tạo channel Android
    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: initSettingsAndroid);
    await _flnp.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        _handleTap(context, resp.payload);
      },
    );
    await _flnp
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // iOS (nếu build iOS) – cho phép hiện khi foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3) Foreground: tự show local notification để có thẻ ngoài status bar
    FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
      final title = m.notification?.title ?? m.data['title'] ?? 'Thông báo';
      final body =
          m.notification?.body ?? m.data['body'] ?? 'Bạn có hoạt động mới';
      final payload = jsonEncode(m.data);

      await _flnp.show(
        m.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: payload,
      );
    });

    // 4) Người dùng bấm vào notification
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      if (!context.mounted) return;
      _handleTap(context, jsonEncode(m.data));
    });

    // 5) App mở từ thông báo khi đang bị kill
    final initial = await _messaging.getInitialMessage();
    if (!context.mounted) return;
    if (initial != null) {
      _handleTap(context, jsonEncode(initial.data));
    }
  }

  void _handleTap(BuildContext context, String? payload) {
    if (payload == null) return;
    // final data = jsonDecode(payload) as Map<String, dynamic>;
  }
}
