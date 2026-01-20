// lib/screens/client_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/client.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  int _selectedTab = 0; // 0 = Suivis, 1 = Événements

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          client.raisonSociale,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec avatar et statut
            _buildHeader(context),
            
            const SizedBox(height: 16),
            
            // Statistiques
            _buildStatsSection(),
            
            const SizedBox(height: 16),
            
            // Informations de contact
            _buildContactSection(),
            
            const SizedBox(height: 16),
            
            // Section Suivis et Événements avec onglets
            _buildActivitiesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final client = widget.client;
    
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _hexToColor(client.status.color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                client.raisonSociale[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _hexToColor(client.status.color),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nom
          Text(
            client.raisonSociale,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Type et Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(
                      client.clientType.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _hexToColor(client.status.color),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  client.status.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final client = widget.client;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Campagnes', client.campagnesCount, Icons.campaign, Colors.blue),
          _buildStatCard('Contacts', client.contactsCount, Icons.contacts, Colors.green),
          _buildStatCard('Suivis', client.suivisCount, Icons.track_changes, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    final client = widget.client;
    
    if (client.email == null && client.telephone == null && 
        client.adresse == null && client.ville == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coordonnées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (client.email != null) ...[
            _buildInfoRow(Icons.email_outlined, 'Email', client.email!),
            const SizedBox(height: 12),
          ],
          if (client.telephone != null) ...[
            _buildInfoRow(Icons.phone_outlined, 'Téléphone', client.telephone!),
            const SizedBox(height: 12),
          ],
          if (client.adresse != null) ...[
            _buildInfoRow(Icons.location_on_outlined, 'Adresse', client.adresse!),
            const SizedBox(height: 12),
          ],
          if (client.ville != null && client.codepostal != null)
            _buildInfoRow(Icons.place_outlined, 'Ville', '${client.codepostal} ${client.ville}'),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    final client = widget.client;
    final suivisCount = client.suivis?.length ?? 0;
    final eventsCount = client.events?.length ?? 0;
    
    if (suivisCount == 0 && eventsCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Onglets
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildTab('Suivis du client', suivisCount, 0, const Color(0xFF007bff)),
                const SizedBox(width: 16),
                _buildTab('Événements', eventsCount, 1, const Color(0xFF28a745)),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Contenu selon l'onglet sélectionné
          Padding(
            padding: const EdgeInsets.all(20),
            child: _selectedTab == 0 
                ? _buildSuivisList()
                : _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int count, int tabIndex, Color color) {
    final isSelected = _selectedTab == tabIndex;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          '$title ($count)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSuivisList() {
    final client = widget.client;
    
    if (client.suivis == null || client.suivis!.isEmpty) {
      return const Center(
        child: Text(
          'Aucun suivi',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: client.suivis!.asMap().entries.map((entry) {
        final index = entry.key;
        final suivi = entry.value;
        return Column(
          children: [
            if (index > 0) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],
            _buildSuiviItem(suivi),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEventsList() {
    final client = widget.client;
    
    if (client.events == null || client.events!.isEmpty) {
      return const Center(
        child: Text(
          'Aucun événement',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: client.events!.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        return Column(
          children: [
            if (index > 0) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],
            _buildEventItem(event),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSuiviItem(Suivi suivi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec date et auteur
        Row(
          children: [
            const Icon(Icons.schedule, size: 18, color: Color(0xFF666666)),
            const SizedBox(width: 6),
            Text(
              _formatDate(suivi.createdAt),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007bff),
              ),
            ),
            const Spacer(),
            if (suivi.author != null)
              Row(
                children: [
                  Text(
                    suivi.author!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007bff),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'SUIVI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Intitulé
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Intitulé :',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                suivi.metaKey,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Texte
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Texte :',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                suivi.metaValue,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventItem(ClientEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec date et auteur
        Row(
          children: [
            const Icon(Icons.schedule, size: 18, color: Color(0xFF666666)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                event.createdAt != null ? _formatDate(event.createdAt!) : 'N/A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF28a745),
                ),
              ),
            ),
            if (event.author != null)
              Row(
                children: [
                  Text(
                    event.author!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28a745),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'ÉVÉNEMENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Nom de l'événement
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nom de l\'événement :',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                event.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Description
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description :',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                event.description ?? '/',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}