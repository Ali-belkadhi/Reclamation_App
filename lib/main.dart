import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/login_viewmodel.dart';
import 'views/login_view.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate dependencies (services)
  final authService = MockAuthService();

  // Instantiate view models
  final loginViewModel = LoginViewModel(authService: authService);

  runApp(MyApp(loginViewModel: loginViewModel));
}

class MyApp extends StatelessWidget {
  final LoginViewModel loginViewModel;

  const MyApp({super.key, required this.loginViewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attijari Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LoginView(viewModel: loginViewModel),
    );
  }
}
