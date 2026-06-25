import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

class ApiAuthService implements AuthService {
  // Use 10.0.2.2 for Android emulator (= localhost on your PC)
  // Change to your PC local IP (e.g. 192.168.x.x) for a real device
  static const String _baseUrl = 'http://10.0.2.2:3000';

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse user from response: { message: '...', user: {...} }
        final userJson = data['user'] as Map<String, dynamic>;
        return User.fromJson(userJson);
      } else if (response.statusCode == 401) {
        throw AuthException('Email ou mot de passe incorrect.');
      } else {
        final message = data['message'] ?? 'Erreur serveur. Veuillez réessayer.';
        throw AuthException(message.toString());
      }
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw AuthException('Le serveur ne répond pas. Vérifiez votre connexion.');
    } catch (e) {
      throw AuthException('Impossible de joindre le serveur. Vérifiez votre réseau.');
    }
  }
}

