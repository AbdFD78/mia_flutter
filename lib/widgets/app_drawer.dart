import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // En-tête avec photo de profil et informations utilisateur
            _buildUserHeader(context),

            // Menu principal (logique alignée sur la sidebar web via les permissions)
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.user;
                  final perms = user?.permissions ?? const [];

                  final List<Widget> items = [];

                  // Dashboard :
                  // - Sur le web, le lien est dans le bloc profil et visible seulement pour le client "CLIENT0"
                  // - Ici, on ajoute aussi un contrôle de permission explicite ACCESS_DASHBOARD
                  if (user != null &&
                      user.clientName == 'CLIENT0' &&
                      perms.contains('ACCESS_DASHBOARD')) {
                    items.add(
                      _buildMenuItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        title: 'Tableau de bord',
                        route: '/dashboard',
                      ),
                    );
                  }

                  // Mon Profil (toujours visible, comme sur le web)
                  items.add(
                    _buildMenuItem(
                      context,
                      icon: Icons.account_circle_outlined,
                      title: 'Mon Profil',
                      route: '/profile',
                    ),
                  );

                  // CLIENTS -> section "CLIENT" sur le web, sous-lien "CLIENTS" (ACCESS_CLIENTS)
                  if (perms.contains('ACCESS_CLIENTS')) {
                    items.add(
                      _buildMenuItem(
                        context,
                        icon: Icons.business_center_outlined,
                        title: 'Clients',
                        route: '/clients',
                      ),
                    );
                  }

                  // UTILISATEURS -> section "UTILISATEURS", sous-lien "UTILISATEURS" (ACCESS_USERS)
                  if (perms.contains('ACCESS_USERS')) {
                    items.add(
                      _buildMenuItem(
                        context,
                        icon: Icons.group_outlined,
                        title: 'Utilisateurs',
                        route: '/users',
                      ),
                    );
                  }

                  // CAMPAGNES -> section "CAMPAGNE", sous-lien "MES CAMPAGNES" (ACCESS_CAMPAGNE)
                  if (perms.contains('ACCESS_CAMPAGNE')) {
                    items.add(
                      _buildMenuItem(
                        context,
                        icon: Icons.campaign_outlined,
                        title: 'Campagnes',
                        route: '/campagnes',
                      ),
                    );
                  }

                  // EVENEMENTS -> section "Evenements", sous-lien "EVENEMENTS" (ACCESS_EVENTS)
                  if (perms.contains('ACCESS_EVENTS')) {
                    items.add(
                      _buildMenuItem(
                        context,
                        icon: Icons.event_outlined,
                        title: 'Liste des événements',
                        route: '/events',
                      ),
                    );
                  }

                  // CALENDRIER -> section "Evenements", sous-lien "CALENDRIER" (ACCESS_EVENTS_CALENDAR)
                  if (perms.contains('ACCESS_EVENTS_CALENDAR')) {
                    items.add(
                      _buildMenuItem(
                        context,
                        icon: Icons.calendar_month_outlined,
                        title: 'Calendrier',
                        route: '/calendar',
                      ),
                    );
                  }

                  // SUIVIES CLIENTS -> section "Evenements", sous-lien "SUIVIES CLIENTS" (ACCESS_SUIVIES_CLIENTS)
                  if (perms.contains('ACCESS_SUIVIES_CLIENTS')) {
                    items.add(
                      _buildMenuItem(
                        context,
                        icon: Icons.track_changes_outlined,
                        title: 'Suivies clients',
                        route: '/activities',
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: items,
                  );
                },
              ),
            ),
            
            // Déconnexion en bas, séparée visuellement
            const Divider(height: 1),
            _buildMenuItem(
              context,
              icon: Icons.exit_to_app_outlined,
              title: 'Déconnexion',
              onTap: () => _handleLogout(context),
              textColor: AppTheme.accentRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return InkWell(
          onTap: () {
            Navigator.pop(context);
            context.go('/profile');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Photo de profil
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
                  child: user?.picture != null
                      ? CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: NetworkImage(AppConfig.getResourceUrl(user!.picture!)),
                          onBackgroundImageError: (exception, stackTrace) {
                            // Erreur silencieuse - l'icône par défaut sera affichée
                          },
                          child: const Icon(Icons.person, size: 24, color: Colors.grey),
                        )
                      : CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, size: 24, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                // Nom et email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom de l'utilisateur (plus visible)
                      Text(
                        user?.name ?? 'Utilisateur',
                        style: const TextStyle(
                          color: Color(0xFF212121),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Email (moins visible)
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Bouton compact "Profil"
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.accentBlue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isActive = route != null && currentRoute == route;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap ?? () {
            Navigator.pop(context);
            if (route != null) {
              context.go(route);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? AppTheme.accentBlue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: AppTheme.accentBlue,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // Icône
                Icon(
                  icon,
                  color: isActive
                      ? AppTheme.accentBlue
                      : (textColor ?? Colors.grey[700]),
                  size: 24,
                ),
                const SizedBox(width: 16),
                // Titre
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isActive
                          ? AppTheme.accentBlue
                          : (textColor ?? Colors.grey[800]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    final authProvider = context.read<AuthProvider>();

    try {
      await authService.logout();
      authProvider.logout();
      
      if (context.mounted) {
        Navigator.pop(context);
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
