// lib/models/client.dart

class Client {
  final int id;
  final String raisonSociale;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? ville;
  final String? codepostal;
  final String? picture;
  
  final ClientType clientType;
  final Status status;
  
  final int campagnesCount;
  final int contactsCount;
  final int suivisCount;
  
  final String? lastActivity;
  final String? lastAuthor;
  final String? lastSuiviIntitule;
  final String? lastSuiviText;
  final List<Suivi>? suivis;
  final List<ClientEvent>? events;

  Client({
    required this.id,
    required this.raisonSociale,
    this.email,
    this.telephone,
    this.adresse,
    this.ville,
    this.codepostal,
    this.picture,
    required this.clientType,
    required this.status,
    required this.campagnesCount,
    required this.contactsCount,
    required this.suivisCount,
    this.lastActivity,
    this.lastAuthor,
    this.lastSuiviIntitule,
    this.lastSuiviText,
    this.suivis,
    this.events,
  });

  // Créer un Client depuis JSON (données de l'API)
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      raisonSociale: json['raison_sociale'],
      email: json['email'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      ville: json['ville'],
      codepostal: json['codepostal'],
      picture: json['picture'],
      clientType: ClientType.fromJson(json['client_type']),
      status: Status.fromJson(json['status']),
      campagnesCount: json['campagnes_count'] ?? 0,
      contactsCount: json['contacts_count'] ?? 0,
      suivisCount: json['suivis_count'] ?? 0,
      lastActivity: json['last_activity'],
      lastAuthor: json['last_author'],
      lastSuiviIntitule: json['last_suivi_intitule'],
      lastSuiviText: json['last_suivi_text'],
      suivis: json['suivis'] != null 
          ? (json['suivis'] as List).map((s) => Suivi.fromJson(s)).toList()
          : null,
      events: json['events'] != null 
          ? (json['events'] as List).map((e) => ClientEvent.fromJson(e)).toList()
          : null,
    );
  }
}

// Modèle pour Suivi
class Suivi {
  final int id;
  final String metaKey;
  final String metaValue;
  final String createdAt;
  final String? author;

  Suivi({
    required this.id,
    required this.metaKey,
    required this.metaValue,
    required this.createdAt,
    this.author,
  });

  factory Suivi.fromJson(Map<String, dynamic> json) {
    return Suivi(
      id: json['id'],
      metaKey: json['meta_key'] ?? '',
      metaValue: json['meta_value'] ?? '',
      createdAt: json['created_at'],
      author: json['author'],
    );
  }
}

// Modèle pour Événement Client
class ClientEvent {
  final int id;
  final String name;
  final String? description;
  final String? createdAt;
  final String? deadline;
  final String? author;

  ClientEvent({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.deadline,
    this.author,
  });

  factory ClientEvent.fromJson(Map<String, dynamic> json) {
    return ClientEvent(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      createdAt: json['created_at'],
      deadline: json['deadline'],
      author: json['author'],
    );
  }
}

// Modèle pour ClientType
class ClientType {
  final int id;
  final String name;

  ClientType({
    required this.id,
    required this.name,
  });

  factory ClientType.fromJson(Map<String, dynamic> json) {
    return ClientType(
      id: json['id'],
      name: json['name'],
    );
  }
}

// Modèle pour Status
class Status {
  final int id;
  final String name;
  final String color;

  Status({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'],
      name: json['name'],
      color: json['color'],
    );
  }
}