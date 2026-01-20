import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

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
            
            // Menu principal
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.account_circle,
                    title: 'Mon Profil',
                    route: '/profile',
                  ),
                  _buildExpandableMenuItem(
                    context,
                    icon: Icons.business_center,
                    title: 'Clients',
                    subItems: [
                      {'title': 'Liste clients', 'route': '/clients', 'icon': 'list'},
                    ],
                  ),
                  _buildExpandableMenuItem(
                    context,
                    icon: Icons.group,
                    title: 'Utilisateurs',
                    subItems: [
                      {'title': 'Liste utilisateurs', 'route': '/users', 'icon': 'list'},
                    ],
                  ),
                  _buildExpandableMenuItem(
                    context,
                    icon: Icons.campaign,
                    title: 'Campagnes',
                    subItems: [
                      {'title': 'Mes campagnes', 'route': '/campagnes', 'icon': 'list'},
                    ],
                  ),
                  _buildExpandableMenuItem(
                    context,
                    icon: Icons.event,
                    title: 'Événements',
                    subItems: [
                      {'title': 'Liste des événements', 'route': '/events', 'icon': 'list'},
                      {'title': 'Calendrier', 'route': '/calendar', 'icon': 'calendar'},
                      {'title': 'Suivies clients', 'route': '/activities', 'icon': 'track'},
                    ],
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.exit_to_app,
                    title: 'Déconnexion',
                    onTap: () => _handleLogout(context),
                    textColor: Colors.red,
                  ),
                ],
              ),
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
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Photo utilisateur
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFFff6b9d).withOpacity(0.1),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user?.picture != null
                      ? NetworkImage('http://10.0.2.2:8000${user!.picture}')
                      : null,
                  child: user?.picture == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // Nom de l'utilisateur
              Text(
                user?.name ?? 'Utilisateur',
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Email de l'utilisateur
              Text(
                user?.email ?? '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
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

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFFff6b9d) : (textColor ?? Colors.grey[700]),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? const Color(0xFFff6b9d) : (textColor ?? Colors.grey[800]),
        ),
      ),
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (route != null) {
          context.go(route);
        }
      },
      selected: isActive,
      selectedTileColor: const Color(0xFFff6b9d).withOpacity(0.1),
    );
  }

  Widget _buildExpandableMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Map<String, String>> subItems,
  }) {
    return ExpansionTile(
      leading: Icon(
        icon,
        color: Colors.grey[700],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: Colors.grey[800],
        ),
      ),
      childrenPadding: EdgeInsets.zero,
      children: subItems.map((item) {
        return _buildSubMenuItem(
          context,
          title: item['title']!,
          route: item['route']!,
          iconType: item['icon']!,
        );
      }).toList(),
    );
  }

  Widget _buildSubMenuItem(
    BuildContext context, {
    required String title,
    required String route,
    required String iconType,
  }) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isActive = currentRoute == route;

    // Choisir l'icône selon le type
    IconData iconData;
    switch (iconType) {
      case 'list':
        iconData = Icons.list_alt;
        break;
      case 'calendar':
        iconData = Icons.calendar_month;
        break;
      case 'track':
        iconData = Icons.track_changes;
        break;
      default:
        iconData = Icons.arrow_right;
    }

    return ListTile(
      leading: Icon(
        iconData,
        size: 20,
        color: isActive ? const Color(0xFFff6b9d) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? const Color(0xFFff6b9d) : Colors.grey[700],
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
      selected: isActive,
      selectedTileColor: const Color(0xFFff6b9d).withOpacity(0.1),
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
