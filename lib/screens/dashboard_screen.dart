// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../services/push_notification_service.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;
  String _selectedDateFilter = 'this_month';
  String? _selectedUserFilter;
  
  @override
  void initState() {
    super.initState();
    _loadDashboard();
    // Initialiser le service de notifications push une fois que le Navigator est disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService().setContext(context);
      PushNotificationService().initialize();
    });
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dashboardService.getDashboard(
        dateFilter: _selectedDateFilter,
        userFilter: _selectedUserFilter,
      );
      
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeDateFilter(String? newFilter) {
    if (newFilter != null && newFilter != _selectedDateFilter) {
      setState(() {
        _selectedDateFilter = newFilter;
      });
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Dashboard', style: AppTheme.heading1),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildDashboardContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardData == null || _dashboardData!['data'] == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    final data = _dashboardData!['data'];
    final hasDashboard = data['has_dashboard'] ?? false;

    if (!hasDashboard) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Aucun dashboard configuré',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final dateRanges = data['date_ranges'] as Map<String, dynamic>? ?? {};
    final users = data['users'] as List<dynamic>? ?? [];
    final config = data['config'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtres
            _buildFilters(dateRanges, users),
            const SizedBox(height: 20),

            // Widgets du dashboard
            ...config.map((row) => _buildRow(row)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(Map<String, dynamic> dateRanges, List<dynamic> users) {
    return Column(
      children: [
        // Filtre de période
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF666666), size: 18),
              const SizedBox(width: 12),
              const Text(
                'Période:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedDateFilter,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: dateRanges.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: _changeDateFilter,
                ),
              ),
            ],
          ),
        ),
        
        // Filtre par utilisateur (si des utilisateurs existent)
        if (users.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF666666), size: 18),
                const SizedBox(width: 12),
                const Text(
                  'Utilisateur:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String?>(
                    value: _selectedUserFilter,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text(
                      'Tous',
                      style: TextStyle(fontSize: 14),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Tous les utilisateurs',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      ...users.map((user) {
                        return DropdownMenuItem<String?>(
                          value: user['id'].toString(),
                          child: Text(
                            user['name'].toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: _changeUserFilter,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _changeUserFilter(String? newFilter) {
    if (newFilter != _selectedUserFilter) {
      setState(() {
        _selectedUserFilter = newFilter;
      });
      _loadDashboard();
    }
  }

  Widget _buildRow(dynamic row) {
    final cols = row['cols'] as int? ?? 1;
    final cells = row['cells'] as List<dynamic>? ?? [];

    // Sur mobile, on affiche toujours en colonne pour plus de lisibilité
    // Sauf si c'est des stats (widget_category = 'stat') qu'on peut mettre sur 2 colonnes
    final nonNullCells = cells.where((cell) => cell != null).toList();
    
    if (nonNullCells.isEmpty) return const SizedBox.shrink();

    // Vérifier si ce sont tous des widgets de stats
    final areAllStats = nonNullCells.every((cell) => 
      cell['widget_category'] == 'stat'
    );

    if (areAllStats && nonNullCells.length > 1) {
      // Pour les stats, on utilise un GridView avec 2 colonnes
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: nonNullCells.length,
          itemBuilder: (context, index) {
            return _buildWidget(nonNullCells[index]);
          },
        ),
      );
    } else {
      // Pour les autres widgets (listes, graphiques), on affiche en colonne
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: nonNullCells.map((cell) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWidget(cell),
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildWidget(dynamic widget) {
    final category = widget['widget_category'] as String?;
    final type = widget['widget_type'] as String?;
    final data = widget['data'];

    if (category == 'stat') {
      return _buildStatCard(type, data);
    } else if (category == 'event_list') {
      return _buildEventList(type, data);
    } else if (category == 'graph') {
      return _buildGraphCard(type, data);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('Type non supporté: $category'),
    );
  }

  Widget _buildStatCard(String? type, dynamic data) {
    final value = data?.toString() ?? '0';
    final info = _getStatInfo(type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: info['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              info['icon'],
              color: info['color'],
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info['title'] ?? 'Statistique',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(String? type, dynamic data) {
    final info = _getEventListInfo(type);
    final events = data as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Icon(
                  Icons.event_note,
                  size: 20,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info['title'] ?? 'Événements',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                if (events.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DC7EA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      events.length.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DC7EA),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          events.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: Text(
                      'Aucun événement à afficher',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length > 3 ? 3 : events.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    return _buildEventItem(events[index], type);
                  },
                ),
          Divider(height: 1, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.refresh, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Mis à jour à ${DateFormat('HH:mm').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (events.length > 3)
                  Text(
                    '+${events.length - 3} autres',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(dynamic event, String? widgetType) {
    final name = event['name'] ?? 'Sans titre';
    final description = event['description'] ?? '';
    final deadline = event['deadline'];
    final createdAt = event['created_at'];

    final isDeadline = widgetType == 'deadlines_passees' || widgetType == 'deadlines_semaine';
    final dateToShow = isDeadline && deadline != null ? deadline : createdAt;
    
    DateTime? parsedDate;
    try {
      if (dateToShow != null) {
        parsedDate = DateTime.parse(dateToShow);
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }

    bool isPast = false;
    try {
      isPast = deadline != null && DateTime.parse(deadline).isBefore(DateTime.now());
    } catch (e) {
      // Ignorer les erreurs de parsing
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isPast ? Colors.red : const Color(0xFF1DC7EA),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (parsedDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isPast ? Colors.red : const Color(0xFF1DC7EA),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(parsedDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: isPast ? Colors.red : const Color(0xFF1DC7EA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description.length > 80
                  ? '${description.substring(0, 80)}...'
                  : description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGraphCard(String? type, dynamic data) {
    final info = _getGraphInfo(type);
    
    // Extraire les données du graphique
    final labels = (data?['labels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final values = (data?['data'] as List<dynamic>?)?.map((e) {
      if (e is num) return e.toDouble();
      if (e is String) return double.tryParse(e) ?? 0.0;
      return 0.0;
    }).toList() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                type == 'emails_line' ? Icons.show_chart : Icons.bar_chart,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info['title'] ?? 'Graphique',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: labels.isEmpty || values.isEmpty
                ? _buildEmptyGraph()
                : type == 'emails_line'
                    ? _buildLineChart(labels, values)
                    : _buildBarChart(labels, values, type),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGraph() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<String> labels, List<double> values) {
    var maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b);
    maxY = maxY == 0 ? 10.0 : maxY * 1.2; // Minimum de 10 si toutes les valeurs sont 0
    
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: labels.length > 10 ? (labels.length / 5).ceilToDouble() : 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (labels.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: values.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF66BB6A),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: values.length <= 10,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF66BB6A),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF66BB6A).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<String> labels, List<double> values, String? type) {
    var maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b);
    maxY = maxY == 0 ? 10.0 : maxY * 1.2; // Minimum de 10 si toutes les valeurs sont 0
    final color = type == 'campagnes_bar' 
        ? const Color(0xFFFFA726) 
        : const Color(0xFFEF5350);

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) return const SizedBox();
                  
                  // Afficher 1 label sur 2 si trop de données
                  if (labels.length > 10 && index % 2 != 0) {
                    return const SizedBox();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: values.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: color,
                  width: labels.length > 20 ? 8 : 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatInfo(String? type) {
    switch (type) {
      case 'campagnes_total':
      case 'campagnes_creees':
        return {
          'title': 'Campagnes totales',
          'icon': Icons.campaign,
          'color': const Color(0xFFFFA726),
        };
      case 'contacts_total':
        return {
          'title': 'Contacts totaux',
          'icon': Icons.people,
          'color': const Color(0xFF42A5F5),
        };
      case 'emails_envoyes':
        return {
          'title': 'Emails envoyés',
          'icon': Icons.email,
          'color': const Color(0xFF66BB6A),
        };
      case 'evenements_total':
        return {
          'title': 'Événements totaux',
          'icon': Icons.event,
          'color': const Color(0xFFEF5350),
        };
      case 'evenements_a_venir':
        return {
          'title': 'Événements à venir',
          'icon': Icons.event_available,
          'color': const Color(0xFF26C6DA),
        };
      case 'evenements_passes':
        return {
          'title': 'Événements passés',
          'icon': Icons.event_busy,
          'color': const Color(0xFF9E9E9E),
        };
      default:
        return {
          'title': type ?? 'Statistique',
          'icon': Icons.bar_chart,
          'color': const Color(0xFF5C6BC0),
        };
    }
  }

  Map<String, String> _getEventListInfo(String? type) {
    switch (type) {
      case 'evenements_jour':
        return {'title': 'Événements du jour'};
      case 'deadlines_passees':
        return {'title': 'Deadlines passées'};
      case 'deadlines_semaine':
        return {'title': 'Deadlines de la semaine'};
      default:
        return {'title': 'Événements'};
    }
  }

  Map<String, String> _getGraphInfo(String? type) {
    switch (type) {
      case 'emails_line':
        return {'title': 'Emails envoyés'};
      case 'campagnes_bar':
        return {'title': 'Campagnes par période'};
      case 'evenements_bar':
        return {'title': 'Événements par période'};
      default:
        return {'title': 'Graphique'};
    }
  }
}
