// lib/config/app_config.dart

class AppConfig {
  // ============================================
  // CONFIGURATION ENVIRONNEMENT
  // ============================================
  // Pour tester en PRODUCTION, changez cette valeur à true
  // Pour développer en LOCAL, gardez cette valeur à false
  // 
  // IMPORTANT: Après avoir changé cette valeur, faites un
  // "Hot Restart" (R majuscule) ou redémarrez l'application
  // ============================================
  static const bool isProduction = true; // ← Changez à true pour la production
  
  // URL de base de l'API
  static String get baseUrl {
    return isProduction 
        ? 'https://crm.model-intelligence-agency.com/api'  // Site en ligne
        : 'http://10.0.2.2:8000/api';                      // Localhost (émulateur Android)
  }
  
  // URL de base du serveur (sans /api) pour les ressources (images, fichiers, etc.)
  static String get serverUrl {
    return isProduction 
        ? 'https://crm.model-intelligence-agency.com'      // Site en ligne
        : 'http://10.0.2.2:8000';                          // Localhost (émulateur Android)
  }
  
  // Construire une URL complète pour une ressource
  static String getResourceUrl(String path) {
    // Si le path commence par '/', on le garde, sinon on l'ajoute
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverUrl$cleanPath';
  }
  
  // Environnement actuel (pour debug)
  static String get environment => isProduction ? 'PRODUCTION' : 'DÉVELOPPEMENT';
}
