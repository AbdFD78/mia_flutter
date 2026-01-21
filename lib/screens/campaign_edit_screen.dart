// lib/screens/campaign_edit_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/campaign.dart';

class CampaignEditScreen extends StatefulWidget {
  final Campaign campaign;
  
  const CampaignEditScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<CampaignEditScreen> createState() => _CampaignEditScreenState();
}

class _CampaignEditScreenState extends State<CampaignEditScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  // Étape 1 : Informations de base
  late TextEditingController _nomController;
  int? _selectedClientId;
  int? _selectedConfigId;
  File? _selectedImage;
  String? _currentImageUrl;
  
  // Étape 2 : Intervenants
  List<int> _selectedMiaIntervenants = [];
  List<int> _selectedClientIntervenants = [];
  
  // Données
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _configs = [];
  List<Map<String, dynamic>> _clientContacts = [];
  List<Map<String, dynamic>> _clientUsers = [];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.campaign.nom);
    _selectedClientId = widget.campaign.clientId;
    _selectedConfigId = widget.campaign.configsId;
    _currentImageUrl = widget.campaign.picture;
    
    _loadCreateData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _loadCreateData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      final data = await _apiService.getCampaignCreateData();
      
      setState(() {
        _clients = List<Map<String, dynamic>>.from(data['clients'] ?? []);
        _configs = List<Map<String, dynamic>>.from(data['configs'] ?? []);
        _isLoadingData = false;
      });
      
      // Charger les intervenants actuels
      if (_selectedClientId != null) {
        await _loadClientContacts(_selectedClientId!);
      }
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadClientContacts(int clientId) async {
    try {
      // Passer le campagneId pour charger les intervenants existants
      final data = await _apiService.getClientContacts(clientId, campagneId: widget.campaign.id);
      
      setState(() {
        _clientContacts = List<Map<String, dynamic>>.from(data['contacts'] ?? []);
        _clientUsers = List<Map<String, dynamic>>.from(data['users'] ?? []);
        
        // Charger les intervenants existants
        _selectedMiaIntervenants = List<int>.from(data['current_mia_intervenants'] ?? []);
        _selectedClientIntervenants = List<int>.from(data['current_client_intervenants'] ?? []);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _apiService.updateCampaign(
        id: widget.campaign.id,
        nom: _nomController.text,
        clientId: _selectedClientId!,
        configId: _selectedConfigId!,
        miaIntervenants: _selectedMiaIntervenants,
        clientIntervenants: _selectedClientIntervenants,
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campagne modifiée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retour avec succès
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Modifier la campagne',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepTapped: (step) {
                  setState(() {
                    _currentStep = step;
                  });
                },
                onStepContinue: () {
                  if (_currentStep == 0) {
                    if (_formKey.currentState!.validate() &&
                        _selectedClientId != null &&
                        _selectedConfigId != null) {
                      if (_selectedClientId != widget.campaign.clientId) {
                        _loadClientContacts(_selectedClientId!);
                      }
                      setState(() {
                        _currentStep = 1;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir tous les champs requis'),
                        ),
                      );
                    }
                  } else if (_currentStep == 1) {
                    _submitForm();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep--;
                    });
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(_currentStep == 1 ? 'Enregistrer' : 'Suivant'),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _isLoading ? null : details.onStepCancel,
                            child: const Text('Précédent'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  // Étape 1 : Informations de base (même structure que create)
                  Step(
                    title: const Text('Informations'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nom, Client, Config (identique à create_screen)
                        TextFormField(
                          controller: _nomController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de la campagne *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.campaign),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le nom est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<int>(
                          value: _selectedClientId,
                          decoration: const InputDecoration(
                            labelText: 'Client *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: _clients.map((client) {
                            return DropdownMenuItem<int>(
                              value: client['id'] as int,
                              child: Text(client['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClientId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un client';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<int>(
                          value: _selectedConfigId,
                          decoration: const InputDecoration(
                            labelText: 'Configuration *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.settings),
                          ),
                          items: _configs.map((config) {
                            return DropdownMenuItem<int>(
                              value: config['id'] as int,
                              child: Text(config['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedConfigId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner une configuration';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Gestion de l'image (identique à create_screen)
                        Text(
                          'Image de la campagne (optionnel)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (_selectedImage != null || _currentImageUrl != null) ...[
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _selectedImage != null
                                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                      : Image.network(
                                          'http://10.0.2.2:8000/${_currentImageUrl!}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(child: Icon(Icons.broken_image, size: 48));
                                          },
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: _removeImage,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.8),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.close, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.edit),
                              label: const Text('Changer l\'image'),
                            ),
                          ),
                        ] else ...[
                          InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade50,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('Ajouter une image', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Étape 2 : Intervenants (identique à create_screen)
                  Step(
                    title: const Text('Intervenants'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_clientUsers.isNotEmpty) ...[
                          Text('Intervenants MIA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                          const SizedBox(height: 8),
                          ..._clientUsers.map((user) {
                            final userId = user['id'] as int;
                            final isSelected = _selectedMiaIntervenants.contains(userId);
                            return CheckboxListTile(
                              title: Text(user['name'] as String),
                              subtitle: Text(user['email'] as String),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedMiaIntervenants.add(userId);
                                  } else {
                                    _selectedMiaIntervenants.remove(userId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                        ],
                        
                        if (_clientContacts.isNotEmpty) ...[
                          Text('Intervenants Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                          const SizedBox(height: 8),
                          ..._clientContacts.map((contact) {
                            final contactId = contact['id'] as int;
                            final isSelected = _selectedClientIntervenants.contains(contactId);
                            return CheckboxListTile(
                              title: Text(contact['name'] as String),
                              subtitle: Text(contact['email'] as String),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedClientIntervenants.add(contactId);
                                  } else {
                                    _selectedClientIntervenants.remove(contactId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ],
                        
                        if (_clientUsers.isEmpty && _clientContacts.isEmpty) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('Aucun intervenant disponible', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
