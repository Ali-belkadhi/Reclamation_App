class EquipeOption {
  final int id;
  final String code;
  final String nom;
  final bool actif;

  const EquipeOption({
    required this.id,
    required this.code,
    required this.nom,
    required this.actif,
  });

  factory EquipeOption.fromJson(Map<String, dynamic> json) {
    return EquipeOption(
      id: (json['idEquipe'] as num).toInt(),
      code: json['code'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      actif: json['actif'] as bool? ?? true,
    );
  }
}
