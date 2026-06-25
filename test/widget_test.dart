import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclamation_attijari/main.dart';
import 'package:reclamation_attijari/services/auth_service.dart';
import 'package:reclamation_attijari/viewmodels/login_viewmodel.dart';

void main() {
  testWidgets('Login view smoke test', (WidgetTester tester) async {
    // Instantiate mock service and view model
    final authService = MockAuthService();
    final loginViewModel = LoginViewModel(authService: authService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(loginViewModel: loginViewModel));

    // Verify brand name and page title are present
    expect(find.text('Attijari bank'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);

    // Verify email and password text fields are present
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify login button is present
    expect(find.text('SE CONNECTER'), findsOneWidget);
  });
}
