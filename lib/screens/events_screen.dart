// lib/screens/events_screen.dart

import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  List<Event> _events = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadEvents();
    }
  }

  String get _currentTab {
    switch (_tabController.index) {
      case 0:
        return 'events';
      case 1:
        return 'my_events';
      case 2:
        return 'events_arch';
      default:
        return 'events';
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventsData = await _apiService.getEvents(
        tab: _currentTab,
        search: _searchQuery,
      );

      setState(() {
        _events = eventsData.map((data) => Event.fromJson(data)).toList();
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
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Événements', style: AppTheme.heading2),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accentBlue,
          tabs: const [
            Tab(text: 'Événements'),
            Tab(text: 'Mes Événements'),
            Tab(text: 'Archivés'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: AppTheme.backgroundSecondary,
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher des événements...',
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
              ),
              onChanged: (_) => _performSearch(), // Recherche en direct
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          
          // Liste des événements
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            Text(
                              'Aucun événement trouvé',
                              style: AppTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return _buildEventCard(event);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre
            Text(
              event.name.toUpperCase(),
              style: AppTheme.heading3.copyWith(
                fontSize: 16,
                color: AppTheme.accentBlue,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Dates
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Créé le: ${event.createdAt ?? 'N/A'}',
                  style: AppTheme.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
            
            if (event.deadline != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.alarm, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Deadline: ${event.deadline}',
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 12,
                      color: event.deadlinePassed ? AppTheme.accentRed : AppTheme.accentGreen,
                      fontWeight: event.deadlinePassed ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
            
            // Créateur
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Créé par: ${event.creator.name}',
                  style: AppTheme.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
            
            // Utilisateurs affectés
            if (event.assignedUsers.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Affectés: ',
                    style: AppTheme.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: event.assignedUsers.map((user) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Text(
                      user.name,
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // Tags
            if (event.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: event.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _hexToColor(tag.color),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Text(
                      tag.name,
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return AppTheme.textSecondary;
    }
  }
}
