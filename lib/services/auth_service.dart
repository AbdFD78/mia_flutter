// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class AuthService {
  // URL de base de l'API (configurée via AppConfig)
  static String get baseUrl => AppConfig.baseUrl;
  
  // Clés pour SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Connexion de l'utilisateur
  /// Retourne un Map avec 'success', 'message', 'user' et 'token'
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'remember': remember,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Extraction du token et de l'utilisateur
        final token = data['data']['token'];
        final userJson = data['data']['user'];
        final user = User.fromJson(userJson);

        // Stockage en local
        await saveToken(token);
        // DEBUG: afficher le token pour tests API externes
        // ATTENTION: à retirer en production
        // (visible dans la console après la connexion)
        // Exemple de recherche dans les logs: "DEBUG_TOKEN_MOBILE"
        // pour éviter de le perdre dans le bruit.
        // ignore: avoid_print
        print('DEBUG_TOKEN_MOBILE: $token');
        await saveUser(user);

        return {
          'success': true,
          'message': data['message'],
          'user': user,
          'token': token,
        };
      } else {
        // Gestion des erreurs
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur de connexion',
          'errors': data['errors'] ?? {},
          'password_reset_required': data['password_reset_required'] ?? false,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Déconnexion de l'utilisateur
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      
      if (token != null) {
        // Appel API de déconnexion
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Suppression des données locales
      await clearAuthData();

      return {
        'success': true,
        'message': 'Déconnexion réussie',
      };
    } catch (e) {
      // Même en cas d'erreur, on supprime les données locales
      await clearAuthData();
      
      return {
        'success': false,
        'message': 'Erreur lors de la déconnexion',
        'error': e.toString(),
      };
    }
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Récupérer l'utilisateur connecté depuis le stockage local
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        return User.fromJsonString(userJson);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Sauvegarder le token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Récupérer le token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Sauvegarder l'utilisateur
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toJsonString());
  }

  /// Supprimer toutes les données d'authentification
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Vérifier la validité du token auprès du serveur
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Erreur lors de la validation du token: $e');
      return false;
    }
  }
}
