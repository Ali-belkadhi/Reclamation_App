import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/agence.dart';

class AgenceException implements Exception {
  final String message;

  const AgenceException(this.message);

  @override
  String toString() => message;
}

abstract class AgenceService {
  Future<List<Agence>> findAll();
  Future<Agence> create(Agence agence);
  Future<Agence> update(Agence agence);
  Future<void> delete(int idAgence);
}

class ApiAgenceService implements AgenceService {
  static const _timeout = Duration(seconds: 10);
  static const _headers = {'Content-Type': 'application/json'};

  @override
  Future<List<Agence>> findAll() async {
    final response = await _send(
      () => http.get(Uri.parse('${ApiConfig.baseUrl}/agences')).timeout(_timeout),
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => Agence.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Agence> create(Agence agence) async {
    final response = await _send(
      () => http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/agences'),
            headers: _headers,
            body: jsonEncode(agence.toRequestJson()),
          )
          .timeout(_timeout),
    );
    return Agence.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Agence> update(Agence agence) async {
    final response = await _send(
      () => http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/agences/${agence.idAgence}'),
            headers: _headers,
            body: jsonEncode(agence.toRequestJson()),
          )
          .timeout(_timeout),
    );
    return Agence.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int idAgence) async {
    await _send(
      () => http
          .delete(Uri.parse('${ApiConfig.baseUrl}/agences/$idAgence'))
          .timeout(_timeout),
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
      throw AgenceException(message);
    } on AgenceException {
      rethrow;
    } on TimeoutException {
      throw const AgenceException('Le serveur ne répond pas. Réessayez plus tard.');
    } catch (_) {
      throw const AgenceException('Agence Service : Impossible de joindre le serveur. Vérifiez votre connexion.');
    }
  }
}
