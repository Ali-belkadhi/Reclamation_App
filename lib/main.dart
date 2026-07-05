import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/login_viewmodel.dart';
import 'views/login_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService.instance.initialize(navigatorKey);

  final authService = ApiAuthService();
  final loginViewModel = LoginViewModel(authService: authService);

  runApp(MyApp(loginViewModel: loginViewModel));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService.instance.handleInitialNotification();
  });
}

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