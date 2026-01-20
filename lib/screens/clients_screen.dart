// lib/screens/clients_screen.dart

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ApiService _apiService = ApiService();
  List<Client> _allClients = [];
  List<Client> _filteredClients = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
void initState() {
  super.initState();
  _loadClients();
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Charger les clients depuis l'API
  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clients = await _apiService.getClients();
      setState(() {
        _allClients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  // Filtrer les clients selon la recherche
  void _filterClients() {
  final query = _searchController.text.toLowerCase().trim();
  
  setState(() {
    if (query.isEmpty) {
      _filteredClients = _allClients;
    } else {
      _filteredClients = _allClients.where((client) {
        // Recherche dans raison sociale
        final matchRaison = client.raisonSociale.toLowerCase().contains(query);
        
        // Recherche dans email
        final matchEmail = client.email?.toLowerCase().contains(query) ?? false;
        
        // Recherche dans téléphone
        final matchTel = client.telephone?.toLowerCase().contains(query) ?? false;
        
        // Recherche dans type de client
        final matchType = client.clientType.name.toLowerCase().contains(query);
        
        // Recherche dans statut
        final matchStatus = client.status.name.toLowerCase().contains(query);
        
        // Recherche dans ville
        final matchVille = client.ville?.toLowerCase().contains(query) ?? false;
        
        // Debug : afficher ce qu'on cherche
        print('🔍 Recherche: "$query"');
        print('   Raison sociale: "${client.raisonSociale.toLowerCase()}" -> $matchRaison');
        print('   Type: "${client.clientType.name.toLowerCase()}" -> $matchType');
        print('   Statut: "${client.status.name.toLowerCase()}" -> $matchStatus');
        
        return matchRaison || matchEmail || matchTel || matchType || matchStatus || matchVille;
      }).toList();
      
      print('📊 Résultats: ${_filteredClients.length} client(s) trouvé(s)');
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Clients',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSearchBar(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: _buildBody(),
    );
  }

  // Barre de recherche
  Widget _buildSearchBar() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: _searchController,
      keyboardType: TextInputType.text, // ← AJOUTER CETTE LIGNE
      textInputAction: TextInputAction.search, // ← AJOUTER CETTE LIGNE
      onChanged: (value) {
        print('📝 Texte changé: "$value"');
        _filterClients();
      },
      decoration: InputDecoration(
        hintText: 'Rechercher un client...',
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _filterClients();
                },
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    ),
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
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erreur de connexion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadClients,
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

    // Affichage si aucun client
    if (_filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Aucun client trouvé'
                  : 'Aucun résultat pour "${_searchController.text}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Affichage de la liste des clients
    return RefreshIndicator(
      onRefresh: _loadClients,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredClients.length,
        itemBuilder: (context, index) {
          final client = _filteredClients[index];
          return _buildClientCard(client);
        },
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientDetailScreen(client: client),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Nom + Badge Statut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar/Icône
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hexToColor(client.status.color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        client.raisonSociale[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _hexToColor(client.status.color),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Nom et type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.raisonSociale,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.business, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              client.clientType.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge Statut
                  _buildStatusBadge(client.status),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Informations de contact (si disponibles)
              if (client.email != null || client.telephone != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      if (client.email != null)
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                client.email!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (client.email != null && client.telephone != null)
                        const SizedBox(height: 8),
                      if (client.telephone != null)
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              client.telephone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Statistiques
              Row(
                children: [
                  Expanded(child: _buildStat('Campagnes', client.campagnesCount, Icons.campaign, Colors.blue)),
                  Expanded(child: _buildStat('Contacts', client.contactsCount, Icons.contacts, Colors.green)),
                  Expanded(child: _buildStat('Suivis', client.suivisCount, Icons.track_changes, Colors.orange)),
                ],
              ),
              
              // Dernière activité et auteur
              if (client.lastActivity != null || client.lastAuthor != null)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (client.lastActivity != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _formatDate(client.lastActivity!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (client.lastAuthor != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    client.lastAuthor!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Status status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _hexToColor(status.color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Formater la date
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return "Aujourd'hui";
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  // Convertir une couleur hexadécimale en Color Flutter
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}