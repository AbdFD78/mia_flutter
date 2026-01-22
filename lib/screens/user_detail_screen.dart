// lib/screens/user_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(user.name, style: AppTheme.heading2),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec avatar
            _buildHeader(),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Informations de l'utilisateur
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppTheme.backgroundSecondary,
      padding: const EdgeInsets.all(AppTheme.spacingXXL),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
            backgroundImage: user.picture != null
                ? NetworkImage(user.picture!)
                : null,
            child: user.picture == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: AppTheme.accentBlue,
                  )
                : null,
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Nom
          Text(
            user.name,
            style: AppTheme.heading1,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          // Type d'utilisateur
          if (user.userTypeName != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Text(
                user.userTypeName!,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            
            _buildDetailRow('ID', user.id.toString()),
            const SizedBox(height: AppTheme.spacingL),
            
            _buildDetailRow('Nom', user.name),
            const SizedBox(height: AppTheme.spacingL),
            
            _buildDetailRow('Email', user.email),
            const SizedBox(height: AppTheme.spacingL),
            
            _buildDetailRow('Téléphone', user.telephone ?? 'Non défini'),
            const SizedBox(height: AppTheme.spacingL),
            
            if (user.clientName != null) ...[
              _buildDetailRow('Client', user.clientName!),
              const SizedBox(height: AppTheme.spacingL),
            ],
            
            if (user.userTypeName != null)
              _buildDetailRow('Type d\'utilisateur', user.userTypeName!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingM,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(
              color: AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: AppTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
