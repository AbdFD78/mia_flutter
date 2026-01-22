// lib/widgets/campaign_field_widget.dart

import 'package:flutter/material.dart';
import '../models/campaign_detail.dart';
import 'dart:convert';
import 'dart:async';

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

  const CampaignFieldWidget({
    super.key,
    required this.field,
  });

  @override
  State<CampaignFieldWidget> createState() => _CampaignFieldWidgetState();
}

class _CampaignFieldWidgetState extends State<CampaignFieldWidget> {
  CampaignField get field => widget.field;

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
      case 'newdocgenerator':
        return _buildDocumentField();
      
      case 'discussion':
        return _buildDiscussionField();
      
      case 'recapitulatif':
        return _buildRecapitulatifField();
      
      case 'tableauproduit':
        return _buildTableauProduitField();
      
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
    
    // Parser les valeurs sélectionnées (JSON array comme ["1","2"])
    List<String> selectedValues = [];
    if (field.value != null) {
      if (field.value is List) {
        selectedValues = (field.value as List).map((e) => e.toString()).toList();
      } else if (field.value is String) {
        try {
          final decoded = json.decode(field.value);
          if (decoded is List) {
            selectedValues = decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          selectedValues = [field.value.toString()];
        }
      }
    }
    
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
            final isChecked = selectedValues.contains(entry.key);
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
    
    // La valeur sélectionnée (string simple comme "2")
    final String? selectedValue = field.value?.toString();
    
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
            final isSelected = selectedValue == entry.key;
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
    
    // La valeur sélectionnée (string simple comme "3")
    final String? selectedValue = field.value?.toString();
    final String displayValue = selectedValue != null && availableOptions.containsKey(selectedValue)
        ? availableOptions[selectedValue]!
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
                      color: selectedValue != null ? Colors.black87 : Colors.grey,
                      fontWeight: selectedValue != null ? FontWeight.w500 : FontWeight.normal,
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
              final isSelected = selectedValue == entry.key;
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
    // Parser les URLs des médias
    List<String> mediaUrls = [];
    if (field.value != null) {
      if (field.value is List) {
        // Directement un array d'URLs depuis l'API
        mediaUrls = (field.value as List).map((e) => e.toString()).toList();
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
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Aucun média',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
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
                  child: GestureDetector(
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
          const SizedBox(height: 4),
          Text(
            'Type: ${field.type}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.orange,
              fontStyle: FontStyle.italic,
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
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
      ),
    );
  }
}
