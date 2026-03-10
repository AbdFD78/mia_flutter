// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/auth_provider.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/users_screen.dart';
import 'screens/campaigns_screen.dart';
import 'screens/events_screen.dart';
import 'screens/activities_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/coming_soon_screen.dart';

/// Handler pour les notifications en arrière-plan (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Notification en arrière-plan: ${message.notification?.title}');
  // Traitement en arrière-plan si nécessaire
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  // Note: Sur iOS, Firebase peut être initialisé dans AppDelegate.swift
  // mais on essaie aussi ici pour être sûr
  bool firebaseInitialized = false;
  try {
    // Vérifier si Firebase est déjà initialisé (par AppDelegate sur iOS)
    try {
      Firebase.app();
      print('✅ Firebase déjà initialisé (probablement par AppDelegate sur iOS)');
      firebaseInitialized = true;
    } catch (e) {
      // Firebase n'est pas initialisé, l'initialiser
      print('⚠️ Firebase non initialisé, tentative d\'initialisation...');
      await Firebase.initializeApp();
      print('✅ Firebase initialisé depuis main.dart');
      firebaseInitialized = true;
    }
    
    // Configurer le handler pour les notifications en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation de Firebase: $e');
    print('   Type d\'erreur: ${e.runtimeType}');
    if (e.toString().contains('GoogleService-Info.plist') || 
        e.toString().contains('not-initialized')) {
      print('   ⚠️ Vérifiez que GoogleService-Info.plist est présent dans ios/Runner/');
      print('   ⚠️ Et qu\'il est ajouté au projet Xcode dans le bundle');
      print('   ⚠️ Vérifiez aussi que Firebase est initialisé dans AppDelegate.swift');
    }
    print('   Les notifications push ne fonctionneront pas sans Firebase configuré');
    // L'application peut continuer à fonctionner sans les notifications push
  }
  
  if (!firebaseInitialized) {
    print('⚠️ Application démarrée sans Firebase - les notifications push seront désactivées');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Mia CRM',
            theme: AppTheme.lightTheme,
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    final user = authProvider.user;
    final perms = user?.permissions ?? const [];
    final bool canAccessDashboard = perms.contains('ACCESS_DASHBOARD');

    return GoRouter(
      initialLocation: authProvider.isAuthenticated
          ? (canAccessDashboard ? '/dashboard' : '/profile')
          : '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        final location = state.matchedLocation;

        // Si l'utilisateur n'est pas authentifié et n'est pas sur la page de login
        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        // Si l'utilisateur est authentifié et essaie d'accéder à la page de login
        if (isAuthenticated && isLoggingIn) {
          return canAccessDashboard ? '/dashboard' : '/profile';
        }

        // Empêcher l'accès direct au dashboard si l'utilisateur n'a pas la permission
        if (isAuthenticated && location == '/dashboard' && !canAccessDashboard) {
          return '/profile';
        }

        // Pas de redirection nécessaire
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/clients',
          builder: (context, state) => const ClientsScreen(),
        ),
        // Événements
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventsScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const ComingSoonScreen(title: 'Calendrier'),
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) => const ActivitiesScreen(),
        ),
        // Campagnes
        GoRoute(
          path: '/campagnes',
          builder: (context, state) => const CampaignsScreen(),
        ),
        GoRoute(
          path: '/campagne-configs',
          builder: (context, state) => const ComingSoonScreen(title: 'Configurer Campagnes'),
        ),
        GoRoute(
          path: '/form-templates',
          builder: (context, state) => const ComingSoonScreen(title: 'Formulaires'),
        ),
        GoRoute(
          path: '/produits',
          builder: (context, state) => const ComingSoonScreen(title: 'Produits'),
        ),
        // Email
        GoRoute(
          path: '/email/inbox',
          builder: (context, state) => const ComingSoonScreen(title: 'Boîte de réception'),
        ),
        // Utilisateurs
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/permissions',
          builder: (context, state) => const ComingSoonScreen(title: 'Permissions'),
        ),
        GoRoute(
          path: '/video-calls',
          builder: (context, state) => const ComingSoonScreen(title: 'Conférences'),
        ),
        // Groupes
        GoRoute(
          path: '/groupes',
          builder: (context, state) => const ComingSoonScreen(title: 'Groupes'),
        ),
        // Utilitaires
        GoRoute(
          path: '/statuses',
          builder: (context, state) => const ComingSoonScreen(title: 'Status'),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const ComingSoonScreen(title: 'Catégories'),
        ),
        // Gestion MIA
        GoRoute(
          path: '/entreprise',
          builder: (context, state) => const ComingSoonScreen(title: 'Entreprise'),
        ),
        GoRoute(
          path: '/file-transfers',
          builder: (context, state) => const ComingSoonScreen(title: 'MIA Transfer'),
        ),
        GoRoute(
          path: '/documents',
          builder: (context, state) => const ComingSoonScreen(title: 'Documents'),
        ),
        GoRoute(
          path: '/api-keys',
          builder: (context, state) => const ComingSoonScreen(title: 'API'),
        ),
        GoRoute(
          path: '/logs',
          builder: (context, state) => const ComingSoonScreen(title: 'Logs'),
        ),
        // Profil
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
      // Gestion des erreurs de route
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page non trouvée: ${state.uri}'),
        ),
      ),
      // Rafraîchir le routeur quand l'état d'authentification change
      refreshListenable: authProvider,
    );
  }
}
