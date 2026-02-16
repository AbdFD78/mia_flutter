// lib/models/user.dart

import 'dart:convert';

class User {
  final int id;
  final String name;
  final String email;
  final String? telephone;
  final String? picture;
  final int? clientId;
  final String? clientName;
  final int? userTypeId;
  final String? userTypeName;
  final List<String> permissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.telephone,
    this.picture,
    this.clientId,
    this.clientName,
    this.userTypeId,
    this.userTypeName,
    this.permissions = const [],
  });

  // Créer un User depuis JSON (données de l'API)
  factory User.fromJson(Map<String, dynamic> json) {
    List<String> perms = const [];
    final rawPerms = json['permissions'];
    if (rawPerms is List) {
      perms = rawPerms.map((e) => e.toString()).toList();
    }

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      telephone: json['telephone'],
      picture: json['picture'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      userTypeId: json['user_type_id'],
      userTypeName: json['user_type_name'],
      permissions: perms,
    );
  }

  // Convertir un User en JSON (pour stocker en local)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'telephone': telephone,
      'picture': picture,
      'client_id': clientId,
      'client_name': clientName,
      'user_type_id': userTypeId,
      'user_type_name': userTypeName,
      'permissions': permissions,
    };
  }

  // Convertir un User en String JSON (pour SharedPreferences)
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Créer un User depuis String JSON (depuis SharedPreferences)
  factory User.fromJsonString(String jsonString) {
    return User.fromJson(jsonDecode(jsonString));
  }

  // Créer une copie avec des valeurs modifiées
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? telephone,
    String? picture,
    int? clientId,
    String? clientName,
    int? userTypeId,
    String? userTypeName,
    List<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      picture: picture ?? this.picture,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      userTypeId: userTypeId ?? this.userTypeId,
      userTypeName: userTypeName ?? this.userTypeName,
      permissions: permissions ?? this.permissions,
    );
  }
}
