import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase background indisponible: $error');
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  late final FirebaseMessaging _messaging;
  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<String>? _tokenSubscription;
  RemoteMessage? _initialMessage;
  String? _currentUserId;
  bool _firebaseAvailable = false;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      _firebaseAvailable = true;

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
      _initialMessage = await _messaging.getInitialMessage();

      _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
        final userId = _currentUserId;
        if (userId != null) {
          _sendTokenToBackend(userId, token);
        }
      });
    } catch (error) {
      _firebaseAvailable = false;
      debugPrint(
        'Firebase non configuré. Ajoutez la configuration FlutterFire: $error',
      );
    }
  }

  Future<void> registerTokenForUser(String userId) async {
    _currentUserId = userId;
    if (!_firebaseAvailable) return;

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _sendTokenToBackend(userId, token);
      }
    } catch (error) {
      debugPrint('Impossible de récupérer le token FCM: $error');
    }
  }

  void clearCurrentUser() {
    _currentUserId = null;
  }

  void handleInitialNotification() {
    final message = _initialMessage;
    _initialMessage = null;
    if (message != null) {
      _handleNotificationOpen(message);
    }
  }

  Future<void> _sendTokenToBackend(String userId, String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/devices/register-token'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'fcmToken': token,
              'deviceType': _deviceType,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Enregistrement FCM refusé (${response.statusCode}): ${response.body}',
        );
      }
    } catch (error) {
      debugPrint('Backend indisponible pour enregistrer le token FCM: $error');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? 'Nouvelle notification';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    _showSnackBar(title, body);
  }

  void _handleNotificationOpen(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? 'Réclamation';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    _showSnackBar(title, body);
  }

  void _showSnackBar(String title, String body) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title\n$body'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get _deviceType {
    if (kIsWeb) return 'WEB';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => 'IOS',
      _ => 'ANDROID',
    };
  }

  void dispose() {
    _tokenSubscription?.cancel();
  }
}
