import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/login_viewmodel.dart';
import 'views/login_view.dart';

// Clé globale pour la navigation (accessible dans tout l'app)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// Point d'entrée de l'application
// ─────────────────────────────────────────────────────────────────────────────
Future<void> main() async {
  // ÉTAPE 1 : Initialiser les bindings Flutter (OBLIGATOIRE avant tout code async)
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[APP] ✅ WidgetsFlutterBinding initialisé');

  // ÉTAPE 2 : Enregistrer le handler de background FCM AVANT Firebase.initializeApp()
  // Ce handler est appelé quand l'app est FERMÉE et qu'une notification arrive
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  debugPrint('[APP] ✅ Handler de background FCM enregistré');

  // ÉTAPE 3 : Initialiser Firebase + toutes les écoutes FCM
  await PushNotificationService.instance.initialize(navigatorKey);
  debugPrint('[APP] ✅ PushNotificationService initialisé');

  // ÉTAPE 4 : Créer les services et ViewModels
  final authService = ApiAuthService();
  final loginViewModel = LoginViewModel(authService: authService);
  debugPrint('[APP] ✅ Services et ViewModels créés');

  // ÉTAPE 5 : Lancer l'application
  runApp(MyApp(loginViewModel: loginViewModel));
  debugPrint('[APP] ✅ Application lancée');

  // ÉTAPE 6 : Traiter la notification initiale après le premier frame
  // (si l'app a été ouverte en cliquant sur une notification alors qu'elle était FERMÉE)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugPrint('[APP] Vérification du message initial...');
    PushNotificationService.instance.handleInitialNotification();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget racine de l'application
// ─────────────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  final LoginViewModel loginViewModel;

  const MyApp({super.key, required this.loginViewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Attijari Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LoginView(viewModel: loginViewModel),
    );
  }
}