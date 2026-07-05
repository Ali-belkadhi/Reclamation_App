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
  Future<ReclamationMessage> sendMessage(String reclamationId, {
    required String senderId,
    required String content,
    String messageType = 'TEXT',
  });

  Future<Reclamation> create({
    required String senderId,
    required String objet,
    required String type,
    required String description,
    required String destinationType,
    String? receiverId,
    int? destinationId,
    int? agenceId,
  });
}

class ApiReclamationService implements ReclamationService {
  static const _timeout = Duration(seconds: 10);
  static const _headers = {'Content-Type': 'application/json; charset=utf-8'};

  @override
  Future<List<Reclamation>> findReceivedByUser(String idUser) async {
    final response = await _send(
      () => http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/reclamations/receiver/${Uri.encodeComponent(idUser)}',
            ),
          )
          .timeout(_timeout),
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => Reclamation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Reclamation>> findAll() async {
    final response = await _send(
      () => http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/reclamations'),
          )
          .timeout(_timeout),
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => Reclamation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Reclamation>> findByUser(String idUser) async {
    final response = await _send(
      () => http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/reclamations/user/${Uri.encodeComponent(idUser)}',
            ),
          )
          .timeout(_timeout),
    );
    final items = jsonDecode(response.body) as List<dynamic>;
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
  Future<Reclamation> create({
    required String senderId,
    required String objet,
    required String type,
    required String description,
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
      'description': description,
      'destinationType': destinationType,
      'receiverIds': isUser && receiverId != null ? [receiverId] : <String>[],
      'destinationIds': !isUser && destinationId != null
          ? [destinationId]
          : <int>[],
      if (agenceId != null) 'agenceId': agenceId,
    };

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

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      String message = 'Une erreur est survenue.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = (body['message'] ?? body['error'] ?? message).toString();
      } catch (_) {}
      throw ReclamationException(message);
    } on ReclamationException {
      rethrow;
    } on TimeoutException {
      throw const ReclamationException('Le serveur ne répond pas.');
    } catch (_) {
      throw const ReclamationException(
        'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }
  }
}
