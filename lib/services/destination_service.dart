import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/equipe.dart';
import '../models/user.dart';
import 'reclamation_service.dart';

class DestinationOptions {
  final List<User> users;
  final List<EquipeOption> equipes;

  const DestinationOptions({required this.users, required this.equipes});
}

class ApiDestinationService {
  static const _timeout = Duration(seconds: 10);

  Future<List<EquipeOption>> loadEquipes() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/equipes'))
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ReclamationException('Impossible de charger les équipes.');
      }
      final equipesJson = jsonDecode(response.body) as List<dynamic>;
      return equipesJson
          .map((item) => EquipeOption.fromJson(item as Map<String, dynamic>))
          .where((equipe) => equipe.actif!)
          .toList();
    } on ReclamationException {
      rethrow;
    } on TimeoutException {
      throw const ReclamationException('Le serveur ne répond pas.');
    } catch (_) {
      throw const ReclamationException('Impossible de charger les équipes.');
    }
  }

  Future<DestinationOptions> loadOptions() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/users')).timeout(_timeout),
        http.get(Uri.parse('${ApiConfig.baseUrl}/equipes')).timeout(_timeout),
      ]);

      for (final response in responses) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw const ReclamationException(
            'Impossible de charger les destinations.',
          );
        }
      }

      final usersJson = jsonDecode(responses[0].body) as List;
      final equipesJson = jsonDecode(responses[1].body) as List;


      final users = usersJson
          .map((item) => User.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      final equipes = equipesJson
          .map((item) => EquipeOption.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((equipe) => equipe.actif == true)
          .toList();


      return DestinationOptions(
        users: users,
        equipes: equipes,
      );
    } on ReclamationException {
      rethrow;
    } on TimeoutException {
      throw const ReclamationException('Le serveur ne répond pas.');
    } catch (e, s) {
      print('loadOptions ERROR => $e');
      print('STACK => $s');

      throw const ReclamationException(
        'Impossible de charger les membres et les équipes.',
      );
    }
  }
}
