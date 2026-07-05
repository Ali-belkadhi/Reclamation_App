class ReclamationSender {
  final String idUser;
  final String nom;
  final String prenom;

  const ReclamationSender({
    required this.idUser,
    required this.nom,
    required this.prenom,
  });

  String get fullName => '$prenom $nom'.trim();

  factory ReclamationSender.fromJson(Map<String, dynamic> json) {
    return ReclamationSender(
      idUser: json['Id_User'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
    );
  }
}

class Reclamation {
  final String id;
  final String objet;
  final String type;
  final String statut;
  final String description;
  final String destinationType;
  final ReclamationSender? sender;
  final DateTime? createdAt;

  const Reclamation({
    required this.id,
    required this.objet,
    required this.type,
    required this.statut,
    required this.description,
    required this.destinationType,
    this.sender,
    this.createdAt,
  });

  factory Reclamation.fromJson(Map<String, dynamic> json) {
    final senderJson = json['sender'];
    return Reclamation(
      id: json['_id'] as String? ?? '',
      objet: json['objet'] as String? ?? '',
      type: json['type'] as String? ?? '',
      statut: json['statut'] as String? ?? 'NOUVELLE',
      description: json['description'] as String? ?? '',
      destinationType: json['destinationType'] as String? ?? '',
      sender: senderJson is Map<String, dynamic>
          ? ReclamationSender.fromJson(senderJson)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
