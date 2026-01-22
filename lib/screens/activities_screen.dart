// lib/screens/activities_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final ApiService _apiService = ApiService();
  
  List<Activity> _activities = [];
  List<Map<String, dynamic>> _authors = [];
  List<Map<String, dynamic>> _clients = [];
  
  bool _isLoading = false;
  bool _isLoadingFilters = false;
  
  // Filtres
  String _selectedType = 'all'; // 'all', 'suivie', 'event'
  String? _selectedAuthorId;
  String? _selectedClientId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    setState(() {
      _isLoadingFilters = true;
    });

    try {
      final authors = await _apiService.getActivityAuthors();
      final clients = await _apiService.getActivityClients();

      if (mounted) {
        setState(() {
          _authors = authors;
          _clients = clients;
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFilters = false;
        });
      }
      print('Erreur lors du chargement des filtres: $e');
    }
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activitiesData = await _apiService.getActivities(
        type: _selectedType,
        authorId: _selectedAuthorId,
        clientId: _selectedClientId,
        dateFrom: _dateFrom != null ? DateFormat('yyyy-MM-dd').format(_dateFrom!) : null,
        dateTo: _dateTo != null ? DateFormat('yyyy-MM-dd').format(_dateTo!) : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _activities = activitiesData.map((data) => Activity.fromJson(data)).toList();
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

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadActivities();
  }

  void _resetFilters() {
    setState(() {
      _selectedType = 'all';
      _selectedAuthorId = null;
      _selectedClientId = null;
      _dateFrom = null;
      _dateTo = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadActivities();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
      _loadActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Suivies Clients',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Section filtres
          _buildFiltersSection(),
          
          // Liste des activités
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Aucune activité trouvée pour "${_searchQuery}"'
                                  : 'Aucune activité trouvée',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadActivities,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) {
                            final activity = _activities[index];
                            return _buildActivityCard(activity);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Première ligne : Type et Auteur
            Row(
              children: [
                Expanded(
                  child: _buildTypeFilter(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAuthorFilter(),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Deuxième ligne : Client et bouton reset
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildClientFilter(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetFilters,
                  tooltip: 'Réinitialiser',
                  color: Colors.grey[700],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Troisième ligne : dates
            Row(
              children: [
                Expanded(
                  child: _buildDateFilter(true), // Date début
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateFilter(false), // Date fin
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher dans toutes les colonnes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => _performSearch(),
              onSubmitted: (_) => _performSearch(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Tous')),
        DropdownMenuItem(value: 'suivie', child: Text('Suivis clients')),
        DropdownMenuItem(value: 'event', child: Text('Événements')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedType = value ?? 'all';
        });
        _loadActivities();
      },
    );
  }

  Widget _buildAuthorFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedAuthorId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Auteur',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Tous les auteurs'),
        ),
        ..._authors.map((author) => DropdownMenuItem<String>(
              value: author['id'].toString(),
              child: Text(author['name'] ?? ''),
            )),
      ],
      onChanged: (value) {
        setState(() {
          _selectedAuthorId = value;
        });
        _loadActivities();
      },
    );
  }

  Widget _buildClientFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedClientId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Client',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Tous les clients'),
        ),
        ..._clients.map((client) => DropdownMenuItem<String>(
              value: client['id'].toString(),
              child: Text(client['raison_sociale'] ?? ''),
            )),
      ],
      onChanged: (value) {
        setState(() {
          _selectedClientId = value;
        });
        _loadActivities();
      },
    );
  }

  Widget _buildDateFilter(bool isFrom) {
    return InkWell(
      onTap: () => _selectDate(context, isFrom),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isFrom ? 'Date de début' : 'Date de fin',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          isFrom
              ? (_dateFrom != null
                  ? DateFormat('dd/MM/yyyy').format(_dateFrom!)
                  : 'Sélectionner')
              : (_dateTo != null
                  ? DateFormat('dd/MM/yyyy').format(_dateTo!)
                  : 'Sélectionner'),
          style: TextStyle(
            color: (isFrom ? _dateFrom : _dateTo) != null
                ? Colors.black87
                : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final isSuivie = activity.type == 'suivie';
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSuivie ? Colors.blue.shade300 : Colors.green.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSuivie ? Colors.blue[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activity.typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSuivie ? Colors.blue[900] : Colors.green[900],
                    ),
                  ),
                ),
                const Spacer(),
                if (activity.createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(activity.createdAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Client
            Row(
              children: [
                Icon(Icons.business, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activity.clientName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Auteur
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  activity.authorName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            
            if (activity.title != null && activity.title!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                activity.title!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
            
            if (activity.content != null && activity.content!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                activity.content!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
