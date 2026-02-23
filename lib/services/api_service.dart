// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/client.dart';
import '../models/user.dart';
import '../models/campaign.dart';
import '../models/campaign_detail.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  // URL de base de l'API (configurée via AppConfig)
  // PRODUCTION: https://crm.model-intelligence-agency.com/api
  // DÉVELOPPEMENT: http://10.0.2.2:8000/api (émulateur Android)
  static String get baseUrl => AppConfig.baseUrl;
  
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
    int perPage = 100,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Construire l'URL avec paramètres
      var url = '$baseUrl/clients';
      final queryParams = <String, String>{
        'per_page': perPage.toString(),
      };
      
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
    int page = 1,
    int perPage = 8,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Construire l'URL avec paramètres de recherche et filtre
      var url = '$baseUrl/campagnes';
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      
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
          final List<dynamic> campaignsJson =
              decodedData['campaigns'] ?? decodedData['data'] ?? [];
          final campaigns =
              campaignsJson.map((json) => Campaign.fromJson(json)).toList();

          return {
            'campaigns': campaigns,
            'clients': decodedData['clients'] ?? [],
            'page': decodedData['page'] ?? 1,
            'per_page': decodedData['per_page'] ?? campaigns.length,
            'total': decodedData['total'] ?? campaigns.length,
            'has_more': decodedData['has_more'] ?? false,
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

  /// Test d'authentification pour events
  Future<Map<String, dynamic>> testEventsAuth() async {
    try {
      final headers = await _getHeaders();
      
      print('🧪 Test Events Auth - Headers: $headers');
      
      var uri = Uri.parse('$baseUrl/events/test');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      print('🧪 Test Events Auth - Status: ${response.statusCode}');
      print('🧪 Test Events Auth - Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur Test: $e');
      rethrow;
    }
  }

  /// Récupérer la liste des événements
  Future<List<Map<String, dynamic>>> getEvents({String tab = 'events', String search = ''}) async {
    try {
      final headers = await _getHeaders();
      
      print('📡 getEvents - Headers: $headers');
      print('📡 getEvents - URL: $baseUrl/events?tab=$tab&search=$search');
      
      var uri = Uri.parse('$baseUrl/events?tab=$tab&search=$search');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      print('📡 getEvents - Status: ${response.statusCode}');
      print('📡 getEvents - Body: ${response.body}');

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(jsonData['data'] ?? []);
      } else {
        throw Exception('Erreur lors du chargement des événements');
      }
    } catch (e) {
      print('Erreur: $e');
      rethrow;
    }
  }

  /// Archiver un événement
  Future<void> archiveEvent(int eventId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode != 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Erreur lors de l\'archivage');
      }
    } catch (e) {
      print('Erreur: $e');
      rethrow;
    }
  }

  /// Récupérer les activités (suivis clients et événements) avec filtres
  Future<List<Map<String, dynamic>>> getActivities({
    String type = 'all', // 'all', 'suivie', 'event'
    String? authorId,
    String? clientId,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      
      var url = '$baseUrl/activities?type=$type';
      if (authorId != null && authorId.isNotEmpty) {
        url += '&author_id=$authorId';
      }
      if (clientId != null && clientId.isNotEmpty) {
        url += '&client_id=$clientId';
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        url += '&date_from=$dateFrom';
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        url += '&date_to=$dateTo';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des activités: $e');
      rethrow;
    }
  }

  /// Récupérer la liste des auteurs (utilisateurs) pour les filtres d'activités
  Future<List<Map<String, dynamic>>> getActivityAuthors() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/activities/authors'),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des auteurs: $e');
      rethrow;
    }
  }

  /// Récupérer la liste des clients pour les filtres d'activités
  Future<List<Map<String, dynamic>>> getActivityClients() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/activities/clients'),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des clients: $e');
      rethrow;
    }
  }

  /// Récupérer les informations du profil utilisateur
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return jsonData['data'];
        }
        throw Exception('Données de profil invalides');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      rethrow;
    }
  }

  /// Mettre à jour le profil utilisateur (nom et/ou email)
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {};
      if (name != null && name.isNotEmpty) {
        body['name'] = name;
      }
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: jsonEncode(body),
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData['data'] ?? {};
        }
        throw Exception(jsonData['message'] ?? 'Erreur lors de la mise à jour');
      } else {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  /// Changer le mot de passe
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/profile/password'),
        headers: headers,
        body: jsonEncode({
          'old_password': oldPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] != true) {
          throw Exception(jsonData['message'] ?? 'Erreur lors du changement de mot de passe');
        }
      } else {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors du changement de mot de passe: $e');
      rethrow;
    }
  }

  /// Récupérer les membres de l'équipe (même client_id)
  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile/team'),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'équipe: $e');
      rethrow;
    }
  }

  /// Récupérer les devices de l'utilisateur pour les notifications push
  Future<List<Map<String, dynamic>>> getPushDevices() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/push/devices'),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['devices'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['devices']);
        }
        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des devices: $e');
      rethrow;
    }
  }

  /// Désactiver les notifications push pour un device
  Future<bool> disablePushDevice({
    String? deviceFingerprint,
    String? fcmToken,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/push/disable-device'),
        headers: headers,
        body: jsonEncode({
          if (deviceFingerprint != null) 'device_fingerprint': deviceFingerprint,
          if (fcmToken != null) 'fcm_token': fcmToken,
        }),
      );

      _handleAuthError(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la désactivation du device: $e');
      rethrow;
    }
  }

  // ============================================================
  // NEWDOCGENERATOR - Génération devis / facture & lignes produits
  // ============================================================

  /// Génère un devis en mode "prévisualisation" (brouillon) pour un champ newdocgenerator.
  /// Utilise l'endpoint /devis/preview (nouveau flux aligné avec le web).
  Future<void> generateNewDocDevisPreview({
    required int campagneId,
    required String tabTag,
    required String formTag,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
        '$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/devis/preview');

    final response = await http.post(uri, headers: headers);
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ??
          'Erreur lors de la génération de la prévisualisation du devis');
    }
  }

  /// Confirme la prévisualisation de devis (brouillon) pour un champ newdocgenerator.
  Future<void> confirmNewDocDevisPreview({
    required int campagneId,
    required String tabTag,
    required String formTag,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
        '$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/devis/confirm');

    final response = await http.post(uri, headers: headers);
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ??
          'Erreur lors de la confirmation du devis');
    }
  }

  /// Annule la prévisualisation de devis (brouillon) pour un champ newdocgenerator.
  Future<void> cancelNewDocDevisPreview({
    required int campagneId,
    required String tabTag,
    required String formTag,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
        '$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/devis/cancel');

    final response = await http.post(uri, headers: headers);
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ??
          'Erreur lors de l\'annulation du brouillon de devis');
    }
  }

  Future<void> generateNewDocDevis({
    required int campagneId,
    required String tabTag,
    required String formTag,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/devis');

    final response = await http.post(uri, headers: headers);
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ?? 'Erreur lors de la génération du devis');
    }
  }

  Future<void> generateNewDocFacture({
    required int campagneId,
    required String tabTag,
    required String formTag,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/facture');

    final response = await http.post(uri, headers: headers);
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ?? 'Erreur lors de la génération de la facture');
    }
  }

  /// Génère une FACTURE en mode "prévisualisation" (brouillon) pour un champ newdocgenerator.
  Future<void> generateNewDocFacturePreview({
    required int campagneId,
    required String tabTag,
    required String formTag,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
        '$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/facture/preview');

    final response = await http.post(uri, headers: headers);
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ??
          'Erreur lors de la génération de l\'aperçu de la facture');
    }
  }

  /// Confirme la FACTURE en brouillon.
  Future<void> confirmNewDocFacturePreview({
    required int campagneId,
    required String tabTag,
    required String formTag,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
        '$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/facture/confirm');

    final response = await http.post(uri, headers: headers);
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ??
          'Erreur lors de la confirmation de la facture');
    }
  }

  /// Annule la FACTURE en brouillon (supprime l'aperçu).
  Future<void> cancelNewDocFacturePreview({
    required int campagneId,
    required String tabTag,
    required String formTag,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
        '$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/facture/cancel');

    final response = await http.post(uri, headers: headers);
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ??
          'Erreur lors de l\'annulation du brouillon de facture');
    }
  }

  /// Envoi par email du devis ou de la facture d'un champ newdocgenerator,
  /// avec destinataire modifiable et pièces jointes optionnelles.
  Future<void> sendNewDocEmail({
    required int campagneId,
    required String tabTag,
    required String formTag,
    required String recipient,
    required String subject,
    required String message,
    required String documentType, // 'devis' ou 'facture'
    List<File>? attachments,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    final uri = Uri.parse(
        '$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/send-email');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['recipient'] = recipient;
    request.fields['subject'] = subject;
    request.fields['message'] = message;
    request.fields['document_type'] = documentType;

    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        final multipartFile = await http.MultipartFile.fromPath(
          'attachments[]',
          file.path,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    _handleAuthError(response);

    final Map<String, dynamic> jsonData = json.decode(response.body);
    if (response.statusCode != 200 || jsonData['success'] != true) {
      throw Exception(jsonData['message'] ?? 'Erreur lors de l\'envoi de l\'email');
    }
  }

  Future<void> updateNewDocProductLines({
    required int campagneId,
    required String tabTag,
    required String formTag,
    required List<Map<String, dynamic>> productLines,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/product-lines');

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'product_lines': productLines}),
    );
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ?? 'Erreur lors de la mise à jour des lignes produits');
    }
  }

  /// Upload de médias pour un champ mediauploader
  Future<List<String>> uploadMedia({
    required int campagneId,
    required String tabTag,
    required String formTag,
    required List<File> mediaFiles,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    final uri = Uri.parse('$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/media');
    
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Ajouter tous les fichiers
    for (var file in mediaFiles) {
      final fileExtension = file.path.split('.').last.toLowerCase();
      String? contentType;
      
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileExtension)) {
        contentType = 'image/$fileExtension';
        if (fileExtension == 'jpg') contentType = 'image/jpeg';
      } else if (['mp4', 'avi', 'mov', 'wmv', 'webm', 'ogg'].contains(fileExtension)) {
        contentType = 'video/$fileExtension';
      } else if (fileExtension == 'pdf') {
        contentType = 'application/pdf';
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'media[]',
        file.path,
        filename: file.path.split('/').last,
        contentType: contentType != null ? MediaType.parse(contentType) : null,
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    _handleAuthError(response);

    if (response.statusCode != 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      throw Exception(jsonData['message'] ?? 'Erreur lors de l\'upload des médias');
    }

    final Map<String, dynamic> jsonData = json.decode(response.body);
    if (jsonData['success'] == true && jsonData['media'] != null) {
      return List<String>.from(jsonData['media']);
    }
    
    throw Exception('Erreur lors de l\'upload des médias');
  }

  /// Récupérer les commentaires d'un média (imageId = md5 du chemin relatif)
  Future<List<Map<String, dynamic>>> getMediaComments(String imageId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/mobile/media-comments/$imageId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['error'] ?? jsonData['message'] ?? 'Erreur lors du chargement des commentaires');
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      if (jsonData['success'] == true && jsonData['comments'] != null) {
        return List<Map<String, dynamic>>.from(jsonData['comments'] as List);
      }

      return [];
    } catch (e) {
      print('Erreur lors du chargement des commentaires média: $e');
      rethrow;
    }
  }

  /// Ajouter un commentaire texte (sans pièce jointe) sur un média
  Future<Map<String, dynamic>> addMediaComment({
    required String imageId,
    required String message,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final uri = Uri.parse('$baseUrl/mobile/media-comments');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['imageId'] = imageId;
      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['error'] ?? jsonData['message'] ?? 'Erreur lors de l\'ajout du commentaire');
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      if (jsonData['success'] == true && jsonData['comment'] != null) {
        return Map<String, dynamic>.from(jsonData['comment'] as Map);
      }

      throw Exception('Erreur lors de l\'ajout du commentaire');
    } catch (e) {
      print('Erreur lors de l\'ajout du commentaire média: $e');
      rethrow;
    }
  }

  /// Supprimer (soft delete) un commentaire média
  Future<Map<String, dynamic>> deleteMediaComment(int commentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/mobile/media-comments/$commentId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['error'] ?? jsonData['message'] ?? 'Erreur lors de la suppression du commentaire');
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      return jsonData;
    } catch (e) {
      print('Erreur lors de la suppression du commentaire média: $e');
      rethrow;
    }
  }

  /// Suppression d'un média pour un champ mediauploader (par index)
  Future<List<String>> deleteMedia({
    required int campagneId,
    required String tabTag,
    required String formTag,
    required int index,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/campagnes/$campagneId/docs/$tabTag/$formTag/media/$index'),
        headers: headers,
      );

      _handleAuthError(response);

      if (response.statusCode != 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Erreur lors de la suppression du média');
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      if (jsonData['success'] == true && jsonData['remaining_media'] != null) {
        return List<String>.from(jsonData['remaining_media']);
      }

      return [];
    } catch (e) {
      print('Erreur lors de la suppression du média: $e');
      rethrow;
    }
  }
}