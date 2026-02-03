// lib/models/campaign_detail.dart

class CampaignDetail {
  final int id;
  final String nom;
  final String? picture;
  final int clientId;
  final String clientName;
  final int? configsId;
  final String configName;
  final List<CampaignTab> tabs;

  CampaignDetail({
    required this.id,
    required this.nom,
    this.picture,
    required this.clientId,
    required this.clientName,
    this.configsId,
    required this.configName,
    required this.tabs,
  });

  factory CampaignDetail.fromJson(Map<String, dynamic> json) {
    return CampaignDetail(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      picture: json['picture'],
      clientId: json['client_id'] ?? 0,
      clientName: json['client_name'] ?? 'Client non défini',
      configsId: json['configs_id'],
      configName: json['config_name'] ?? 'Configuration non définie',
      tabs: (json['tabs'] as List<dynamic>?)
              ?.map((tab) => CampaignTab.fromJson(tab))
              .toList() ??
          [],
    );
  }
}

class CampaignTab {
  final int id;
  final String nom;
  final String tag;
  final int order;
  final bool valid;
  final List<CampaignField> fields;

  CampaignTab({
    required this.id,
    required this.nom,
    required this.tag,
    required this.order,
    required this.valid,
    required this.fields,
  });

  factory CampaignTab.fromJson(Map<String, dynamic> json) {
    return CampaignTab(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      tag: json['tag'] ?? '',
      order: json['order'] ?? 0,
      valid: _parseBool(json['valid']),
      fields: (json['fields'] as List<dynamic>?)
              ?.map((field) => CampaignField.fromJson(field))
              .toList() ??
          [],
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return true;
  }
}

class CampaignField {
  final int id;
  final String tag;
  final String type;
  final String label;
  final dynamic value;
  final bool required;
  final int colSize;
  final Map<String, dynamic> options;
  final int order;
  final bool display;

  CampaignField({
    required this.id,
    required this.tag,
    required this.type,
    required this.label,
    this.value,
    required this.required,
    required this.colSize,
    required this.options,
    required this.order,
    this.display = true,
  });

  factory CampaignField.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'text').toString();
    final Map<String, dynamic> opts = json['options'] is Map<String, dynamic>
        ? json['options'] as Map<String, dynamic>
        : {};

    // Certains formulaires "NewDocGenerator" ont un type différent
    // ("document", "newgenerator", etc.). On les détecte par la présence
    // d'un template + data.Tableau_Produit dans les options, quel que soit
    // le type d'origine, et on les traite comme "newdocgenerator".
    String effectiveType = rawType.toLowerCase();
    final String tag = (json['tag'] ?? '').toString().toLowerCase();
    final bool looksLikeNewDocGenerator =
        (opts.containsKey('template') &&
            (opts['data'] is Map<String, dynamic>) &&
            (opts['data'] as Map<String, dynamic>).containsKey('Tableau_Produit')) ||
        tag.startsWith('newgenerator');
    if (looksLikeNewDocGenerator) {
      effectiveType = 'newdocgenerator';
    }

    return CampaignField(
      id: json['id'] ?? 0,
      tag: json['tag'] ?? '',
      type: effectiveType,
      label: json['label'] ?? 'Sans titre',
      value: json['value'],
      required: _parseBool(json['required']),
      colSize: json['col_size'] ?? 12,
      options: opts,
      order: json['order'] ?? 0,
      // Si la clé display n'est pas présente, on considère que le champ est visible
      display: json.containsKey('display')
          ? _parseBool(json['display'])
          : true,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
