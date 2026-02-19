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
  
  static const String _defaultCampaignImageUrl =
      'https://crm.model-intelligence-agency.com/img/No Profile Picture.png';
  static const String _defaultConfigImageUrl =
      'https://crm.model-intelligence-agency.com/img/defaut-config.jpg';

  List<Campaign> _campaigns = [];
  List<Campaign> _filteredCampaigns = [];
  List<Map<String, dynamic>> _clients = [];
  int? _selectedClientId;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  bool _isGridView = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _searchController.addListener(_filterCampaigns);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
      });

      final result = await _apiService.getCampaigns(
        clientId: _selectedClientId,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _currentPage,
        perPage: 8,
      );

      setState(() {
        _campaigns = result['campaigns'] as List<Campaign>;
        _filteredCampaigns = _campaigns;
        _clients = List<Map<String, dynamic>>.from(result['clients'] ?? []);
        _hasMore = (result['has_more'] ?? false) as bool;
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
    // On relance un chargement serveur dès que l'utilisateur modifie la recherche
    // pour que la pagination soit cohérente avec le filtre.
    if (!_isLoading) {
      _loadCampaigns();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Mes Campagnes', style: AppTheme.heading1),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(
              _isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
            ),
            tooltip: _isGridView ? 'Afficher en liste' : 'Afficher en grille',
          ),
        ],
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
                      : _isGridView
                          ? GridView.builder(
                              padding: const EdgeInsets.all(12),
                              controller: _scrollController,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                // ratio largeur/hauteur -> plus petit => plus de hauteur disponible
                                childAspectRatio: 0.7,
                              ),
                              itemCount: _filteredCampaigns.length,
                              itemBuilder: (context, index) {
                                return _buildCampaignGridCard(_filteredCampaigns[index]);
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              controller: _scrollController,
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

  String _buildImageUrl(String? path, String fallback) {
    if (path == null || path.isEmpty) {
      return fallback;
    }
    if (path.startsWith('http')) {
      return path;
    }
    return 'https://crm.model-intelligence-agency.com/$path';
  }

  String _getCampaignImageUrl(Campaign campaign) {
    return _buildImageUrl(campaign.picture, _defaultCampaignImageUrl);
  }

  String _getConfigImageUrl(Campaign campaign) {
    return _buildImageUrl(campaign.configPicture, _defaultConfigImageUrl);
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (!_scrollController.hasClients) return;

    final threshold = 200.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= threshold) {
      _loadMoreCampaigns();
    }
  }

  Future<void> _loadMoreCampaigns() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _apiService.getCampaigns(
        clientId: _selectedClientId,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: nextPage,
        perPage: 8,
      );

      final newCampaigns = result['campaigns'] as List<Campaign>;

      setState(() {
        _currentPage = nextPage;
        _campaigns.addAll(newCampaigns);
        _filteredCampaigns = _campaigns;
        _hasMore = (result['has_more'] ?? false) as bool;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildCampaignCard(Campaign campaign) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Row(
          children: [
            // Logo de la campagne
            ClipOval(
              child: Image.network(
                _getCampaignImageUrl(campaign),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 56,
                    height: 56,
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.campaign_outlined,
                      color: AppTheme.accentBlue,
                    ),
                  );
                },
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

  Widget _buildCampaignGridCard(Campaign campaign) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampaignDetailScreen(campaign: campaign),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bandeau avec l'image de config + avatar circulaire de la campagne
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: Image.network(
                      _getConfigImageUrl(campaign),
                      fit: BoxFit.cover, // occupe toute la largeur du card
                      alignment: Alignment.topCenter, // on garde le haut de l'image
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.backgroundSecondary,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_outlined,
                            color: AppTheme.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppTheme.accentBlue.withOpacity(0.1),
                          backgroundImage:
                              NetworkImage(_getCampaignImageUrl(campaign)),
                          onBackgroundImageError:
                              (exception, stackTrace) {},
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingM,
                0,
                AppTheme.spacingM,
                AppTheme.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.nom,
                    style: AppTheme.heading3.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    campaign.clientName,
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    campaign.configName,
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
