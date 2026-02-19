// lib/widgets/campaign_field_widget.dart

import 'package:flutter/material.dart';
import '../models/campaign_detail.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import '../config/app_config.dart';
import '../screens/pdf_viewer_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';

// Cache global pour stocker l'état de chargement des images
class _ImageCache {
  static final _ImageCache _instance = _ImageCache._internal();
  factory _ImageCache() => _instance;
  _ImageCache._internal();

  final Map<String, bool> _loadedImages = {};
  final Map<String, bool> _failedImages = {};

  bool isLoaded(String url) => _loadedImages[url] ?? false;
  bool hasFailed(String url) => _failedImages[url] ?? false;
  
  void markAsLoaded(String url) {
    _loadedImages[url] = true;
    _failedImages.remove(url);
  }
  
  void markAsFailed(String url) {
    _failedImages[url] = true;
  }
  
  void clear() {
    _loadedImages.clear();
    _failedImages.clear();
  }
}

// File d'attente globale pour charger les images une par une
class _ImageLoadQueue {
  static final _ImageLoadQueue _instance = _ImageLoadQueue._internal();
  factory _ImageLoadQueue() => _instance;
  _ImageLoadQueue._internal();

  final List<Completer<void>> _queue = [];
  bool _isProcessing = false;

  Future<void> acquireLock() async {
    final completer = Completer<void>();
    _queue.add(completer);
    
    if (!_isProcessing) {
      _processQueue();
    }
    
    return completer.future;
  }

  void releaseLock() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0);
    }
    
    // Délai de 3 secondes entre chaque image pour laisser respirer le serveur PHP
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (_queue.isNotEmpty) {
        _processQueue();
      } else {
        _isProcessing = false;
      }
    });
  }

  void _processQueue() {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }
    
    _isProcessing = true;
    _queue.first.complete();
  }
}

class CampaignFieldWidget extends StatefulWidget {
  final CampaignField field;
  final int campaignId;
  final String tabTag;
  final VoidCallback? onRefreshRequested;

  const CampaignFieldWidget({
    super.key,
    required this.field,
    required this.campaignId,
    required this.tabTag,
    this.onRefreshRequested,
  });

  @override
  State<CampaignFieldWidget> createState() => _CampaignFieldWidgetState();
}

class _CampaignFieldWidgetState extends State<CampaignFieldWidget> {
  CampaignField get field => widget.field;
  final ApiService _apiService = ApiService();

  // Cache des lignes produits éditables pour les champs newdocgenerator
  static final Map<String, List<Map<String, dynamic>>> _newDocLinesCache = {};

  @override
  Widget build(BuildContext context) {
    switch (field.type.toLowerCase()) {
      case 'title':
      case 'titre':
        return _buildTitleField();
      
      case 'text':
      case 'texte':
        return _buildTextField();
      
      case 'number':
        return _buildNumberField();
      
      case 'textarea':
      case 'text-area':
        return _buildTextAreaField();
      
      case 'checkbox':
        return _buildCheckboxField();
      
      case 'radio':
        return _buildRadioField();
      
      case 'selectfield':
      case 'select-field':
        return _buildSelectField();
      
      case 'mediauploader':
      case 'media-uploader':
      case 'media':
        return _buildMediaField();
      
      case 'document':
        return _buildDocumentField();

      case 'newdocgenerator':
        return _buildNewDocGeneratorField();
      
      case 'discussion':
        return _buildDiscussionField();
      
      case 'recapitulatif':
        return _buildRecapitulatifField();
      
      case 'tableauproduit':
        // Sur mobile, on masque complètement les tableaux produits,
        // comme demandé (gestion détaillée uniquement sur la version web).
        return const SizedBox.shrink();
      
      case 'suivie-client':
        return _buildSuivieClientField();
      
      default:
        return _buildDefaultField();
    }
  }

  Widget _buildTitleField() {
    // Le texte du titre vient de field.value (qui contient options['value'])
    final String titleText = field.value?.toString() ?? field.label;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF66615B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        titleText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            field.value?.toString() ?? '/',
            style: TextStyle(
              fontSize: 15,
              color: field.value != null ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            field.value?.toString() ?? '0',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAreaField() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            field.value?.toString() ?? '/',
            style: TextStyle(
              fontSize: 15,
              color: field.value != null ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxField() {
    // Parser les options disponibles
    final Map<String, dynamic> options = field.options;
    final Map<String, String> availableOptions = {};
    
    // Les options sont stockées dans field.options (ex: {"1":"1","2":"2","3":"3"})
    if (options.isNotEmpty) {
      options.forEach((key, value) {
        if (key != 'label' && key != 'required' && value is String) {
          availableOptions[key] = value;
        }
      });
    }
    
    // Parser les valeurs sélectionnées - gérer différents formats (List, JSON string, string simple)
    List<String> selectedValues = [];
    if (field.value != null) {
      if (field.value is List) {
        selectedValues = (field.value as List).map((e) => e.toString().trim()).toList();
      } else if (field.value is String) {
        try {
          final decoded = json.decode(field.value as String);
          if (decoded is List) {
            selectedValues = decoded.map((e) => e.toString().trim()).toList();
          } else {
            // Si c'est un objet ou autre, convertir en liste
            selectedValues = [decoded.toString().trim()];
          }
        } catch (e) {
          // Ce n'est pas du JSON, traiter comme une valeur unique
          final valueStr = field.value.toString().trim();
          if (valueStr.isNotEmpty) {
            selectedValues = [valueStr];
          }
        }
      } else {
        // Pour int, double, etc.
        selectedValues = [field.value.toString().trim()];
      }
    }
    
    // Normaliser les valeurs sélectionnées
    selectedValues = selectedValues.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
    
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...availableOptions.entries.map((entry) {
            // Comparaison flexible : par clé exacte, clé normalisée, ou valeur
            final normalizedKey = entry.key.trim();
            final normalizedValue = entry.value.trim();
            final isChecked = selectedValues.any((selected) {
              final normalizedSelected = selected.trim();
              return normalizedSelected == normalizedKey || 
                     normalizedSelected == normalizedValue ||
                     normalizedSelected == entry.key ||
                     normalizedSelected == entry.value;
            });
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isChecked ? Colors.blue : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 15,
                        color: isChecked ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRadioField() {
    // Parser les options disponibles
    final Map<String, dynamic> options = field.options;
    final Map<String, String> availableOptions = {};
    
    // Les options sont stockées dans field.options (ex: {"1":"1","2":"2","3":"3"})
    if (options.isNotEmpty) {
      options.forEach((key, value) {
        if (key != 'label' && key != 'required' && value is String) {
          availableOptions[key] = value;
        }
      });
    }
    
    // La valeur sélectionnée - gérer différents formats (string, int, JSON)
    String? selectedValue;
    if (field.value != null) {
      if (field.value is String) {
        // Essayer de parser si c'est un JSON
        try {
          final decoded = json.decode(field.value as String);
          if (decoded is List && decoded.isNotEmpty) {
            selectedValue = decoded.first.toString();
          } else if (decoded is Map) {
            // Si c'est un objet, prendre la première valeur
            selectedValue = decoded.values.first?.toString();
          } else {
            selectedValue = decoded.toString();
          }
        } catch (e) {
          // Ce n'est pas du JSON, utiliser directement
          selectedValue = field.value.toString().trim();
        }
      } else {
        // Pour int, double, etc.
        selectedValue = field.value.toString().trim();
      }
    }
    
    // Normaliser la clé pour la comparaison
    final String? normalizedSelectedValue = selectedValue?.trim();
    
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...availableOptions.entries.map((entry) {
            // Comparaison flexible : par clé exacte, clé normalisée, ou valeur
            final normalizedKey = entry.key.trim();
            final normalizedValue = entry.value.trim();
            final isSelected = normalizedSelectedValue != null && (
              normalizedSelectedValue == normalizedKey || 
              normalizedSelectedValue == normalizedValue ||
              normalizedSelectedValue == entry.key ||
              normalizedSelectedValue == entry.value
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSelectField() {
    // Parser les options disponibles
    final Map<String, dynamic> options = field.options;
    final Map<String, String> availableOptions = {};
    
    // Les options sont stockées dans field.options (ex: {"1":"1","2":"2","3":"3"})
    if (options.isNotEmpty) {
      options.forEach((key, value) {
        if (key != 'label' && key != 'required' && value is String) {
          availableOptions[key] = value;
        }
      });
    }
    
    // La valeur sélectionnée - gérer différents formats (string, int, JSON)
    String? selectedValue;
    if (field.value != null) {
      if (field.value is String) {
        // Essayer de parser si c'est un JSON
        try {
          final decoded = json.decode(field.value as String);
          if (decoded is List && decoded.isNotEmpty) {
            selectedValue = decoded.first.toString();
          } else if (decoded is Map) {
            // Si c'est un objet, prendre la première valeur
            selectedValue = decoded.values.first?.toString();
          } else {
            selectedValue = decoded.toString();
          }
        } catch (e) {
          // Ce n'est pas du JSON, utiliser directement
          selectedValue = field.value.toString().trim();
        }
      } else {
        // Pour int, double, etc.
        selectedValue = field.value.toString().trim();
      }
    }
    
    // Normaliser la clé pour la comparaison (enlever les espaces)
    final String? normalizedSelectedValue = selectedValue?.trim();
    
    // Chercher la valeur dans les options (comparaison flexible)
    String? matchedKey;
    if (normalizedSelectedValue != null) {
      // Essayer une correspondance exacte
      if (availableOptions.containsKey(normalizedSelectedValue)) {
        matchedKey = normalizedSelectedValue;
      } else {
        // Essayer de trouver par valeur (si la clé ne correspond pas)
        for (var entry in availableOptions.entries) {
          if (entry.key.trim() == normalizedSelectedValue || 
              entry.value.trim() == normalizedSelectedValue) {
            matchedKey = entry.key;
            break;
          }
        }
      }
    }
    
    final String displayValue = matchedKey != null && availableOptions.containsKey(matchedKey)
        ? availableOptions[matchedKey]!
        : 'Aucune sélection';
    
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_drop_down, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 15,
                      color: matchedKey != null ? Colors.black87 : Colors.grey,
                      fontWeight: matchedKey != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Afficher toutes les options disponibles en dessous
          if (availableOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Options disponibles :',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            ...availableOptions.entries.map((entry) {
              final isSelected = matchedKey != null && (matchedKey == entry.key || normalizedSelectedValue == entry.key);
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: isSelected ? Colors.blue : Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.blue[700] : Colors.grey[600],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaField() {
    // Parser les données des médias
    List<String> mediaUrls = [];
    List<String>? mediaImageIds;
    if (field.value != null) {
      if (field.value is List) {
        final rawList = field.value as List;
        // Cas 1: API récente avec métadonnées dans options['_media_meta']
        if (field.options is Map && (field.options as Map).containsKey('_media_meta')) {
          final meta = (field.options as Map)['_media_meta'];
          if (meta is List) {
            mediaImageIds = meta
                .map((e) => (e is Map && e['image_id'] != null) ? e['image_id'].toString() : '')
                .cast<String>()
                .toList();
          }
        }
        // La valeur principale reste une liste d'URLs (compatibilité ascendante)
        mediaUrls = rawList.map((e) => e.toString()).toList();
      } else if (field.value is String) {
        try {
          // Essayer de parser comme JSON
          final decoded = json.decode(field.value);
          if (decoded is List) {
            mediaUrls = decoded.map((e) => e.toString()).toList();
          } else {
            mediaUrls = [field.value.toString()];
          }
        } catch (e) {
          // Si ce n'est pas du JSON, traiter comme une URL simple
          if (field.value.toString().isNotEmpty) {
            mediaUrls = [field.value.toString()];
          }
        }
      }
    }

    if (mediaUrls.isEmpty) {
      return _buildCardField(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'Aucun média',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _pickAndUploadMedia(context),
                    icon: const Icon(Icons.add_photo_alternate, size: 18),
                    label: const Text('Ajouter des médias'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _pickAndUploadDocument(context),
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: const Text('Joindre un fichier (PDF)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                field.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${mediaUrls.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate, size: 20),
                    tooltip: 'Ajouter des médias',
                    onPressed: () => _pickAndUploadMedia(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.attach_file, size: 20),
                    tooltip: 'Joindre un fichier (PDF)',
                    onPressed: () => _pickAndUploadDocument(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mediaUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Ouvrir le carrousel en plein écran
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _MediaCarouselScreen(
                                mediaUrls: mediaUrls,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _NetworkImageWithRetry(
                              url: mediaUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              cacheWidth: 80,
                              cacheHeight: 80,
                              index: index,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => _confirmAndDeleteMedia(context, index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentField() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.blue.shade700, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.value != null ? 'Document disponible' : 'Aucun document',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (field.value != null)
                        const Text(
                          'Tap pour télécharger',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (field.value != null)
                  Icon(Icons.download, color: Colors.blue.shade700),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Version enrichie pour le type newdocgenerator :
  /// - Dernier devis / facture
  /// - Historique
  /// - Lignes produits (lecture seule)
  Widget _buildNewDocGeneratorField() {
    // Normaliser la valeur :
    // - cas 1 : aucune valeur encore stockée -> structure vide
    // - cas 2 : déjà une Map structurée (API récente)
    // - cas 3 : ancienne valeur JSON brute (history de devis uniquement)
    Map<String, dynamic>? data;

    if (field.value == null) {
      data = {
        'latest_devis': null,
        'devis_history': <Map<String, dynamic>>[],
        'latest_facture': null,
        'facture_history': <Map<String, dynamic>>[],
        'product_lines': <Map<String, dynamic>>[],
      };
    } else if (field.value is Map<String, dynamic>) {
      data = field.value as Map<String, dynamic>;
    } else if (field.value is String) {
      try {
        final decoded = json.decode(field.value as String);
        if (decoded is Map<String, dynamic>) {
          // Ancien format : {"timestamp": {"pdf": "...", "num_devis": "..."}, ...}
          final rawMap = decoded;
          final devisHistory = <Map<String, dynamic>>[];
          rawMap.forEach((key, value) {
            if (value is Map) {
              final record = Map<String, dynamic>.from(value as Map);
              final pdfPath = record['pdf']?.toString();
              devisHistory.add({
                'timestamp': key.toString(),
                'num_devis': record['num_devis']?.toString(),
                'pdf_url': pdfPath != null
                    ? AppConfig.getResourceUrl(pdfPath)
                    : null,
              });
            }
          });

          Map<String, dynamic>? latestDevis;
          if (devisHistory.isNotEmpty) {
            latestDevis = devisHistory.lastWhere(
              (e) => e['pdf_url'] != null,
              orElse: () => devisHistory.last,
            );
          }

          data = {
            'latest_devis': latestDevis,
            'devis_history': devisHistory,
            'latest_facture': null,
            'facture_history': <Map<String, dynamic>>[],
            'product_lines': <Map<String, dynamic>>[],
          };
        }
      } catch (_) {
        // Si le JSON n'est pas valide, on retombera sur le rendu simple.
      }
    }

    if (data == null) {
      // Fallback sur l'ancien rendu si la valeur n'est pas exploitable
      return _buildDocumentField();
    }

    final String cacheKey =
        '${widget.campaignId}-${widget.tabTag}-${field.tag}';

    final Map<String, dynamic>? latestDevis =
        data['latest_devis'] is Map<String, dynamic>
            ? data['latest_devis'] as Map<String, dynamic>
            : null;
    final Map<String, dynamic>? latestFacture =
        data['latest_facture'] is Map<String, dynamic>
            ? data['latest_facture'] as Map<String, dynamic>
            : null;

    final List<Map<String, dynamic>> devisHistory =
        (data['devis_history'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final List<Map<String, dynamic>> factureHistory =
        (data['facture_history'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final List<Map<String, dynamic>> products =
        (data['products'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final Map<String, dynamic>? devisPreview =
        data['preview_devis'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['preview_devis'] as Map)
            : null;
    final bool hasDevisPreview = devisPreview != null;

    final Map<String, dynamic>? facturePreview =
        data['preview_facture'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['preview_facture'] as Map)
            : null;
    final bool hasFacturePreview = facturePreview != null;

    // Charger les lignes depuis l'API et mettre à jour le cache
    final apiLinesRaw = data['product_lines'] as List<dynamic>? ?? [];
    
    final apiLines = apiLinesRaw
        .map((e) {
          if (e is Map) {
            return Map<String, dynamic>.from(e);
          }
          return <String, dynamic>{};
        })
        .where((e) => e.isNotEmpty)
        .toList();
    
    // Toujours synchroniser le cache avec les données de l'API si elles sont présentes
    // Si l'API renvoie des lignes, on les utilise pour mettre à jour le cache
    if (apiLines.isNotEmpty) {
      // Si on a des données de l'API, toujours les utiliser pour mettre à jour le cache
      _newDocLinesCache[cacheKey] = List<Map<String, dynamic>>.from(apiLines);
    } else if (!_newDocLinesCache.containsKey(cacheKey)) {
      // Si l'API ne renvoie rien et que le cache n'existe pas, initialiser avec une liste vide
      _newDocLinesCache[cacheKey] = [];
    }
    // Si l'API renvoie une liste vide mais que le cache existe déjà avec des données,
    // on garde le cache (l'utilisateur pourrait être en train d'éditer)
    
    final productLines = _newDocLinesCache[cacheKey] ?? [];

    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag du champ
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Boutons de génération (utiliser Wrap pour éviter les overflows)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Le bouton "Générer un devis" est masqué dès qu'un devis est confirmé (généré)
              // On le masque si latestDevis existe (devis confirmé dans l'historique)
              if (latestDevis == null)
                IconButton.filled(
                  onPressed: () async {
                    if (!hasDevisPreview) {
                      final confirmed = await _confirmGenerateDevis(context);
                      if (confirmed == true) {
                        await _handleGenerateDevis();
                      }
                    } else {
                      await _showDevisBrouillonMenu(
                        context,
                        devisPreview,
                        latestDevis,
                      );
                    }
                  },
                  icon: const Icon(Icons.description_outlined),
                  tooltip:
                      'Générer un devis (vous ne pourrez plus le modifier ni en générer un autre)',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              // Le bouton "Générer une facture" est masqué si une facture est déjà confirmée
              // On le masque si latestFacture existe (facture confirmée dans l'historique)
              if (latestDevis != null && latestFacture == null)
                IconButton.filled(
                  onPressed: () async {
                    if (!hasFacturePreview) {
                      // Première fois : avertissement puis génération de l'aperçu facture
                      final confirmed = await _confirmGenerateFacture(context);
                      if (confirmed == true) {
                        await _apiService.generateNewDocFacturePreview(
                          campagneId: widget.campaignId,
                          tabTag: widget.tabTag,
                          formTag: field.tag,
                        );
                        if (widget.onRefreshRequested != null) {
                          widget.onRefreshRequested!();
                        }
                      }
                    } else {
                      // Brouillon existant : ouvrir le menu brouillon facture
                      await _showFactureBrouillonMenu(
                        context,
                        facturePreview,
                        latestFacture,
                      );
                    }
                  },
                  icon: const Icon(Icons.receipt_long),
                  tooltip: 'Générer une facture à partir du devis courant',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              // Bouton "Voir les produits" : masqué si facture confirmée
              if (latestFacture == null)
                IconButton.filled(
                  onPressed: () {
                    _openLinesEditor(context, cacheKey, products);
                  },
                  icon: const Icon(Icons.table_chart),
                  tooltip: 'Voir les produits',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Si facture confirmée : deux boutons simples "Voir le devis" et "Voir la facture"
          if (latestDevis != null && latestFacture != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdf(
                      context,
                      latestDevis['pdf_url'] as String,
                      'Devis ${latestDevis['num_devis'] ?? ''}',
                    ),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Voir le devis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdf(
                      context,
                      latestFacture['pdf_url'] as String,
                      'Facture ${latestFacture['num_facture'] ?? ''}',
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Voir la facture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else if (latestDevis != null) ...[
            // Dernier devis : affiché uniquement si facture non confirmée
            Row(
              children: [
                const Icon(Icons.description_outlined,
                    color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dernier devis : ${latestDevis['num_devis'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (latestDevis['pdf_url'] != null)
                  TextButton.icon(
                    onPressed: () => _openPdf(
                      context,
                      latestDevis['pdf_url'] as String,
                      'Devis ${latestDevis['num_devis'] ?? ''}',
                    ),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Voir'),
                  ),
                // Historique des devis : masqué si facture confirmée
                if (devisHistory.isNotEmpty && latestFacture == null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.history, size: 20),
                    tooltip: 'Historique des devis',
                    onSelected: (String? pdfUrl) {
                      if (pdfUrl != null) {
                        try {
                          final item = devisHistory.firstWhere(
                            (e) => e['pdf_url'] == pdfUrl,
                          );
                          _openPdf(
                            context,
                            pdfUrl,
                            'Devis ${item['num_devis'] ?? ''}',
                          );
                        } catch (_) {
                          // Si l'élément n'est pas trouvé, ouvrir quand même le PDF
                          _openPdf(context, pdfUrl, 'Devis');
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return devisHistory.map((item) {
                        final pdfUrl = item['pdf_url'] as String?;
                        return PopupMenuItem<String>(
                          value: pdfUrl,
                          enabled: pdfUrl != null,
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined,
                                  size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item['timestamp'] ?? ''} — ${item['num_devis'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: pdfUrl != null
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

        ],
      ),
    );
  }

  Widget _buildDiscussionField() {
    // Parser les données de discussion
    final Map<String, dynamic>? discussionData = field.value is Map 
        ? field.value as Map<String, dynamic> 
        : null;
    
    final List<dynamic> messages = discussionData?['messages'] ?? [];
    
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Discussion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Messages
          if (messages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.chat_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun message dans cette discussion',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index] as Map<String, dynamic>;
                  final isOwn = message['is_own'] == true;
                  final isDeleted = message['is_deleted'] == true;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isOwn 
                          ? MainAxisAlignment.end 
                          : MainAxisAlignment.start,
                      children: [
                        // Avatar à gauche pour les autres, à droite pour soi
                        if (!isOwn) ...[
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              message['author_picture'] ?? '',
                            ),
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        // Bulle de message
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isOwn 
                                ? CrossAxisAlignment.end 
                                : CrossAxisAlignment.start,
                            children: [
                              // Nom et date
                              Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                                child: Text(
                                  '${message['author_name']} • ${message['created_at']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              
                              // Message
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwn 
                                      ? Colors.blue 
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  isDeleted 
                                      ? 'Message supprimé' 
                                      : message['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isOwn ? Colors.white : Colors.black87,
                                    fontStyle: isDeleted 
                                        ? FontStyle.italic 
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Avatar à droite pour soi
                        if (isOwn) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              message['author_picture'] ?? '',
                            ),
                            backgroundColor: Colors.blue[100],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Note pour écriture (lecture seule en mobile)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Utilisez la version web pour envoyer des messages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapitulatifField() {
    // Parser les données du récapitulatif (groupées par onglet)
    final Map<String, dynamic>? recapData = field.value is Map 
        ? field.value as Map<String, dynamic> 
        : null;
    
    if (recapData == null || recapData.isEmpty) {
      return _buildCardField(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune donnée disponible',
                    style: TextStyle(
                      color: Colors.grey[600],
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
    
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              const Icon(Icons.summarize, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Récapitulatif',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Afficher les données groupées par onglet
          ...recapData.entries.map((ongletEntry) {
            final ongletName = ongletEntry.key;
            final champs = ongletEntry.value as Map<String, dynamic>?;
            
            if (champs == null || champs.isEmpty) return const SizedBox.shrink();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom de l'onglet
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ongletName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Champs de cet onglet
                ...champs.entries.map((champEntry) {
                  final champName = champEntry.key;
                  final champValue = champEntry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            champName[0].toUpperCase() + champName.substring(1),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            champValue?.toString() ?? 'Non renseigné',
                            style: TextStyle(
                              fontSize: 14,
                              color: champValue != null 
                                  ? Colors.black87 
                                  : Colors.grey[400],
                              fontStyle: champValue == null 
                                  ? FontStyle.italic 
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableauProduitField() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                field.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text(
                'Tableau de produits\nVoir sur la version web pour plus de détails',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuivieClientField() {
    // Parser les données du suivi client
    final Map<String, dynamic>? suivieData = field.value is Map 
        ? field.value as Map<String, dynamic> 
        : null;
    
    final List<dynamic> history = suivieData?['history'] ?? [];
    final String clientName = suivieData?['client_name'] ?? 'Client';
    
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec nom du client
          Row(
            children: [
              const Icon(Icons.history, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historique - $clientName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Liste de l'historique (suivis + events)
          if (history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun historique pour ce client',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...history.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value as Map<String, dynamic>;
              final bool isLast = index == history.length - 1;
              final String type = item['type'] ?? 'suivi';
              final bool isEvent = type == 'event';
              
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEvent ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEvent ? Colors.green.shade100 : Colors.blue.shade100,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge de type + Date
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isEvent ? Colors.green : Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEvent ? Icons.event : Icons.note,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isEvent ? 'ÉVÉNEMENT' : 'SUIVI',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.access_time, 
                                 size: 14, 
                                 color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item['created_at'] ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Intitulé (titre pour event, meta_key pour suivi)
                        if (item['intitule'] != null && item['intitule'].toString().isNotEmpty) ...[
                          Text(
                            item['intitule'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                        
                        // Texte/Description
                        if (item['texte'] != null && item['texte'].toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item['texte'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        
                        // Deadline (uniquement pour les events)
                        if (isEvent && item['deadline'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.flag, 
                                   size: 14, 
                                   color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Échéance: ${item['deadline']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Auteur
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline, 
                                 size: 14, 
                                 color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              item['user_name'] ?? 'Utilisateur inconnu',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 12),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildDefaultField() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            field.value?.toString() ?? '/',
            style: TextStyle(
              fontSize: 15,
              color: field.value != null ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardField({required Widget child}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  void _openPdf(BuildContext context, String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          url: url,
          title: title,
        ),
      ),
    );
  }

  Future<void> _handleGenerateDevis() async {
    try {
      // Nouveau flux: générer d'abord un devis en mode "aperçu" (brouillon),
      // aligné avec le comportement de la version web.
      await _apiService.generateNewDocDevisPreview(
        campagneId: widget.campaignId,
        tabTag: widget.tabTag,
        formTag: field.tag,
      );
      if (widget.onRefreshRequested != null) {
        widget.onRefreshRequested!();
      }
    } catch (e) {
      // On laisse la gestion fine des erreurs à plus tard
      // pour l'instant on log simplement.
      // ignore: avoid_print
      print('Erreur génération devis: $e');
    }
  }

  Future<void> _showDevisBrouillonMenu(
    BuildContext context,
    Map<String, dynamic>? devisPreview,
    Map<String, dynamic>? latestDevis,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        final String? previewUrl =
            devisPreview != null ? devisPreview['pdf_url'] as String? : null;
        final String previewTitle =
            'Devis ${devisPreview?['num_devis'] ?? latestDevis?['num_devis'] ?? ''}';

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Brouillon de devis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (previewUrl != null)
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Aperçu du devis'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openPdf(context, previewUrl, previewTitle);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Mettre à jour le devis'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _apiService.generateNewDocDevisPreview(
                    campagneId: widget.campaignId,
                    tabTag: widget.tabTag,
                    formTag: field.tag,
                  );
                  if (widget.onRefreshRequested != null) {
                    widget.onRefreshRequested!();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: const Text('Confirmer le devis'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _apiService.confirmNewDocDevisPreview(
                    campagneId: widget.campaignId,
                    tabTag: widget.tabTag,
                    formTag: field.tag,
                  );
                  if (widget.onRefreshRequested != null) {
                    widget.onRefreshRequested!();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Annuler le brouillon'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _apiService.cancelNewDocDevisPreview(
                    campagneId: widget.campaignId,
                    tabTag: widget.tabTag,
                    formTag: field.tag,
                  );
                  if (widget.onRefreshRequested != null) {
                    widget.onRefreshRequested!();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGenerateFacture() async {
    try {
      await _apiService.generateNewDocFacture(
        campagneId: widget.campaignId,
        tabTag: widget.tabTag,
        formTag: field.tag,
      );
      if (widget.onRefreshRequested != null) {
        widget.onRefreshRequested!();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur génération facture: $e');
    }
  }

  Future<void> _pickAndUploadMedia(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final bool isIOS = Platform.isIOS;

    // Sur iOS/iPad, éviter le bottom sheet qui peut faire figer l'app avec la caméra.
    // Utiliser un AlertDialog qui se ferme proprement avant d'ouvrir le sélecteur natif.
    final ImageSource? source = isIOS
        ? await showDialog<ImageSource>(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Ajouter des médias'),
                content: const Text('Choisir la source'),
                actions: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: const Text('Galerie'),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text('Appareil photo'),
                  ),
                ],
              );
            },
          )
        : await showModalBottomSheet<ImageSource>(
            context: context,
            builder: (BuildContext context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Galerie'),
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Appareil photo'),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ],
                ),
              );
            },
          );

    if (source == null) return;

    // Court délai pour laisser le dialogue se fermer avant d'ouvrir le sélecteur natif (évite bug au 1er clic sur iOS).
    final int delayMs = isIOS ? 400 : 300;
    await Future.delayed(Duration(milliseconds: delayMs));

    if (!context.mounted) return;

    try {
      List<File> files = [];

      if (source == ImageSource.camera) {
        final pickedFile = await picker.pickImage(source: ImageSource.camera);
        if (pickedFile != null) {
          files = [File(pickedFile.path)];
        }
      } else {
        // Galerie : laisser choisir entre photos et vidéos
        final String? mediaType = isIOS
            ? await showDialog<String>(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Type de média'),
                    content: const Text('Que souhaitez-vous ajouter ?'),
                    actions: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context, 'image'),
                        icon: const Icon(Icons.photo_library, size: 20),
                        label: const Text('Photos'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context, 'video'),
                        icon: const Icon(Icons.videocam, size: 20),
                        label: const Text('Vidéos'),
                      ),
                    ],
                  );
                },
              )
            : await showModalBottomSheet<String>(
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Photos'),
                          onTap: () => Navigator.pop(context, 'image'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.videocam),
                          title: const Text('Vidéos'),
                          onTap: () => Navigator.pop(context, 'video'),
                        ),
                      ],
                    ),
                  );
                },
              );

        if (mediaType == null) return;

        if (mediaType == 'image') {
          final pickedFiles = await picker.pickMultiImage();
          if (pickedFiles != null && pickedFiles.isNotEmpty) {
            files = pickedFiles.map((xFile) => File(xFile.path)).toList();
          }
        } else if (mediaType == 'video') {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.video,
            allowMultiple: true,
          );
          if (result != null && result.files.isNotEmpty) {
            files = result.files
                .where((f) => f.path != null)
                .map((f) => File(f.path!))
                .toList();
          }
        }
      }

      if (files.isEmpty) return;

      // Afficher un indicateur de chargement
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Uploader les fichiers
      await _apiService.uploadMedia(
        campagneId: widget.campaignId,
        tabTag: widget.tabTag,
        formTag: field.tag,
        mediaFiles: files,
      );

      // Fermer l'indicateur de chargement
      if (!context.mounted) return;
      Navigator.of(context).pop();

      // Afficher un message de succès
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Médias uploadés avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Rafraîchir les données
      if (widget.onRefreshRequested != null) {
        widget.onRefreshRequested!();
      }
    } catch (e) {
      // Fermer l'indicateur de chargement s'il est ouvert
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadDocument(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final files = result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();

      if (files.isEmpty) return;

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _apiService.uploadMedia(
        campagneId: widget.campaignId,
        tabTag: widget.tabTag,
        formTag: field.tag,
        mediaFiles: files,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fichiers PDF uploadés avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onRefreshRequested != null) {
        widget.onRefreshRequested!();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload du fichier: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteMedia(BuildContext context, int index) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Supprimer le média'),
          content: const Text('Voulez-vous vraiment supprimer ce média ? Cette action est définitive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _apiService.deleteMedia(
        campagneId: widget.campaignId,
        tabTag: widget.tabTag,
        formTag: field.tag,
        index: index,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Média supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onRefreshRequested != null) {
        widget.onRefreshRequested!();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression du média: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveProductLines(String cacheKey) async {
    try {
      final lines = _newDocLinesCache[cacheKey] ?? [];
      await _apiService.updateNewDocProductLines(
        campagneId: widget.campaignId,
        tabTag: widget.tabTag,
        formTag: field.tag,
        productLines: lines,
      );
      if (widget.onRefreshRequested != null) {
        widget.onRefreshRequested!();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur sauvegarde lignes produits: $e');
    }
  }

  void _recomputeLineTotals(String cacheKey, int index) {
    final line = _newDocLinesCache[cacheKey]![index];

    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
    }

    final double quantite = toDouble(line['quantite']);
    final double prixUnitaire = toDouble(line['prix_unitaire']);
    final double remise = toDouble(line['remise']);
    final double tva = toDouble(line['Tva'] ?? line['tva']);

    // Même formule que TableauProduit::calculateTotals
    double totalHt = (quantite * prixUnitaire) -
        (quantite * ((remise / 100) * prixUnitaire));
    double totalTva = (totalHt * tva) / 100;
    double totalTtc = totalHt + totalTva;

    if (totalHt.isNaN || totalHt.isInfinite) totalHt = 0;
    if (totalTva.isNaN || totalTva.isInfinite) totalTva = 0;
    if (totalTtc.isNaN || totalTtc.isInfinite) totalTtc = 0;

    _newDocLinesCache[cacheKey]![index]['TotalHt'] =
        double.parse(totalHt.toStringAsFixed(2));
    _newDocLinesCache[cacheKey]![index]['total_ht'] =
        double.parse(totalHt.toStringAsFixed(2));
    _newDocLinesCache[cacheKey]![index]['TotalTva'] =
        double.parse(totalTva.toStringAsFixed(2));
    _newDocLinesCache[cacheKey]![index]['total_tva'] =
        double.parse(totalTva.toStringAsFixed(2));
    _newDocLinesCache[cacheKey]![index]['TotalTtc'] =
        double.parse(totalTtc.toStringAsFixed(2));
    _newDocLinesCache[cacheKey]![index]['total_ttc'] =
        double.parse(totalTtc.toStringAsFixed(2));
  }

  // Convertir n'importe quelle valeur dynamique en double en toute sécurité
  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
  }

  Future<bool?> _confirmGenerateDevis(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Générer un devis'),
          content: const Text(
            'Vous êtes sur le point de générer un devis.\n\n'
            'Attention : une fois le devis généré, vous ne pourrez plus le modifier ni en générer un nouveau pour ce document.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmGenerateFacture(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Générer une facture'),
          content: const Text(
            'Attention : une fois la facture générée, vous ne pourrez plus modifier '
            'ou régénérer le devis associé.\n\n'
            'Voulez-vous continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFactureBrouillonMenu(
    BuildContext context,
    Map<String, dynamic>? facturePreview,
    Map<String, dynamic>? latestFacture,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        final String? previewUrl =
            facturePreview != null ? facturePreview['pdf_url'] as String? : null;
        final String title =
            'Facture ${facturePreview?['num_facture'] ?? latestFacture?['num_facture'] ?? ''}';

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Brouillon de facture',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (previewUrl != null)
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Aperçu de la facture'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openPdf(context, previewUrl, title);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Mettre à jour la facture'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _apiService.generateNewDocFacturePreview(
                    campagneId: widget.campaignId,
                    tabTag: widget.tabTag,
                    formTag: field.tag,
                  );
                  if (widget.onRefreshRequested != null) {
                    widget.onRefreshRequested!();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: const Text('Confirmer la facture'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _apiService.confirmNewDocFacturePreview(
                    campagneId: widget.campaignId,
                    tabTag: widget.tabTag,
                    formTag: field.tag,
                  );
                  if (widget.onRefreshRequested != null) {
                    widget.onRefreshRequested!();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Annuler le brouillon'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _apiService.cancelNewDocFacturePreview(
                    campagneId: widget.campaignId,
                    tabTag: widget.tabTag,
                    formTag: field.tag,
                  );
                  if (widget.onRefreshRequested != null) {
                    widget.onRefreshRequested!();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Calculer les totaux globaux (somme de toutes les lignes)
  Map<String, double> _calculateGlobalTotals(String cacheKey) {
    final lines = _newDocLinesCache[cacheKey] ?? [];
    double totalHt = 0;
    double totalTva = 0;
    double totalTtc = 0;

    for (var line in lines) {
      totalHt += _toDouble(line['TotalHt'] ?? line['total_ht']);
      totalTva += _toDouble(line['TotalTva'] ?? line['total_tva']);
      totalTtc += _toDouble(line['TotalTtc'] ?? line['total_ttc'] ?? line['TotalTTC']);
    }

    return {
      'total_ht': totalHt,
      'total_tva': totalTva,
      'total_ttc': totalTtc,
    };
  }

  // Ouvrir le popup d'édition d'une ligne
void _openLineEditor(
  BuildContext context,
  String cacheKey,
  int index,
  List<Map<String, dynamic>> products,
  StateSetter setModalState,
) {
  final line = _newDocLinesCache[cacheKey]![index];

  int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  // Controllers pour pré-remplir et mettre à jour visuellement les champs
  final titleController = TextEditingController(
    text: line['title']?.toString() ?? line['Titre']?.toString() ?? '',
  );
  final descController = TextEditingController(
    text: line['description']?.toString() ?? '',
  );
  final qteController = TextEditingController(
    text: line['quantite']?.toString() ?? '0',
  );
  final puController = TextEditingController(
    text: line['prix_unitaire']?.toString() ?? '0',
  );
  final remiseController = TextEditingController(
    text: line['remise']?.toString() ?? '0',
  );
  final tvaController = TextEditingController(
    text: line['Tva']?.toString() ?? line['tva']?.toString() ?? '0',
  );

  final initialProduitId = _parseId(line['produit_id']);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (editCtx) {
      return StatefulBuilder(
        builder: (context, setEditState) {
          final mediaQuery = MediaQuery.of(context);
          final isWide = mediaQuery.size.width >= 700;
          final maxWidth = isWide ? 720.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: mediaQuery.size.height * 0.8,
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.8,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                builder: (context, scrollController) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: mediaQuery.viewInsets.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Modifier la ligne',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(editCtx).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              DropdownButtonFormField<int>(
                                value: initialProduitId,
                                decoration: const InputDecoration(
                                  labelText: 'Produit',
                                  border: OutlineInputBorder(),
                                ),
                                items: products
                                    .map(
                                      (p) => DropdownMenuItem<int>(
                                        value: _parseId(p['id']),
                                        child: Text(
                                          (p['label'] ?? p['titre'] ?? '')
                                              .toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setEditState(() {
                                    _newDocLinesCache[cacheKey]![index]
                                        ['produit_id'] = value;
                                    final selected = products.firstWhere(
                                      (p) => p['id'] == value,
                                      orElse: () => {},
                                    );
                                    if (selected is Map &&
                                        selected.isNotEmpty) {
                                      final libelle = selected['titre'] ??
                                          selected['label'] ??
                                          '';
                                      // Mettre à jour le cache
                                      _newDocLinesCache[cacheKey]![index]
                                          ['title'] = libelle;
                                      _newDocLinesCache[cacheKey]![index]
                                          ['Titre'] = libelle;
                                      _newDocLinesCache[cacheKey]![index]
                                              ['description'] =
                                          selected['description'] ?? '';
                                      _newDocLinesCache[cacheKey]![index]
                                              ['prix_unitaire'] =
                                          selected['prix_unitaire'] ?? 0;
                                      _newDocLinesCache[cacheKey]![index]
                                              ['Tva'] =
                                          selected['tva'] ?? 0;
                                      _newDocLinesCache[cacheKey]![index]
                                              ['tva'] =
                                          selected['tva'] ?? 0;

                                      // Mettre à jour visuellement les champs
                                      titleController.text =
                                          libelle.toString();
                                      descController.text =
                                          (selected['description'] ?? '')
                                              .toString();
                                      puController.text =
                                          (selected['prix_unitaire'] ?? 0)
                                              .toString();
                                      tvaController.text =
                                          (selected['tva'] ?? 0).toString();

                                      _recomputeLineTotals(cacheKey, index);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Titre',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  setEditState(() {
                                    _newDocLinesCache[cacheKey]![index]
                                        ['title'] = val;
                                    _newDocLinesCache[cacheKey]![index]
                                        ['Titre'] = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: descController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                onChanged: (val) {
                                  setEditState(() {
                                    _newDocLinesCache[cacheKey]![index]
                                            ['description'] =
                                        val;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: qteController,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantité',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: (val) {
                                        setEditState(() {
                                          _newDocLinesCache[cacheKey]![index]
                                              ['quantite'] = val;
                                          _recomputeLineTotals(
                                              cacheKey, index);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: puController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prix unitaire',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: (val) {
                                        setEditState(() {
                                          _newDocLinesCache[cacheKey]![index]
                                              ['prix_unitaire'] = val;
                                          _recomputeLineTotals(
                                              cacheKey, index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: remiseController,
                                      decoration: const InputDecoration(
                                        labelText: 'Remise (%)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: (val) {
                                        setEditState(() {
                                          _newDocLinesCache[cacheKey]![index]
                                              ['remise'] = val;
                                          _recomputeLineTotals(
                                              cacheKey, index);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: tvaController,
                                      decoration: const InputDecoration(
                                        labelText: 'TVA (%)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: (val) {
                                        setEditState(() {
                                          _newDocLinesCache[cacheKey]![index]
                                              ['Tva'] = val;
                                          _newDocLinesCache[cacheKey]![index]
                                              ['tva'] = val;
                                          _recomputeLineTotals(
                                              cacheKey, index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  final currentLine =
                                      _newDocLinesCache[cacheKey]![index];
                                  final totalHt = (currentLine['TotalHt'] ??
                                          currentLine['total_ht'] ??
                                          0)
                                      .toDouble();
                                  final totalTva = (currentLine['TotalTva'] ??
                                          currentLine['total_tva'] ??
                                          0)
                                      .toDouble();
                                  final totalTtc =
                                      (currentLine['TotalTtc'] ??
                                              currentLine['total_ttc'] ??
                                              currentLine['TotalTTC'] ??
                                              0)
                                          .toDouble();

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'Total HT',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '${totalHt.toStringAsFixed(2)} €',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Total TVA',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '${totalTva.toStringAsFixed(2)} €',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Total TTC',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '${totalTtc.toStringAsFixed(2)} €',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(editCtx).pop();
                              setModalState(() {}); // Rafraîchir la liste
                            },
                            child: const Text('Enregistrer'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}

  void _openLinesEditor(
    BuildContext context, String cacheKey, List<Map<String, dynamic>> products) {
  // S'assurer que le cache existe avant d'ouvrir le modal
  if (!_newDocLinesCache.containsKey(cacheKey)) {
    _newDocLinesCache[cacheKey] = [];
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final lines = _newDocLinesCache[cacheKey] ?? [];
          final totals = _calculateGlobalTotals(cacheKey);

          final mediaQuery = MediaQuery.of(context);
          final isWide = mediaQuery.size.width >= 700;
          final maxWidth = isWide ? 720.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: mediaQuery.size.height * 0.8,
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        // Header avec titre et bouton fermer
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Voir les produits',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                        // Liste des lignes (drag & drop)
                        Expanded(
                          child: lines.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucune ligne de produit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Cliquez sur "Ajouter une ligne" pour commencer',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ReorderableListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: lines.length,
                                  buildDefaultDragHandles: false,
                                  onReorder: (oldIndex, newIndex) {
                                    setModalState(() {
                                      final list =
                                          _newDocLinesCache[cacheKey]!;
                                      if (newIndex > oldIndex) {
                                        newIndex -= 1;
                                      }
                                      final moved = list.removeAt(oldIndex);
                                      list.insert(newIndex, moved);
                                      // Met à jour le champ "order"
                                      for (var i = 0; i < list.length; i++) {
                                        list[i]['order'] = i;
                                      }
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final line = lines[index];
                                    final title = line['title']?.toString() ??
                                        line['Titre']?.toString() ??
                                        'Ligne ${index + 1}';
                                    final qte =
                                        (line['quantite'] ?? 0).toString();
                                    final pu =
                                        (line['prix_unitaire'] ?? 0).toString();
                                    final totalTtc = ((line['TotalTtc'] ??
                                                line['total_ttc'] ??
                                                line['TotalTTC'] ??
                                                0)
                                            .toDouble())
                                        .toStringAsFixed(2);

                                    return ReorderableDragStartListener(
                                      key: ValueKey(line['index'] ?? index),
                                      index: index,
                                      child: Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              // Zone texte + montant
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '$qte × ${double.tryParse(pu)?.toStringAsFixed(2) ?? pu} €',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          '$totalTtc €',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Boutons d'action à droite
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () {
                                                  _openLineEditor(
                                                    context,
                                                    cacheKey,
                                                    index,
                                                    products,
                                                    setModalState,
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () async {
                                                  final confirm =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (dialogCtx) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                            'Supprimer la ligne'),
                                                        content: const Text(
                                                            'Voulez-vous vraiment supprimer cette ligne de produit ?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        dialogCtx)
                                                                    .pop(false),
                                                            child: const Text(
                                                                'Annuler'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        dialogCtx)
                                                                    .pop(true),
                                                            child: const Text(
                                                              'Supprimer',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirm == true) {
                                                    setModalState(() {
                                                      final list =
                                                          _newDocLinesCache[
                                                              cacheKey]!;
                                                      list.removeAt(index);
                                                      for (var i = 0;
                                                          i < list.length;
                                                          i++) {
                                                        list[i]['order'] = i;
                                                      }
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Bouton Ajouter une ligne
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  final random = Random();
                                  final timestamp = DateTime.now()
                                      .millisecondsSinceEpoch;
                                  final randomPart =
                                      random.nextInt(1000000);
                                  final index =
                                      '${timestamp.toRadixString(36)}$randomPart';

                                  final list =
                                      _newDocLinesCache[cacheKey]!;
                                  final order = list.length;
                                  list.add({
                                    'index': index,
                                    'title': '',
                                    'description': '',
                                    'quantite': 0,
                                    'prix_unitaire': 0,
                                    'remise': 0,
                                    'TotalHt': 0,
                                    'Tva': 0,
                                    'TotalTtc': 0,
                                    'order': order,
                                  });
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ajouter une ligne',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Footer avec totaux et bouton Enregistrer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Totaux en readonly
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total TTC',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'HT: ${totals['total_ht']!.toStringAsFixed(2)} € | TVA: ${totals['total_tva']!.toStringAsFixed(2)} €',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${totals['total_ttc']!.toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Bouton Enregistrer
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await _handleSaveProductLines(cacheKey);
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                      }
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erreur lors de la sauvegarde: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.save, size: 20),
                                  label: const Text(
                                    'Enregistrer',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}
}

// Widget avec retry automatique et délai
class _NetworkImageWithRetry extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final int index;

  const _NetworkImageWithRetry({
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.index = 0,
  });

  @override
  State<_NetworkImageWithRetry> createState() => _NetworkImageWithRetryState();
}

class _NetworkImageWithRetryState extends State<_NetworkImageWithRetry> {
  int _retryCount = 0;
  String? _imageKey;
  bool _isRetrying = false;
  bool _shouldLoad = false;
  final _queue = _ImageLoadQueue();
  final _cache = _ImageCache();
  bool _hasAcquiredLock = false;

  @override
  void initState() {
    super.initState();
    
    // Si l'image est déjà en cache Flutter, la charger immédiatement
    if (_cache.isLoaded(widget.url)) {
      setState(() {
        _imageKey = widget.url;
        _shouldLoad = true;
      });
    } else if (!_cache.hasFailed(widget.url)) {
      // Délai initial pour laisser respirer le serveur
      Future.delayed(Duration(milliseconds: 1000 + (widget.index * 200)), () {
        if (mounted) _loadImage();
      });
    }
  }

  Future<void> _loadImage() async {
    if (_imageKey != null) return;
    
    // Si déjà en cache, charger directement sans passer par la queue
    if (_cache.isLoaded(widget.url)) {
      if (mounted) {
        setState(() {
          _imageKey = widget.url;
          _shouldLoad = true;
        });
      }
      return;
    }
    
    setState(() {
      _shouldLoad = true;
    });
    
    // Attendre notre tour dans la file d'attente seulement si pas en cache
    await _queue.acquireLock();
    _hasAcquiredLock = true;
    
    if (mounted) {
      setState(() {
        _imageKey = widget.url;
      });
    }
  }

  @override
  void dispose() {
    if (_hasAcquiredLock) {
      _hasAcquiredLock = false;
      _queue.releaseLock();
    }
    super.dispose();
  }

  Future<void> _retry() async {
    if (_retryCount >= 3 || _isRetrying || !mounted) return;
    
    if (!mounted) return;
    
    setState(() {
      _isRetrying = true;
    });
    
    // Attendre un peu avant de réessayer
    await Future.delayed(const Duration(milliseconds: 500));
    
    await _queue.acquireLock();
    _hasAcquiredLock = true;
    
    if (mounted) {
      setState(() {
        _imageKey = null;
        _shouldLoad = false;
      });
      
      // Relancer le chargement
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _loadImage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageKey == null && !_shouldLoad) {
      if (_cache.hasFailed(widget.url)) {
        return Container(
          color: Colors.red.shade50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: Colors.red.shade300,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'Failed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
      
      return GestureDetector(
        onTap: _loadImage,
        child: Container(
          color: Colors.blue.shade50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                color: Colors.blue.shade300,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Loading...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_imageKey == null && _shouldLoad) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Image.network(
      _imageKey!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          _cache.markAsLoaded(widget.url);
          
          if (_hasAcquiredLock) {
            _hasAcquiredLock = false;
            Future.microtask(() => _queue.releaseLock());
          }
          return child;
        }
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: Colors.blue,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Erreur miniature (tentative $_retryCount): ${widget.url}');
        
        if (_hasAcquiredLock) {
          _hasAcquiredLock = false;
          Future.microtask(() => _queue.releaseLock());
        }
        
        // Incrémenter immédiatement pour éviter les retries multiples
        if (_retryCount < 3 && mounted) {
          final currentRetry = _retryCount;
          _retryCount++;
          
          Future.delayed(Duration(seconds: 2 + (currentRetry * 2)), () {
            if (mounted) {
              _loadImage();
            }
          });
        } else if (_retryCount >= 3) {
          _cache.markAsFailed(widget.url);
        }
        
        return GestureDetector(
          onTap: _retryCount >= 3 ? null : _retry,
          child: Container(
            color: _retryCount < 3 ? Colors.orange.shade50 : Colors.red.shade50,
            child: _isRetrying
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _retryCount < 3 ? Icons.refresh : Icons.broken_image,
                        color: _retryCount < 3 ? Colors.orange.shade400 : Colors.red.shade300,
                        size: 28,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _retryCount < 3 ? 'Tap\nretry' : 'Failed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: _retryCount < 3 ? Colors.orange[800] : Colors.red[600],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// Widget pour une image plein écran avec retry
class _FullScreenImageWithRetry extends StatefulWidget {
  final String url;
  final int index;
  final int total;

  const _FullScreenImageWithRetry({
    required this.url,
    required this.index,
    required this.total,
  });

  @override
  State<_FullScreenImageWithRetry> createState() => _FullScreenImageWithRetryState();
}

class _FullScreenImageWithRetryState extends State<_FullScreenImageWithRetry> {
  int _retryCount = 0;
  String? _imageKey;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _imageKey = widget.url;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _retry() async {
    if (!mounted || _isRetrying || _retryCount >= 3) return;
    
    if (!mounted) return;
    setState(() {
      _isRetrying = true;
      _retryCount++;
    });
    
    await Future.delayed(Duration(milliseconds: 2000 * _retryCount));
    
    if (!mounted) return;
    setState(() {
      _imageKey = widget.url;
      _isRetrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_imageKey == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Image.network(
      _imageKey!,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Chargement...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Erreur image plein écran (tentative $_retryCount): ${widget.url}');
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isRetrying)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Icon(
                    _retryCount < 3 ? Icons.refresh : Icons.image_not_supported_outlined,
                    size: 80,
                    color: Colors.white54,
                  ),
                const SizedBox(height: 24),
                Text(
                  _isRetrying ? 'Nouvelle tentative...' : 'Image non disponible',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Image ${widget.index + 1} sur ${widget.total}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                if (!_isRetrying && _retryCount < 3) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
                if (_retryCount >= 3) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Fichier: ${widget.url.split('/').last}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget pour afficher le carrousel d'images en plein écran
class _MediaCarouselScreen extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const _MediaCarouselScreen({
    required this.mediaUrls,
    required this.initialIndex,
  });

  @override
  State<_MediaCarouselScreen> createState() => _MediaCarouselScreenState();
}

class _MediaCarouselScreenState extends State<_MediaCarouselScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final ApiService _apiService = ApiService();
  bool _loadingComments = false;
  bool _sendingComment = false;
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommentsForIndex(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _extractRelativeMediaPath(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path; // ex: /storage/uploads/media/xxx.jpg ou /api/media/uploads/media/xxx.jpg
      if (path.contains('/storage/')) {
        return path.split('/storage/').last;
      }
      if (path.contains('/media/')) {
        return path.split('/media/').last;
      }
      return path.startsWith('/') ? path.substring(1) : path;
    } catch (_) {
      // Fallback simple
      final idx = url.indexOf('/storage/');
      if (idx != -1) {
        return url.substring(idx + '/storage/'.length);
      }
      final idx2 = url.indexOf('/media/');
      if (idx2 != -1) {
        return url.substring(idx2 + '/media/'.length);
      }
      return url;
    }
  }

  String _imageIdForIndex(int index) {
    // Si l'API fournit déjà les image_ids dans options['_media_meta'], on les récupère via field.options
    try {
      final parent = context.findAncestorStateOfType<_CampaignFieldWidgetState>();
      if (parent != null) {
        final field = parent.field;
        if (field.options is Map && (field.options as Map).containsKey('_media_meta')) {
          final meta = (field.options as Map)['_media_meta'];
          if (meta is List && index < meta.length) {
            final item = meta[index];
            if (item is Map && item['image_id'] != null) {
              return item['image_id'].toString();
            }
          }
        }
      }
    } catch (_) {
      // Fallback silencieux sur le calcul local
    }

    // Fallback: recalcule l'imageId à partir de l'URL (ancienne logique)
    final url = widget.mediaUrls[index];
    final relativePath = _extractRelativeMediaPath(url);
    final bytes = utf8.encode(relativePath);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<void> _loadCommentsForIndex(int index) async {
    setState(() {
      _loadingComments = true;
    });
    try {
      final imageId = _imageIdForIndex(index);
      final comments = await _apiService.getMediaComments(imageId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loadingComments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingComments = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des commentaires: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sendingComment) return;

    setState(() {
      _sendingComment = true;
    });

    try {
      final imageId = _imageIdForIndex(_currentIndex);
      final comment = await _apiService.addMediaComment(
        imageId: imageId,
        message: text,
      );
      if (!mounted) return;
      setState(() {
        _comments = List<Map<String, dynamic>>.from(_comments)..add(comment);
        _sendingComment = false;
        _commentController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingComment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout du commentaire: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCommentsPanel() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commentaires',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loadingComments
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun commentaire',
                          style: TextStyle(
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final user = comment['user'] as Map<String, dynamic>? ?? {};
                          final name = user['name']?.toString() ?? 'Utilisateur';
                          final message = comment['message']?.toString() ?? '';
                          final createdAt = comment['created_at']?.toString() ?? '';
                          final picture = user['picture']?.toString();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blueGrey,
                                  backgroundImage: picture != null && picture.isNotEmpty
                                      ? NetworkImage(AppConfig.getResourceUrl(picture))
                                      : null,
                                  child: (picture == null || picture.isEmpty)
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (createdAt.isNotEmpty)
                                        Text(
                                          createdAt,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendingComment ? null : _sendComment,
                icon: _sendingComment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget pageView = PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _loadCommentsForIndex(index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: _FullScreenImageWithRetry(
                    url: widget.mediaUrls[index],
                    index: index,
                    total: widget.mediaUrls.length,
                  ),
                ),
              );
            },
          );

          if (constraints.maxWidth > 700) {
            // Grand écran : image à gauche, commentaires à droite
            return Row(
              children: [
                Expanded(child: pageView),
                SizedBox(
                  width: 320,
                  child: _buildCommentsPanel(),
                ),
              ],
            );
          } else {
            // Mobile : image en haut, commentaires en bas
            return Column(
              children: [
                Expanded(child: pageView),
                SizedBox(
                  height: 260,
                  child: _buildCommentsPanel(),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
