// lib/screens/campaign_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/campaign_detail.dart';
import '../services/api_service.dart';
import '../widgets/campaign_field_widget.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  CampaignDetail? _campaignDetail;
  bool _isLoading = true;
  String? _error;
  
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _loadCampaignDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaignDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final detail = await _apiService.getCampaignDetail(widget.campaign.id);

      setState(() {
        _campaignDetail = detail;
        _isLoading = false;
        
        // Initialiser les controllers après avoir chargé les données
        _tabController = TabController(
          length: detail.tabs.length,
          vsync: this,
        );
        _pageController = PageController();
        
        // Synchroniser TabController et PageController
        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            _pageController.animateToPage(
              _tabController.index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          // Rebuild pour mettre à jour l'état des boutons
          if (mounted) {
            setState(() {});
          }
        });
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _goToNextTab() {
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.campaign.nom,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: _campaignDetail != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: _campaignDetail!.tabs
                    .map((tab) => Tab(text: tab.nom))
                    .toList(),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erreur: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCampaignDetail,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _campaignDetail == null
                  ? const Center(child: Text('Aucune donnée disponible'))
                  : Column(
                      children: [
                        // Contenu des onglets avec swipe
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _campaignDetail!.tabs.length,
                            onPageChanged: (index) {
                              _tabController.animateTo(index);
                            },
                            itemBuilder: (context, index) {
                              final tab = _campaignDetail!.tabs[index];
                              return _buildTabContent(tab);
                            },
                          ),
                        ),
                        
                        // Boutons de navigation
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Bouton Précédent
                              ElevatedButton.icon(
                                onPressed: _tabController.index > 0
                                    ? _goToPreviousTab
                                    : null,
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Précédent'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                  disabledBackgroundColor: Colors.grey[200],
                                  disabledForegroundColor: Colors.grey[400],
                                ),
                              ),
                              
                              // Indicateur de position
                              Text(
                                '${_tabController.index + 1} / ${_campaignDetail!.tabs.length}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              // Bouton Suivant
                              ElevatedButton.icon(
                                onPressed: _tabController.index < _tabController.length - 1
                                    ? _goToNextTab
                                    : null,
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: const Text('Suivant'),
                                iconAlignment: IconAlignment.end,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[200],
                                  disabledForegroundColor: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildTabContent(CampaignTab tab) {
    if (tab.fields.isEmpty) {
      return const Center(
        child: Text(
          'Aucun champ dans cet onglet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tab.fields.length,
      itemBuilder: (context, index) {
        final field = tab.fields[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CampaignFieldWidget(field: field),
        );
      },
    );
  }
}
