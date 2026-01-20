// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  Map<String, dynamic>? _validationErrors;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get validationErrors => _validationErrors;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Initialiser le provider et vérifier si l'utilisateur est déjà connecté
  Future<void> initialize() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final isAuth = await _authService.isAuthenticated();
      
      if (isAuth) {
        // Valider le token auprès du serveur
        final isValid = await _authService.validateToken();
        
        if (isValid) {
          _user = await _authService.getCurrentUser();
          _status = AuthStatus.authenticated;
        } else {
          // Token invalide, déconnexion
          await _authService.clearAuthData();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  /// Connexion de l'utilisateur
  Future<bool> login({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _validationErrors = null;
      notifyListeners();

      final result = await _authService.login(
        email: email,
        password: password,
        remember: remember,
      );

      if (result['success'] == true) {
        _user = result['user'];
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _validationErrors = result['errors'];
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la connexion: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> logout() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authService.logout();
      
      _user = null;
      _errorMessage = null;
      _validationErrors = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      // Même en cas d'erreur, on déconnecte l'utilisateur localement
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Réinitialiser les erreurs
  void clearErrors() {
    _errorMessage = null;
    _validationErrors = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Récupérer le token actuel
  Future<String?> getToken() async {
    return await _authService.getToken();
  }
}
