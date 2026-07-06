import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';

// Exception personnalisée levée en cas d'échec de l'authentification
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

// Interface abstraite définissant le contrat du service d'authentification
abstract class AuthService {
  Future<User> login(String email, String password);
}

// Implémentation concrète de l'authentification via l'API REST
class ApiAuthService implements AuthService {
  @override
  Future<User> login(String email, String password) async {
    try {
      // 1. Envoi de la requête POST avec l'email et le mot de passe encodés en JSON
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10)); // Délai d'expiration de 10s

      // 2. Décodage du corps de la réponse JSON brute
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // 3. Gestion du statut de la réponse HTTP
      if (response.statusCode == 200 || response.statusCode == 201) {
        // En cas de succès, on extrait le nœud JSON 'user' et on le convertit en objet User typé
        final userJson = data['user'] as Map<String, dynamic>;
        return User.fromJson(userJson);
      } else if (response.statusCode == 401) {
        // Échec d'authentification (identifiants incorrects)
        throw AuthException('Email ou mot de passe incorrect.');
      } else {
        // Autres erreurs retournées par le serveur
        final message = data['message'] ?? 'Erreur serveur. Veuillez réessayer.';
        throw AuthException(message.toString());
      }
    } on AuthException {
      rethrow;
    } on TimeoutException {
      // Dépassement de délai (serveur injoignable dans les temps)
      throw AuthException('Le serveur ne répond pas. Vérifiez votre connexion.');
    } catch (e) {
      // Erreur réseau générique (pas d'internet, serveur indisponible, etc.)
      throw AuthException('Auth Service : Impossible de joindre le serveur. Vérifiez votre réseau.');
    }
  }
}

