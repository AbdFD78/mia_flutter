// lib/services/push_notification_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

/// Service pour gérer les notifications push natives dans Flutter
/// Compatible avec le système existant Laravel sans modification
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();
  
  String? _fcmToken;
  bool _isInitialized = false;
  BuildContext? _context;
  static const String _permissionDialogShownKey = 'push_notification_dialog_shown';
  
  /// Définir le contexte pour afficher les dialogues
  void setContext(BuildContext context) {
    if (_context == null) {
      _context = context;
    }
  }
  
  /// Afficher un dialogue personnalisé en français avant de demander les permissions
  Future<bool> _showPermissionDialog() async {
    if (_context == null) {
      // Si pas de contexte, demander directement les permissions
      return true;
    }
    
    // Vérifier que le contexte a un Navigator
    try {
      Navigator.of(_context!);
    } catch (e) {
      // Pas de Navigator disponible, demander directement les permissions
      print('⚠️ Navigator non disponible, demande directe des permissions');
      return true;
    }
    
    final result = await showDialog<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Activer les notifications'),
          content: const Text(
            'Souhaitez-vous recevoir des notifications push pour être informé en temps réel des événements et mises à jour importantes ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Activer'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
  
  /// Initialiser le service de notifications push
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Vérifier d'abord l'état actuel des permissions
      NotificationSettings currentSettings = await _messaging.getNotificationSettings();
      
      // Si les permissions sont déjà accordées ou provisoires, ne pas afficher le dialogue
      if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
          currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ Permissions déjà accordées, pas besoin de dialogue');
        await _getFCMToken();
        _setupNotificationHandlers();
        _isInitialized = true;
        return;
      }
      
      // Si les permissions sont refusées, ne pas afficher le dialogue non plus
      if (currentSettings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ Permissions refusées, pas de dialogue');
        return;
      }
      
      // Vérifier si le dialogue a déjà été affiché (première fois seulement)
      final prefs = await SharedPreferences.getInstance();
      final dialogAlreadyShown = prefs.getBool(_permissionDialogShownKey) ?? false;
      
      bool userWantsNotifications = true;
      
      // Afficher le dialogue seulement si c'est la première fois
      if (!dialogAlreadyShown) {
        userWantsNotifications = await _showPermissionDialog();
        // Mémoriser que le dialogue a été affiché
        await prefs.setBool(_permissionDialogShownKey, true);
      }
      
      if (!userWantsNotifications) {
        print('⚠️ L\'utilisateur a refusé les notifications');
        return;
      }
      
      // Demander les permissions système
      
      if (!userWantsNotifications) {
        print('⚠️ L\'utilisateur a refusé les notifications');
        return;
      }
      
      // Demander les permissions système
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permissions de notification accordées');
        
        // Obtenir le token FCM
        await _getFCMToken();
        
        // Configurer les handlers pour les notifications
        _setupNotificationHandlers();
        
        _isInitialized = true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Permissions de notification provisoires');
        await _getFCMToken();
        _setupNotificationHandlers();
        _isInitialized = true;
      } else {
        print('❌ Permissions de notification refusées');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des notifications push: $e');
    }
  }

  /// Obtenir le token FCM
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('📱 Token FCM obtenu: ${_fcmToken!.substring(0, 20)}...');
        
        // Enregistrer automatiquement le device si l'utilisateur est connecté
        final isAuth = await _authService.isAuthenticated();
        if (isAuth) {
          await registerDevice();
        }
      }
      
      // Écouter les changements de token
      _messaging.onTokenRefresh.listen((newToken) async {
        print('🔄 Token FCM rafraîchi: ${newToken.substring(0, 20)}...');
        _fcmToken = newToken;
        final isAuth = await _authService.isAuthenticated();
        if (isAuth) {
          await registerDevice();
        }
      });
      
      return _fcmToken;
    } catch (e) {
      print('❌ Erreur lors de la récupération du token FCM: $e');
      return null;
    }
  }

  /// Configurer les handlers pour les notifications
  void _setupNotificationHandlers() {
    // Notification reçue quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Notification reçue (app au premier plan):');
      print('   Titre: ${message.notification?.title}');
      print('   Corps: ${message.notification?.body}');
      print('   Data: ${message.data}');
      
      // Ici vous pouvez afficher une notification locale ou mettre à jour l'UI
      // Pour l'instant, on log juste
    });

    // Notification reçue quand l'app est en arrière-plan et l'utilisateur clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Notification ouverte (app en arrière-plan):');
      print('   Titre: ${message.notification?.title}');
      print('   Data: ${message.data}');
      
      // Naviguer vers la page appropriée selon message.data['link']
      _handleNotificationTap(message);
    });

    // Vérifier si l'app a été ouverte depuis une notification (app fermée)
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📬 App ouverte depuis une notification (app fermée):');
        print('   Titre: ${message.notification?.title}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Gérer le clic sur une notification
  void _handleNotificationTap(RemoteMessage message) {
    final link = message.data['link'] ?? message.data['url'] ?? message.data['click_action'];
    if (link != null) {
      print('🔗 Navigation vers: $link');
      // TODO: Implémenter la navigation avec go_router
      // Vous pouvez utiliser un GlobalKey<NavigatorState> ou un router
    }
  }

  /// Obtenir le token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Enregistrer le device sur le serveur Laravel
  /// Vérifier et initialiser Firebase si nécessaire
  Future<void> _ensureFirebaseInitialized() async {
    try {
      // Vérifier si Firebase est déjà initialisé en essayant d'accéder à une app
      Firebase.app();
      print('✅ Firebase déjà initialisé');
    } catch (e) {
      // Firebase n'est pas initialisé, l'initialiser
      print('⚠️ Firebase non initialisé, initialisation en cours...');
      try {
        await Firebase.initializeApp();
        print('✅ Firebase initialisé avec succès');
      } catch (initError) {
        print('❌ Erreur lors de l\'initialisation de Firebase: $initError');
        rethrow;
      }
    }
  }

  /// Utilise l'endpoint existant /push/register-device sans modification
  Future<bool> registerDevice() async {
    try {
      // S'assurer que Firebase est initialisé
      await _ensureFirebaseInitialized();
      
      final isAuth = await _authService.isAuthenticated();
      if (!isAuth) {
        print('⚠️ Utilisateur non authentifié, device non enregistré');
        return false;
      }

      // Obtenir le token FCM si ce n'est pas déjà fait
      if (_fcmToken == null) {
        print('⚠️ Token FCM non disponible, tentative d\'obtention...');
        await _getFCMToken();
        if (_fcmToken == null) {
          print('❌ Impossible d\'obtenir le token FCM');
          return false;
        }
      }

      // Obtenir les informations du device
      final deviceInfo = await _getDeviceInfo();
      
      // Obtenir le token d'authentification
      final token = await _authService.getToken();
      if (token == null) {
        print('⚠️ Token d\'authentification non disponible');
        return false;
      }
      
      // Utiliser l'endpoint API (pas de CSRF requis)
      final baseUrl = AppConfig.baseUrl; // Déjà contient /api
      
      final response = await http.post(
        Uri.parse('$baseUrl/push/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcm_token': _fcmToken,
          'device_fingerprint': deviceInfo['fingerprint'],
          'device_type': 'mobile',
          'platform': deviceInfo['platform'],
          'consent_asked': true,
          'consent_given': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Device enregistré avec succès sur le serveur');
        return true;
      } else {
        print('❌ Erreur lors de l\'enregistrement du device: ${response.statusCode}');
        print('   Réponse: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement du device: $e');
      return false;
    }
  }

  /// Obtenir les informations du device
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String platform = 'unknown';
    String fingerprint = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        platform = 'Android ${androidInfo.version.release}';
        fingerprint = androidInfo.id; // Android ID comme fingerprint
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        platform = 'iOS ${iosInfo.systemVersion}';
        fingerprint = iosInfo.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      print('Erreur lors de la récupération des infos device: $e');
      fingerprint = 'flutter-${DateTime.now().millisecondsSinceEpoch}';
    }

    return {
      'platform': platform,
      'fingerprint': fingerprint,
    };
  }

  /// Désactiver les notifications pour ce device
  Future<bool> disableDevice() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (!isAuth) return false;

      final deviceInfo = await _getDeviceInfo();
      final token = await _authService.getToken();
      if (token == null) return false;
      
      // Utiliser l'endpoint API (pas de CSRF requis)
      final baseUrl = AppConfig.baseUrl; // Déjà contient /api
      
      final response = await http.post(
        Uri.parse('$baseUrl/push/disable-device'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'device_fingerprint': deviceInfo['fingerprint'],
          'fcm_token': _fcmToken,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la désactivation du device: $e');
      return false;
    }
  }
}

