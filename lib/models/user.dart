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
  });

  // Créer un User depuis JSON (données de l'API)
  factory User.fromJson(Map<String, dynamic> json) {
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
}
