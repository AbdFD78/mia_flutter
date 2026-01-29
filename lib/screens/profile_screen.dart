// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/app_drawer.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String? _currentImageUrl;
  
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = false;
  bool _isLoadingTeam = false;
  bool _isSaving = false;
  bool _isChangingPassword = false;
  
  // État des notifications push
  bool _pushNotificationsEnabled = false;
  bool _isLoadingPushDevices = false;
  bool _isTogglingPush = false;
  Map<String, dynamic>? _currentDevice;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTeam();
    _loadPushDevices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = await _apiService.getProfile();
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      
      setState(() {
        _nameController.text = profileData['name'] ?? user?.name ?? '';
        _emailController.text = profileData['email'] ?? user?.email ?? '';
        _currentImageUrl = profileData['picture'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadTeam() async {
    setState(() {
      _isLoadingTeam = true;
    });

    try {
      final team = await _apiService.getTeamMembers();
      setState(() {
        _teamMembers = team;
        _isLoadingTeam = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTeam = false;
      });
      print('Erreur lors du chargement de l\'équipe: $e');
    }
  }


  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedData = await _apiService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      // Mettre à jour le provider avec les nouvelles données
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.updateUser(
        name: updatedData['name'] ?? _nameController.text.trim(),
        email: updatedData['email'] ?? _emailController.text.trim(),
        picture: updatedData['picture'],
      );

      setState(() {
        _currentImageUrl = updatedData['picture'];
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil mis à jour avec succès'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      await _apiService.updatePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      setState(() {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _isChangingPassword = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mot de passe mis à jour avec succès'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isChangingPassword = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Mon Profil', style: AppTheme.heading2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte utilisateur
                  _buildUserCard(user),
                  
                  const SizedBox(height: 16),
                  
                  // Section équipe
                  _buildTeamSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Section paramètres
                  _buildSettingsSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Formulaire de modification du profil
                  _buildProfileForm(),
                  
                  const SizedBox(height: 16),
                  
                  // Formulaire de changement de mot de passe
                  _buildPasswordForm(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard(User? user) {
    final imageUrl = _currentImageUrl ?? user?.picture;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Photo de profil en pleine largeur
          Container(
            width: double.infinity,
            height: 200,
            color: AppTheme.borderLight,
            child: imageUrl != null
                ? Image.network(
                    AppConfig.getResourceUrl(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.person, size: 80, color: AppTheme.textHint),
                      );
                    },
                  )
                : Center(
                    child: Icon(Icons.person, size: 80, color: AppTheme.textHint),
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXXL),
            child: Column(
              children: [
                // Nom
                Text(
                  user?.name ?? 'Utilisateur',
                  style: AppTheme.heading3.copyWith(fontSize: 22),
                ),
                
                const SizedBox(height: AppTheme.spacingXS),
                
                // Email
                Text(
                  user?.email ?? '',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Text(
              'MON ÉQUIPE',
              style: AppTheme.heading3.copyWith(fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          _isLoadingTeam
              ? const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingL),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _teamMembers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Text(
                        'Aucun membre d\'équipe',
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _teamMembers.length,
                      itemBuilder: (context, index) {
                        final member = _teamMembers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member['picture'] != null
                                ? NetworkImage(AppConfig.getResourceUrl(member['picture']))
                                : null,
                            child: member['picture'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(member['name'] ?? '', style: AppTheme.bodyMedium),
                          subtitle: Text(
                            member['user_type'] ?? 'Inconnu',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.accentBlue,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.email, color: AppTheme.textSecondary),
                            onPressed: () {
                              // TODO: Ouvrir l'email
                            },
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  /// Charger l'état des devices push
  Future<void> _loadPushDevices() async {
    setState(() {
      _isLoadingPushDevices = true;
    });

    try {
      final devices = await _apiService.getPushDevices();
      
      // Trouver le device mobile actuel (actif)
      Map<String, dynamic>? mobileDevice;
      try {
        mobileDevice = devices.firstWhere(
          (device) => device['device_type'] == 'mobile' && device['is_active'] == true,
        ) as Map<String, dynamic>?;
      } catch (e) {
        // Aucun device mobile actif trouvé
        mobileDevice = null;
      }
      
      setState(() {
        _currentDevice = mobileDevice;
        _pushNotificationsEnabled = mobileDevice != null 
            ? (mobileDevice['is_active'] == true && mobileDevice['notifications_enabled'] == true)
            : false;
        _isLoadingPushDevices = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPushDevices = false;
      });
      print('Erreur lors du chargement des devices push: $e');
    }
  }

  /// Toggle les notifications push
  Future<void> _togglePushNotifications(bool enabled) async {
    setState(() {
      _isTogglingPush = true;
    });

    try {
      if (enabled) {
        // Activer : enregistrer le device
        try {
          final success = await PushNotificationService().registerDevice();
          if (success) {
            // Recharger l'état
            await _loadPushDevices();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifications push activées'),
                  backgroundColor: AppTheme.accentGreen,
                ),
              );
            }
          } else {
            throw Exception('Impossible d\'enregistrer le device');
          }
        } catch (e) {
          // Gérer spécifiquement les erreurs Firebase
          final errorMessage = e.toString();
          if (errorMessage.contains('Firebase') || errorMessage.contains('FCM')) {
            throw Exception('Erreur Firebase: $errorMessage\n\nSur iOS, vérifiez que GoogleService-Info.plist est correctement configuré dans Xcode.');
          }
          rethrow;
        }
      } else {
        // Désactiver : supprimer le device
        if (_currentDevice != null) {
          final deviceFingerprint = _currentDevice!['device_fingerprint'];
          final fcmToken = PushNotificationService().fcmToken;
          
          final success = await _apiService.disablePushDevice(
            deviceFingerprint: deviceFingerprint,
            fcmToken: fcmToken,
          );
          
          if (success) {
            // Recharger l'état
            await _loadPushDevices();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifications push désactivées'),
                  backgroundColor: AppTheme.accentGreen,
                ),
              );
            }
          } else {
            throw Exception('Impossible de désactiver le device');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
      // Restaurer l'état précédent en cas d'erreur
      setState(() {
        _pushNotificationsEnabled = !enabled;
      });
    } finally {
      setState(() {
        _isTogglingPush = false;
      });
    }
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Text(
              'Paramètres',
              style: AppTheme.heading3.copyWith(fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: _isLoadingPushDevices
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _pushNotificationsEnabled 
                                      ? Icons.notifications_active 
                                      : Icons.notifications_off,
                                  color: _pushNotificationsEnabled 
                                      ? AppTheme.accentBlue 
                                      : AppTheme.textHint,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Text(
                                  'Notifications push',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              _pushNotificationsEnabled
                                  ? 'Recevoir des notifications push sur cet appareil'
                                  : 'Activer les notifications push sur cet appareil',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ),
                      if (_isTogglingPush)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Switch(
                          value: _pushNotificationsEnabled,
                          onChanged: _togglePushNotifications,
                          activeColor: AppTheme.accentBlue,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Text(
                'Modifier mon profil',
                style: AppTheme.heading3,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                children: [
                  // Nom
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est requis';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Email (modifiable)
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'email est requis';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Bouton Enregistrer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Card(
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Text(
                'Modifier mon mot de passe',
                style: AppTheme.heading3,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                children: [
                  // Ancien mot de passe
                  TextFormField(
                    controller: _oldPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Ancien mot de passe',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'ancien mot de passe est requis';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Nouveau mot de passe
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau mot de passe',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le nouveau mot de passe est requis';
                      }
                      if (value.length < 8) {
                        return 'Le mot de passe doit contenir au moins 8 caractères';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Confirmer le mot de passe
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La confirmation est requise';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // Bouton Enregistrer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isChangingPassword ? null : _changePassword,
                      child: _isChangingPassword
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
