// lib/services/dashboard_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class DashboardService {
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

  /// Récupérer les données du dashboard
  Future<Map<String, dynamic>> getDashboard({
    String dateFilter = 'this_month',
    String? userFilter,
  }) async {
    try {
      final headers = await _getHeaders();
      
      var url = '$baseUrl/dashboard?date_filter=$dateFilter';
      if (userFilter != null && userFilter.isNotEmpty) {
        url += '&user_filter=$userFilter';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors du chargement du dashboard: $e');
      rethrow;
    }
  }
}
