import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import '../views/reclamation_discussion_view.dart';
import '../models/user.dart';
import '../views/reclamations_view.dart';
import '../theme/app_theme.dart';
import 'reclamation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Handler de background : OBLIGATOIREMENT top-level (hors de toute classe)
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] Message reçu: ${message.messageId}');
  debugPrint('[FCM Background] Titre: ${message.notification?.title}');
  debugPrint('[FCM Background] Corps: ${message.notification?.body}');
  debugPrint('[FCM Background] Data: ${message.data}');
}

// ─────────────────────────────────────────────────────────────────────────────
// Canal Android pour les notifications locales (foreground)
// ─────────────────────────────────────────────────────────────────────────────
const AndroidNotificationChannel _fcmChannel = AndroidNotificationChannel(
  'fcm_high_importance_channel',
  'Notifications importantes',
  description: 'Canal pour les notifications Firebase Cloud Messaging',
  importance: Importance.high,
  playSound: true,
);

// ─────────────────────────────────────────────────────────────────────────────
// Service de notifications push (singleton)
// ─────────────────────────────────────────────────────────────────────────────
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<String>? _tokenSubscription;
  RemoteMessage? _initialMessage;
  String? _currentUserId;
  bool _firebaseAvailable = false;

  // ───────────────────────────────────────────
  // Initialisation principale (appelée dans main())
  // ───────────────────────────────────────────
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    try {
      debugPrint('[FCM] Initialisation de Firebase...');
      await Firebase.initializeApp();
      debugPrint('[FCM] ✅ Firebase initialisé avec succès');

      _messaging = FirebaseMessaging.instance;
      _firebaseAvailable = true;

      // ── 1. Demande de permission (Android 13+ / iOS) ──
      await _requestPermission();

      // ── 2. Configuration des options de présentation foreground (iOS) ──
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // ── 3. Initialisation du plugin local notifications (pour foreground Android) ──
      await _initLocalNotifications();

      // ── 4. Écoute des messages en foreground ──
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      debugPrint('[FCM] ✅ Listener foreground (onMessage) enregistré');

      // ── 5. Écoute du tap sur notification quand l'app est en background ──
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[FCM] 🔔 Notification ouverte depuis le background');
        _handleNotificationOpen(message);
      });
      debugPrint('[FCM] ✅ Listener onMessageOpenedApp enregistré');

      // ── 6. Récupération du message initial (app ouverte via notification) ──
      _initialMessage = await _messaging.getInitialMessage();
      if (_initialMessage != null) {
        debugPrint(
          '[FCM] ℹ️ Message initial détecté: ${_initialMessage!.messageId}',
        );
      }

      // ── 7. Écoute du rafraîchissement du token ──
      _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] 🔄 Token FCM rafraîchi: ${newToken.substring(0, 20)}...');
        final userId = _currentUserId;
        if (userId != null) {
          _sendTokenToBackend(userId, newToken);
        }
      });
      debugPrint('[FCM] ✅ Listener onTokenRefresh enregistré');

      debugPrint('[FCM] ✅ PushNotificationService entièrement initialisé');
    } catch (error, stack) {
      _firebaseAvailable = false;
      debugPrint('[FCM] ❌ Erreur initialisation Firebase: $error');
      debugPrint('[FCM] Stack: $stack');
    }
  }

  // ───────────────────────────────────────────
  // Demande de permission
  // ───────────────────────────────────────────
  Future<void> _requestPermission() async {
    debugPrint('[FCM] Demande de permission notifications...');

    // Sur Android 13+ on demande la permission système via firebase_messaging
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final status = settings.authorizationStatus;
    debugPrint('[FCM] Statut permission: $status');

    if (status == AuthorizationStatus.authorized) {
      debugPrint('[FCM] ✅ Permission accordée');
    } else if (status == AuthorizationStatus.provisional) {
      debugPrint('[FCM] ⚠️ Permission provisoire accordée');
    } else {
      debugPrint('[FCM] ❌ Permission refusée: $status');
    }
  }

  // ───────────────────────────────────────────
  // Initialisation flutter_local_notifications
  // ───────────────────────────────────────────
  Future<void> _initLocalNotifications() async {
    // Création du canal Android (OBLIGATOIRE pour Android 8+)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_fcmChannel);

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[FCM] Notification locale tappée: ${details.payload}');
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!) as Map<String, dynamic>;
            _handleDataPayload(data);
          } catch (_) {}
        }
      },
    );

    debugPrint('[FCM] ✅ flutter_local_notifications initialisé');
  }

  // ───────────────────────────────────────────
  // Enregistrement du token après connexion
  // ───────────────────────────────────────────
  Future<void> registerTokenForUser(String userId) async {
    _currentUserId = userId;

    if (!_firebaseAvailable) {
      debugPrint('[FCM] ⚠️ Firebase non disponible, token non enregistré');
      return;
    }

    try {
      debugPrint('[FCM] Récupération du token FCM pour userId=$userId...');
      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        debugPrint('[FCM] ✅ Token FCM généré: ${token.substring(0, 30)}...');
        await _sendTokenToBackend(userId, token);
      } else {
        debugPrint('[FCM] ❌ Token FCM null ou vide');
      }
    } catch (error) {
      debugPrint('[FCM] ❌ Erreur récupération token FCM: $error');
    }
  }

  // ───────────────────────────────────────────
  // Envoi du token au backend Spring Boot
  // ───────────────────────────────────────────
  Future<void> _sendTokenToBackend(String userId, String token) async {
    debugPrint('[FCM] Envoi du token au backend (userId=$userId)...');

    try {
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (ApiAuthService.currentToken != null) {
        headers['Authorization'] = 'Bearer ${ApiAuthService.currentToken}';
      }

      final payload = {
        'userId': userId,
        'fcmToken': token,
        'deviceType': _deviceType,
      };
      debugPrint('[FCM] Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/devices/register-token'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[FCM] ✅ Token enregistré côté backend (${response.statusCode})');
      } else {
        debugPrint(
          '[FCM] ❌ Échec enregistrement token (${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      debugPrint('[FCM] ⚠️ Timeout lors de l\'envoi du token au backend');
    } catch (error) {
      debugPrint('[FCM] ❌ Erreur réseau envoi token: $error');
    }
  }

  // ───────────────────────────────────────────
  // Gestion message en foreground
  // ───────────────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] 📥 Message reçu en foreground: ${message.messageId}');
    debugPrint('[FCM] Titre: ${message.notification?.title}');
    debugPrint('[FCM] Corps: ${message.notification?.body}');
    debugPrint('[FCM] Data: ${message.data}');

    final notification = message.notification;
    final android = message.notification?.android;

    // Affiche une notification locale (remplace la notif FCM qui n'apparaît pas en foreground sur Android)
    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Nouvelle notification',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _fcmChannel.id,
            _fcmChannel.name,
            channelDescription: _fcmChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
      debugPrint('[FCM] ✅ Notification locale affichée');
    } else {
      // Fallback SnackBar si pas de notification payload
      _showSnackBar(
        notification?.title ?? 'Nouvelle notification',
        notification?.body ?? message.data['body']?.toString() ?? '',
      );
    }
  }

  // ───────────────────────────────────────────
  // Gestion du tap sur une notification
  // ───────────────────────────────────────────
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('[FCM] 🔔 Notification ouverte: ${message.messageId}');
    debugPrint('[FCM] Data: ${message.data}');
    _handleDataPayload(message.data);
  }

  void _handleDataPayload(Map<String, dynamic> data) {
    final reclamationId = data['reclamationId']?.toString();
    final context = _navigatorKey?.currentContext;

    debugPrint('[FCM] Navigation: reclamationId=$reclamationId');

    if (reclamationId != null && context != null && _currentUserId != null) {
      final title = data['title']?.toString() ?? 'Réclamation';
      final body = data['body']?.toString() ?? '';

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReclamationDiscussionView(
            item: ComplaintItem(
              title,
              'Notification',
              'INFO',
              AppColors.primaryRed,
              Icons.notifications,
              id: reclamationId,
              description: body,
            ),
            user: User(
              id: _currentUserId!,
              nom: '',
              prenom: '',
              email: '',
              role: '',
            ),
            reclamationService: ApiReclamationService(),
            onInviteParticipant: () {},
          ),
        ),
      );
    }
  }

  // ───────────────────────────────────────────
  // Traitement du message initial (app lancée via notif)
  // ───────────────────────────────────────────
  void handleInitialNotification() {
    final message = _initialMessage;
    _initialMessage = null;
    if (message != null) {
      debugPrint('[FCM] Traitement du message initial: ${message.messageId}');
      _handleNotificationOpen(message);
    }
  }

  // ───────────────────────────────────────────
  // SnackBar de fallback
  // ───────────────────────────────────────────
  void _showSnackBar(String title, String body) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('[FCM] ⚠️ Impossible d\'afficher le SnackBar: contexte null');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title\n$body'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ───────────────────────────────────────────
  // Déconnexion
  // ───────────────────────────────────────────
  void clearCurrentUser() {
    debugPrint('[FCM] Utilisateur déconnecté, suppression de l\'userId local');
    _currentUserId = null;
  }

  // ───────────────────────────────────────────
  // Type d'appareil
  // ───────────────────────────────────────────
  String get _deviceType {
    if (kIsWeb) return 'WEB';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => 'IOS',
      _ => 'ANDROID',
    };
  }

  // ───────────────────────────────────────────
  // Nettoyage
  // ───────────────────────────────────────────
  void dispose() {
    _tokenSubscription?.cancel();
    debugPrint('[FCM] Service de notifications disposé');
  }
}
