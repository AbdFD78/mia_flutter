// lib/models/campaign.dart

class Campaign {
  final int id;
  final String nom;
  final String? picture;
  final int clientId;
  final String clientName;
  final int? configsId;
  final String configName;
  final String? configPicture;
  final bool canEdit; // Nouveau champ pour les permissions

  Campaign({
    required this.id,
    required this.nom,
    this.picture,
    required this.clientId,
    required this.clientName,
    this.configsId,
    required this.configName,
    this.configPicture,
    this.canEdit = false, // Par défaut, pas de permission d'édition
  });

  /// Créer un objet Campaign depuis JSON
  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      picture: json['picture'],
      clientId: json['client_id'] ?? 0,
      clientName: json['client_name'] ?? 'Client non défini',
      configsId: json['configs_id'],
      configName: json['config_name'] ?? 'Configuration non définie',
      configPicture: json['config_picture'],
      canEdit: json['can_edit'] ?? false, // Lire la permission depuis l'API
    );
  }

  /// Convertir un objet Campaign en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'picture': picture,
      'client_id': clientId,
      'client_name': clientName,
      'configs_id': configsId,
      'config_name': configName,
      'config_picture': configPicture,
      'can_edit': canEdit,
    };
  }
}
