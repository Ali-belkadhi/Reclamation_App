import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/reclamation.dart';
import '../models/message_model.dart';

class ReclamationException implements Exception {
  final String message;

  const ReclamationException(this.message);

  @override
  String toString() => message;
}

abstract class ReclamationService {
  Future<List<Reclamation>> findReceivedByUser(String idUser);
  Future<List<Reclamation>> findByUser(String idUser);
  Future<List<Reclamation>> findAll();

  Future<List<ReclamationMessage>> findMessages(String reclamationId);
  Future<Set<String>> findParticipantUserIds(String reclamationId);
  Future<ReclamationMessage> sendMessage(String reclamationId, {
    required String senderId,
    required String content,
    String messageType = 'TEXT',
  });

  Future<void> inviteParticipants(
    String reclamationId, {
    required String inviterId,
    required String targetType,
    String? userId,
    int? equipeId,
  });

  Future<Reclamation> create({
    required String senderId,
    required String objet,
    required String type,
    required String description,
    String priorite = 'NORMALE',
    required String destinationType,
    String? receiverId,
    int? destinationId,
    int? agenceId,
  });
}

class ApiReclamationService implements ReclamationService {
  // Durée maximale d'attente pour une réponse du serveur (10 secondes)
  static const _timeout = Duration(seconds: 10);
  
  // En-têtes HTTP par défaut envoyés avec les requêtes
  static const _headers = {'Content-Type': 'application/json; charset=utf-8'};

  @override
  Future<List<Reclamation>> findReceivedByUser(String idUser) async {
    // 1. Envoi de la requête GET au serveur pour récupérer les réclamations reçues par l'utilisateur
    final response = await _send(
      () => http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/reclamations/receiver/${Uri.encodeComponent(idUser)}',
            ),
          )
          .timeout(_timeout),
    );
    
    // 2. Décodage de la réponse JSON brute en une liste d'éléments dynamiques
    final items = jsonDecode(response.body) as List<dynamic>;
    
    // 3. Transformation de la liste JSON en une liste d'objets typés Reclamation et retour du résultat
    return items
        .map((item) => Reclamation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Reclamation>> findAll() async {
    // 1. Envoi de la requête GET pour récupérer toutes les réclamations de la base
    final response = await _send(
      () => http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/reclamations'),
          )
          .timeout(_timeout),
    );
    
    // 2. Décodage de la réponse JSON brute
    final items = jsonDecode(response.body) as List<dynamic>;
    
    // 3. Transformation et conversion vers le modèle Reclamation
    return items
        .map((item) => Reclamation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Reclamation>> findByUser(String idUser) async {
    // 1. Envoi de la requête GET pour récupérer les réclamations créées OU reçues par l'utilisateur
    final response = await _send(
      () => http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/reclamations/user/${Uri.encodeComponent(idUser)}',
            ),
          )
          .timeout(_timeout),
    );
    
    // 2. Décodage de la réponse JSON brute
    final items = jsonDecode(response.body) as List<dynamic>;
    
    // 3. Transformation et conversion vers le modèle Reclamation
    return items
        .map((item) => Reclamation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReclamationMessage>> findMessages(String reclamationId) async {
    final response = await _send(
      () => http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/reclamations/${Uri.encodeComponent(reclamationId)}/messages',
            ),
          )
          .timeout(_timeout),
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => ReclamationMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Set<String>> findParticipantUserIds(String reclamationId) async {
    final response = await _send(
      () => http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/reclamations/${Uri.encodeComponent(reclamationId)}/participants',
            ),
          )
          .timeout(_timeout),
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((participant) => participant['user'])
        .whereType<Map>()
        .map((user) => user['Id_User'] ?? user['idUser'] ?? user['id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  @override
  Future<ReclamationMessage> sendMessage(String reclamationId, {
    required String senderId,
    required String content,
    String messageType = 'TEXT',
  }) async {
    final response = await _send(
      () => http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/reclamations/${Uri.encodeComponent(reclamationId)}/messages',
            ),
            headers: _headers,
            body: jsonEncode({
              'senderId': senderId,
              'content': content,
              'messageType': messageType,
            }),
          )
          .timeout(_timeout),
    );
    return ReclamationMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> inviteParticipants(
    String reclamationId, {
    required String inviterId,
    required String targetType,
    String? userId,
    int? equipeId,
  }) async {
    await _send(
      () => http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/reclamations/${Uri.encodeComponent(reclamationId)}/participants/invite',
            ),
            headers: _headers,
            body: jsonEncode({
              'inviterId': inviterId,
              'targetType': targetType,
              if (userId != null) 'userId': userId,
              if (equipeId != null) 'equipeId': equipeId,
            }),
          )
          .timeout(_timeout),
    );
  }

  @override
  Future<Reclamation> create({
    required String senderId,
    required String objet,
    required String type,
    required String description,
    String priorite = 'NORMALE',
    required String destinationType,
    String? receiverId,
    int? destinationId,
    int? agenceId,
  }) async {
    final isUser = destinationType == 'USER';
    final body = <String, dynamic>{
      'senderId': senderId,
      'objet': objet,
      'type': type,
      'statut': 'NOUVELLE',
      'priorite': priorite,
      'description': description,
      'destinationType': destinationType,
      'receiverIds': isUser && receiverId != null ? [receiverId] : <String>[],
      'destinationIds': !isUser && destinationId != null
          ? [destinationId]
          : <int>[],
      if (agenceId != null) 'agenceId': agenceId,
    };
    print('bodyyyy     '+body.toString());
    final response = await _send(
      () => http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/reclamations'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout),
    );
    return Reclamation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // Méthode utilitaire générique de gestion d'envois HTTP avec gestion des exceptions et erreurs
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      // 1. Exécute la requête passée en paramètre
      final response = await request();
      
      // 2. Si le code HTTP indique un succès (2xx), retourne directement la réponse
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      // 3. Sinon (erreurs 4xx ou 5xx), extrait le message d'erreur renvoyé par le backend
      String message = 'Une erreur est survenue.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = (body['message'] ?? body['error'] ?? message).toString();
      } catch (_) {}
      throw ReclamationException(message);
    } on ReclamationException {
      // Relance l'exception personnalisée ReclamationException
      rethrow;
    } on TimeoutException {
      // En cas de dépassement du délai de connexion (10s)
      throw const ReclamationException('Le serveur ne répond pas.');
    } catch (_) {
      // En cas de panne réseau (ex. serveur éteint ou adresse inaccessible)
      throw const ReclamationException(
        'Reclamation Service : Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }
  }
}
