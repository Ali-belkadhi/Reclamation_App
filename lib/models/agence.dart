class Agence {
  final int idAgence;
  final String code;
  final String nom;
  final String? adresse;
  final String? ville;
  final String? telephone;
  final String? email;
  final String? directeur;
  final DateTime? dateCreation;

  const Agence({
    required this.idAgence,
    required this.code,
    required this.nom,
    this.adresse,
    this.ville,
    this.telephone,
    this.email,
    this.directeur,
    this.dateCreation,
  });

  factory Agence.fromJson(Map<String, dynamic> json) {
    return Agence(
      idAgence: (json['idAgence'] as num).toInt(),
      code: json['code'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      directeur: json['directeur'] as String?,
      dateCreation: DateTime.tryParse(json['dateCreation'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'code': code,
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'telephone': telephone,
      'email': email,
      'directeur': directeur,
    };
  }
}
