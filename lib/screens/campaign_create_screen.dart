// lib/screens/campaign_create_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class CampaignCreateScreen extends StatefulWidget {
  const CampaignCreateScreen({super.key});

  @override
  State<CampaignCreateScreen> createState() => _CampaignCreateScreenState();
}

class _CampaignCreateScreenState extends State<CampaignCreateScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  // Étape 1 : Informations de base
  final TextEditingController _nomController = TextEditingController();
  int? _selectedClientId;
  int? _selectedConfigId;
  File? _selectedImage;
  
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
      final data = await _apiService.getClientContacts(clientId);
      
      setState(() {
        _clientContacts = List<Map<String, dynamic>>.from(data['contacts'] ?? []);
        _clientUsers = List<Map<String, dynamic>>.from(data['users'] ?? []);
        _selectedClientIntervenants = [];
        _selectedMiaIntervenants = [];
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
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _apiService.createCampaign(
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
            content: Text('Campagne créée avec succès !'),
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
          'Créer une campagne',
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
                  // Permettre de naviguer entre les étapes en cliquant dessus
                  setState(() {
                    _currentStep = step;
                  });
                },
                onStepContinue: () {
                  if (_currentStep == 0) {
                    if (_formKey.currentState!.validate() &&
                        _selectedClientId != null &&
                        _selectedConfigId != null) {
                      // Charger les contacts du client
                      _loadClientContacts(_selectedClientId!);
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
                            backgroundColor: Colors.blue[700],
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
                              : Text(_currentStep == 1 ? 'Créer' : 'Suivant'),
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
                  // Étape 1 : Informations de base
                  Step(
                    title: const Text('Informations de base'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nom de la campagne
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
                        
                        // Client
                        DropdownButtonFormField<int>(
                          value: _selectedClientId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Client *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: _clients.map((client) {
                            return DropdownMenuItem<int>(
                              value: client['id'] as int,
                              child: Text(
                                client['name'] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        
                        // Configuration
                        DropdownButtonFormField<int>(
                          value: _selectedConfigId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Configuration *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.settings),
                          ),
                          items: _configs.map((config) {
                            return DropdownMenuItem<int>(
                              value: config['id'] as int,
                              child: Text(
                                config['name'] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        
                        // Image de la campagne
                        Text(
                          'Image de la campagne (optionnel)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (_selectedImage != null) ...[
                          // Afficher l'aperçu de l'image
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
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
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
                          // Bouton pour sélectionner une image
                          InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade50,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Ajouter une image',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap pour sélectionner',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Étape 2 : Intervenants
                  Step(
                    title: const Text('Intervenants'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Intervenants MIA
                        if (_clientUsers.isNotEmpty) ...[
                          Text(
                            'Intervenants MIA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
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
                        
                        // Intervenants Client
                        if (_clientContacts.isNotEmpty) ...[
                          Text(
                            'Intervenants Client',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
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
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun intervenant disponible',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
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
