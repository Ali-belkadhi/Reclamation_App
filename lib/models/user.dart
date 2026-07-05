class User {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String? telephone;
  final String? cin;
  final String? agence;
  final String? departementId;
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
    this.departementId,
    this.image,
  });

  // Full name helper
  String get name => '$nom $prenom';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['Id_User'] as String? ?? json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      telephone: json['telephone'] as String?,
      cin: json['cin'] as String?,
      agence: json['agence'] as String?,
      departementId: json['departement_id'] as String?,
      image: json['image'] as String?,
    );
  }

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
      'departement_id': departementId,
      'image': image,
    };
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $name, role: $role)';
}

