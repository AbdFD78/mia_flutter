// lib/screens/users_screen.dart

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Charger les utilisateurs depuis l'API
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _apiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Utilisateurs', style: AppTheme.heading1),
      ),
      drawer: const AppDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Affichage pendant le chargement
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Affichage en cas d'erreur
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.accentRed),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Erreur de connexion',
                style: AppTheme.heading2,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Affichage si aucun utilisateur
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.textHint),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Aucun utilisateur trouvé',
              style: AppTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    // Affichage de la liste des utilisateurs
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(user: user),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Avatar + Nom
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
                    backgroundImage: user.picture != null
                        ? NetworkImage(user.picture!)
                        : null,
                    child: user.picture == null
                        ? Icon(
                            Icons.person,
                            size: 30,
                            color: AppTheme.accentBlue,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  
                  // Nom et type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTheme.heading3,
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        if (user.userTypeName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: AppTheme.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                            child: Text(
                              user.userTypeName!,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.accentBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Icône flèche
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.spacingL),
              
              // Informations
              _buildInfoRow(Icons.email_outlined, 'Email', user.email),
              
              if (user.telephone != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                _buildInfoRow(Icons.phone_outlined, 'Téléphone', user.telephone!),
              ],
              
              if (user.clientName != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                _buildInfoRow(Icons.business_outlined, 'Client', user.clientName!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
