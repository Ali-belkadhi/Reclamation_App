import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/login_viewmodel.dart';
import 'views/login_view.dart';

// Clé globale pour gérer l'état de la navigation dans toute l'application
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Point d'entrée de l'application Flutter
Future<void> main() async {
  // Assure que l'initialisation des widgets Flutter est faite avant d'exécuter du code asynchrone
  WidgetsFlutterBinding.ensureInitialized();
  
  // Définit le gestionnaire des messages de notification Firebase en tâche de fond (lorsque l'application est fermée)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialise le service de notifications push
  await PushNotificationService.instance.initialize(navigatorKey);

  // Instancie le service d'authentification API
  final authService = ApiAuthService();
  
  // Instancie le ViewModel de connexion avec son service
  final loginViewModel = LoginViewModel(authService: authService);

  // Démarre l'application
  runApp(MyApp(loginViewModel: loginViewModel));
  
  // Après le premier rendu graphique de l'application, traite la notification initiale s'il y en a une
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService.instance.handleInitialNotification();
  });
}

// Widget principal racine de l'application (Stateless : pas d'état mutable direct)
class MyApp extends StatelessWidget {
  final LoginViewModel loginViewModel;

  const MyApp({super.key, required this.loginViewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Associe la clé globale de navigation
      title: 'Attijari Mobile',
      debugShowCheckedModeBanner: false, // Supprime le bandeau de debug rouge en haut à droite
      theme: AppTheme.lightTheme, // Applique le thème graphique personnalisé de l'application
      home: LoginView(viewModel: loginViewModel), // Écran d'accueil de l'application (la connexion)
    );
  }
}