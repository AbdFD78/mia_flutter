// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/client.dart';
import '../models/user.dart';
import '../models/campaign.dart';
import '../models/campaign_detail.dart';
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

      // Vérifier l'authentification
      _handleAuthError(response);

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        
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

  /// Récupérer toutes les campagnes avec recherche et filtre par client
  Future<Map<String, dynamic>> getCampaigns({
    String? search,
    int? clientId,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Construire l'URL avec paramètres de recherche et filtre
      var url = '$baseUrl/campagnes';
      final queryParams = <String, String>{};
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (clientId != null) {
        queryParams['client_id'] = clientId.toString();
      }
      
      final uri = Uri.parse(url).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      // Vérifier l'authentification
      _handleAuthError(response);

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        
        if (decodedData is Map<String, dynamic>) {
          // Nouveau format avec campaigns et clients
          final List<dynamic> campaignsJson = decodedData['campaigns'] ?? decodedData['data'] ?? [];
          final campaigns = campaignsJson.map((json) => Campaign.fromJson(json)).toList();
          
          return {
            'campaigns': campaigns,
            'clients': decodedData['clients'] ?? [],
          };
        } else if (decodedData is List) {
          // Ancien format - liste directe
          return {
            'campaigns': decodedData.map((json) => Campaign.fromJson(json)).toList(),
            'clients': [],
          };
        } else {
          throw Exception('Format de réponse inattendu');
        }
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors du chargement des campagnes: $e');
      rethrow;
    }
  }

  /// Récupérer une campagne par ID (simple)
  Future<Campaign> getCampaign(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/campagnes/$id'),
        headers: headers,
      );

      // Vérifier l'authentification
      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Campaign.fromJson(jsonData['data']);
      } else {
        throw Exception('Campagne non trouvée');
      }
    } catch (e) {
      print('Erreur lors du chargement de la campagne: $e');
      rethrow;
    }
  }
  
  /// Récupérer les détails complets d'une campagne (avec onglets et champs)
  Future<CampaignDetail> getCampaignDetail(int id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/campagnes/$id'),
        headers: headers,
      );

      // Vérifier l'authentification
      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return CampaignDetail.fromJson(jsonData);
      } else {
        throw Exception('Campagne non trouvée');
      }
    } catch (e) {
      print('Erreur lors du chargement des détails de la campagne: $e');
      rethrow;
    }
  }

  /// Récupérer les données pour créer une campagne
  Future<Map<String, dynamic>> getCampaignCreateData() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/campagnes/create-data'),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['data'];
      } else {
        throw Exception('Erreur lors du chargement des données');
      }
    } catch (e) {
      print('Erreur: $e');
      rethrow;
    }
  }

  /// Récupérer les contacts d'un client
  Future<Map<String, dynamic>> getClientContacts(int clientId, {int? campagneId}) async {
    try {
      final headers = await _getHeaders();
      
      // Ajouter le paramètre campagne_id si fourni (pour l'édition)
      var uri = Uri.parse('$baseUrl/campagnes/client/$clientId/contacts');
      if (campagneId != null) {
        uri = Uri.parse('$baseUrl/campagnes/client/$clientId/contacts?campagne_id=$campagneId');
      }
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['data'];
      } else {
        throw Exception('Erreur lors du chargement des contacts');
      }
    } catch (e) {
      print('Erreur: $e');
      rethrow;
    }
  }

  /// Créer une campagne
  Future<Map<String, dynamic>> createCampaign({
    required String nom,
    required int clientId,
    required int configId,
    List<int>? miaIntervenants,
    List<int>? clientIntervenants,
    File? imageFile,
  }) async {
    try {
      final token = await _authService.getToken();
      
      // Toujours utiliser multipart pour être cohérent avec update
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/campagnes'),
      );

      // Ajouter le token
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Ajouter les champs
      request.fields['nom'] = nom;
      request.fields['client_id'] = clientId.toString();
      request.fields['configs_id'] = configId.toString();
      
      // Log pour debug
      print('🔍 Création campagne - Intervenants MIA: $miaIntervenants');
      print('🔍 Création campagne - Intervenants Client: $clientIntervenants');
      
      if (miaIntervenants != null && miaIntervenants.isNotEmpty) {
        for (int i = 0; i < miaIntervenants.length; i++) {
          request.fields['mia_intervenants[$i]'] = miaIntervenants[i].toString();
          print('➕ Ajout intervenant MIA [$i]: ${miaIntervenants[i]}');
        }
      }
      
      if (clientIntervenants != null && clientIntervenants.isNotEmpty) {
        for (int i = 0; i < clientIntervenants.length; i++) {
          request.fields['client_intervenants[$i]'] = clientIntervenants[i].toString();
          print('➕ Ajout intervenant Client [$i]: ${clientIntervenants[i]}');
        }
      }

      // Ajouter l'image si elle existe
      if (imageFile != null) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        var multipartFile = http.MultipartFile(
          'picture',
          stream,
          length,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      _handleAuthError(response);

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['data'];
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Erreur de validation');
      } else {
        throw Exception('Erreur lors de la création de la campagne');
      }
    } catch (e) {
      print('Erreur: $e');
      rethrow;
    }
  }

  /// Mettre à jour une campagne
  Future<Map<String, dynamic>> updateCampaign({
    required int id,
    required String nom,
    required int clientId,
    required int configId,
    List<int>? miaIntervenants,
    List<int>? clientIntervenants,
    File? imageFile,
  }) async {
    try {
      final token = await _authService.getToken();
      
      // Utiliser multipart pour l'upload d'image (même structure que create)
      var request = http.MultipartRequest(
        'POST', // POST car Laravel ne supporte pas PUT avec multipart facilement
        Uri.parse('$baseUrl/campagnes/$id'),
      );

      // Ajouter le token
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Ajouter les champs
      request.fields['nom'] = nom;
      request.fields['client_id'] = clientId.toString();
      request.fields['configs_id'] = configId.toString();
      
      // Log pour debug
      print('🔍 Mise à jour campagne - Intervenants MIA: $miaIntervenants');
      print('🔍 Mise à jour campagne - Intervenants Client: $clientIntervenants');
      
      if (miaIntervenants != null && miaIntervenants.isNotEmpty) {
        for (int i = 0; i < miaIntervenants.length; i++) {
          request.fields['mia_intervenants[$i]'] = miaIntervenants[i].toString();
          print('➕ Ajout intervenant MIA [$i]: ${miaIntervenants[i]}');
        }
      }
      
      if (clientIntervenants != null && clientIntervenants.isNotEmpty) {
        for (int i = 0; i < clientIntervenants.length; i++) {
          request.fields['client_intervenants[$i]'] = clientIntervenants[i].toString();
          print('➕ Ajout intervenant Client [$i]: ${clientIntervenants[i]}');
        }
      }

      // Ajouter l'image si elle existe
      if (imageFile != null) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        var multipartFile = http.MultipartFile(
          'picture',
          stream,
          length,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['data'];
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Erreur de validation');
      } else if (response.statusCode == 404) {
        throw Exception('Campagne non trouvée');
      } else {
        throw Exception('Erreur lors de la modification de la campagne');
      }
    } catch (e) {
      print('Erreur: $e');
      rethrow;
    }
  }
}