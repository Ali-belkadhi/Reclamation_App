import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclamation_attijari/main.dart';
import 'package:reclamation_attijari/models/user.dart';
import 'package:reclamation_attijari/services/auth_service.dart';
import 'package:reclamation_attijari/viewmodels/login_viewmodel.dart';

/// Fake auth service used only for tests — does not call the real network.
class FakeAuthService implements AuthService {
  @override
  Future<User> login(String email, String password) async {
    return const User(
      id: 'test_id',
      nom: 'Test',
      prenom: 'User',
      email: 'test@attijari.tn',
      role: 'user',
    );
  }
}

void main() {
  testWidgets('Login view smoke test', (WidgetTester tester) async {
    // Use the local fake service — no real HTTP calls in tests
    final authService = FakeAuthService();
    final loginViewModel = LoginViewModel(authService: authService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(loginViewModel: loginViewModel));

    // Verify page title is present
    expect(find.text('Se connecter'), findsOneWidget);

    // Verify email and password text fields are present
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify login button is present
    expect(find.text('SE CONNECTER'), findsOneWidget);
  });
}

