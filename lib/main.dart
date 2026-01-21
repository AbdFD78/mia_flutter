// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/users_screen.dart';
import 'screens/campaigns_screen.dart';
import 'screens/events_screen.dart';
import 'screens/coming_soon_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Mia CRM',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: authProvider.isAuthenticated ? '/dashboard' : '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        // Si l'utilisateur n'est pas authentifié et n'est pas sur la page de login
        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        // Si l'utilisateur est authentifié et essaie d'accéder à la page de login
        if (isAuthenticated && isLoggingIn) {
          return '/dashboard';
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
          builder: (context, state) => const ComingSoonScreen(title: 'Suivies Clients'),
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
          builder: (context, state) => const ComingSoonScreen(title: 'Mon Profil'),
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
