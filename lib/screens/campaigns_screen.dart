// lib/screens/campaigns_screen.dart

import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import 'campaign_detail_screen.dart';
import 'campaign_create_screen.dart';
import 'campaign_edit_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Campaign> _campaigns = [];
  List<Campaign> _filteredCampaigns = [];
  List<Map<String, dynamic>> _clients = [];
  int? _selectedClientId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _searchController.addListener(_filterCampaigns);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _apiService.getCampaigns(
        clientId: _selectedClientId,
      );

      setState(() {
        _campaigns = result['campaigns'] as List<Campaign>;
        _filteredCampaigns = _campaigns;
        _clients = List<Map<String, dynamic>>.from(result['clients'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterCampaigns() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCampaigns = _campaigns;
      } else {
        _filteredCampaigns = _campaigns
            .where((campaign) => campaign.nom.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Mes Campagnes', style: AppTheme.heading1),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Container(
            color: AppTheme.backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(AppTheme.spacingL, 0, AppTheme.spacingL, AppTheme.spacingL),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par nom...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                
                // Filtre par client
                Container(
                  decoration: AppTheme.dropdownDecoration,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedClientId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.business_outlined),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: AppTheme.spacingL, vertical: AppTheme.spacingM + 2),
                      hintText: 'Tous les clients',
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tous les clients'),
                      ),
                      ..._clients.map((client) {
                        return DropdownMenuItem<int?>(
                          value: client['id'] as int,
                          child: Text(
                            client['name'] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedClientId = value;
                      });
                      _loadCampaigns();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Naviguer vers l'écran de création
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CampaignCreateScreen(),
            ),
          );
          
          // Recharger la liste si une campagne a été créée
          if (result == true) {
            _loadCampaigns();
          }
        },
        backgroundColor: AppTheme.accentBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Créer une campagne',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.accentRed),
                      const SizedBox(height: AppTheme.spacingL),
                      Text('Erreur: $_error', style: AppTheme.bodyLarge),
                      const SizedBox(height: AppTheme.spacingL),
                      ElevatedButton(
                        onPressed: _loadCampaigns,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCampaigns,
                  child: _filteredCampaigns.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.campaign_outlined,
                                    size: 80,
                                    color: AppTheme.textHint,
                                  ),
                                  const SizedBox(height: AppTheme.spacingL),
                                  Text(
                                    'Aucune campagne trouvée',
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredCampaigns.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildCampaignCard(_filteredCampaigns[index]),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
              child: Text(
                campaign.nom.isNotEmpty 
                    ? campaign.nom[0].toUpperCase() 
                    : 'C',
                style: AppTheme.heading3.copyWith(
                  fontSize: 20,
                  color: AppTheme.accentBlue,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),
            
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de la campagne
                  Text(
                    campaign.nom,
                    style: AppTheme.heading3.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Nom du client
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          campaign.clientName,
                          style: AppTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Configuration
                  Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          campaign.configName,
                          style: AppTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Boutons d'action
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton Voir
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CampaignDetailScreen(campaign: campaign),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  color: Colors.blue[700],
                  tooltip: 'Voir',
                ),
                
                // Bouton Éditer (affiché uniquement si l'utilisateur a la permission)
                if (campaign.canEdit)
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampaignEditScreen(campaign: campaign),
                        ),
                      );
                      
                      // Recharger la liste si la campagne a été modifiée
                      if (result == true) {
                        _loadCampaigns();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.green[700],
                    tooltip: 'Modifier',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
