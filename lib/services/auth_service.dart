import 'dart:async';
import '../models/user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<User> login(String email, String password);
}

class MockAuthService implements AuthService {
  @override
  Future<User> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Simple authentication logic for demonstration
    final formattedEmail = email.trim().toLowerCase();
    
    if (formattedEmail.isEmpty || password.isEmpty) {
      throw AuthException('Veuillez remplir tous les champs.');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(formattedEmail)) {
      throw AuthException('Adresse email invalide.');
    }

    // Mock successful authentication for specific credentials
    if (formattedEmail == 'attijari@bank.com' && password == 'attijari2026') {
      return const User(
        id: 'usr_attijari_123',
        email: 'attijari@bank.com',
        name: 'Client Attijari',
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
      );
    } else if (formattedEmail == 'test@attijari.tn' && password == 'test1234') {
      return const User(
        id: 'usr_test_456',
        email: 'test@attijari.tn',
        name: 'Utilisateur Test',
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
      );
    } else {
      throw AuthException('Identifiants incorrects. Veuillez réessayer.');
    }
  }
}
