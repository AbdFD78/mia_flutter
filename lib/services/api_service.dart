// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ApiService {
  // URL de base de ton API Laravel
  // IMPORTANT : Depuis l'émulateur Android, "localhost" ne fonctionne pas
  // On utilise 10.0.2.2 qui est l'IP spéciale de l'émulateur vers le PC hôte
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  final AuthService _authService = AuthService();

  /// Récupérer les headers avec authentification
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Gérer les erreurs d'authentification
  void _handleAuthError(http.Response response) {
    if (response.statusCode == 401) {
      // Token invalide ou expiré, déclencher la déconnexion
      _authService.clearAuthData();
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }
  }
  
  /// Récupérer tous les clients avec filtres optionnels
  Future<Map<String, dynamic>> getClients({
    int? clientTypeId,
    int? statusId,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Construire l'URL avec paramètres
      var url = '$baseUrl/clients';
      final queryParams = <String, String>{};
      
      if (clientTypeId != null) {
        queryParams['client_type_id'] = clientTypeId.toString();
      }
      if (statusId != null) {
        queryParams['status_id'] = statusId.toString();
      }
      
      final uri = Uri.parse(url).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      // Faire la requête GET vers l'API
      final response = await http.get(
        uri,
        headers: headers,
      );

      // Vérifier l'authentification
      _handleAuthError(response);

      // Vérifier le code de statut HTTP
      if (response.statusCode == 200) {
        // Décoder le JSON
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        // Extraire le tableau de clients
        final List<dynamic> clientsJson = jsonData['data'];
        
        // Convertir chaque JSON en objet Client
        final clients = clientsJson.map((json) => Client.fromJson(json)).toList();
        
        // Retourner les clients avec les listes de filtres
        return {
          'clients': clients,
          'client_types': jsonData['client_types'] ?? [],
          'statuses': jsonData['statuses'] ?? [],
        };
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors du chargement des clients: $e');
      rethrow; // Relancer l'erreur pour la gérer dans l'UI
    }
  }
  
  /// Récupérer un client par ID
  Future<Client> getClient(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/clients/$id'),
        headers: headers,
      );

      // Vérifier l'authentification
      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Client.fromJson(jsonData['data']);
      } else {
        throw Exception('Client non trouvé');
      }
    } catch (e) {
      print('Erreur lors du chargement du client: $e');
      rethrow;
    }
  }

  /// Récupérer tous les utilisateurs
  Future<List<User>> getUsers() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );

      print('DEBUG Users - Status: ${response.statusCode}');
      print('DEBUG Users - Body: ${response.body}');

      // Vérifier l'authentification
      _handleAuthError(response);

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        print('DEBUG Users - Decoded type: ${decodedData.runtimeType}');
        
        if (decodedData is Map<String, dynamic>) {
          final List<dynamic> usersJson = decodedData['data'];
          return usersJson.map((json) => User.fromJson(json)).toList();
        } else if (decodedData is List) {
          // Si l'API retourne directement une liste
          return decodedData.map((json) => User.fromJson(json)).toList();
        } else {
          throw Exception('Format de réponse inattendu');
        }
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors du chargement des utilisateurs: $e');
      rethrow;
    }
  }

  /// Récupérer un utilisateur par ID
  Future<User> getUser(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
      );

      // Vérifier l'authentification
      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return User.fromJson(jsonData['data']);
      } else {
        throw Exception('Utilisateur non trouvé');
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'utilisateur: $e');
      rethrow;
    }
  }
}