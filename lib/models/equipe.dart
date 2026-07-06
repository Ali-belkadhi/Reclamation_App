import 'package:reclamation_attijari/models/user.dart';

class EquipeOption {
  final int? id;
  final String code;
  final String nom;
  final String description;
  final bool actif;
  final List<User>? members;

  EquipeOption({
    this.id,
    required this.code,
    required this.nom,
    required this.description,
    required this.actif,
    this.members,
  });

  factory EquipeOption.fromJson(Map<String, dynamic> json) {
    return EquipeOption(
      id: json['idEquipe'] is int
          ? json['idEquipe']
          : int.tryParse(json['idEquipe'].toString()),
      code: json['code']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      actif: json['actif'] == true,
      members: json['members'] == null
          ? null
          : (json['members'] as List)
          .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}