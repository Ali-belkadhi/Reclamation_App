// Représente le modèle de données d'un Utilisateur au sein de l'application
class User {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String? telephone;
  final String? cin;
  final String? agence;
  final int? idEquipe;
  final String? image;

  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.telephone,
    this.cin,
    this.agence,
    this.idEquipe,
    this.image,
  });

  // Getter de commodité pour obtenir le nom complet formate
  String get name => '$nom $prenom';

  // Constructeur d'usine (factory) pour instancier un Utilisateur à partir d'un format de données JSON (Map)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Gère les variations potentielles de clés d'API (Id_User ou id)
      id: json['Id_User'] as String? ?? json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      telephone: json['telephone'] as String?,
      cin: json['cin'] as String?,
      agence: json['agence'] as String?,
      // Utilise un parseur robuste pour l'identifiant de l'équipe (peut être int, double ou string)
      idEquipe: _parseIdEquipe(
        json['idEquipe'] ?? json['equipeId'] ?? json['id_equipe'],
      ),
      image: json['image'] as String?,
    );
  }

  // Convertit l'objet User actuel en un format Map compatible JSON pour les envois API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'telephone': telephone,
      'cin': cin,
      'agence': agence,
      'idEquipe': idEquipe,
      'image': image,
    };
  }

  // Analyseur numérique pour l'identifiant de l'équipe afin d'éviter tout plantage de type à l'exécution
  static int? _parseIdEquipe(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $name, role: $role)';
}

