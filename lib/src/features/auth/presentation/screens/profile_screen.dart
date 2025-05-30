import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Assuming provider for state management & service access

import '../../../../shared/widgets/button_custom.dart';
import '../../../../services/image_upload_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  String? _photoURL;
  String? _errorMessage;

  late ImageUploadService _imageUploadService;

  @override
  void initState() {
    super.initState();
    // Ideally, get the service via Provider
    _imageUploadService = ImageUploadService(); 
    _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If using Provider, get the service here instead of initState
    // _imageUploadService = Provider.of<ImageUploadService>(context);
  }


  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _imageUploadService.dispose(); // Dispose ValueNotifiers in the service
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("Usuário não autenticado.");
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (mounted && userDoc.exists) {
        final userData = userDoc.data()!;
        _nameController.text = userData['name'] ?? '';
        _tagController.text = userData['tag'] ?? '';
        _photoURL = userData['photoURL'];
      } else if (mounted) {
         print("Documento do usuário não encontrado.");
         _errorMessage = "Não foi possível carregar os dados do perfil.";
      }
    } catch (e) {
      print("Erro ao carregar perfil: $e");
       if (mounted) {
          _errorMessage = "Falha ao carregar dados do perfil.";
       }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Adjust quality
        maxWidth: 800, // Optional: resize image
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final downloadURL = await _imageUploadService.uploadProfileImage(imageFile: imageFile);

        if (mounted && downloadURL != null) {
          setState(() {
            _photoURL = downloadURL;
          });
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil atualizada!'), backgroundColor: Colors.green),
          );
        } else if (mounted && _imageUploadService.error.value != null) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro no upload: ${_imageUploadService.error.value}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Erro ao selecionar/enviar imagem: $e");
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao processar imagem: $e'), backgroundColor: Colors.red),
          );
       }
    }
  }

  Future<void> _saveProfile() async {
     if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("Usuário não autenticado.");

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'tag': _tagController.text.trim().toUpperCase(),
        // photoURL is updated directly by the upload service
      });

       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
          );
       }

    } catch (e) {
      print("Erro ao salvar perfil: $e");
       if (mounted) {
          setState(() {
             _errorMessage = "Falha ao salvar alterações.";
          });
       }
    } finally {
       if (mounted) {
          setState(() { _isLoading = false; });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Meu Perfil',
         style: TextStyle(
              color: Color(0xFFFF1A1A),
              fontWeight: FontWeight.bold,
               shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Color(0xFF8B0000),
                  ),
                ],
            ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading && _nameController.text.isEmpty // Show loading only on initial load
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF1A1A)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Header (Photo)
                      _buildProfileHeader(),
                      const SizedBox(height: 30),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Form Fields
                      _buildLabel('Nome'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(hintText: 'Seu nome no jogo'),
                        style: const TextStyle(color: Colors.white),
                         validator: (value) => (value == null || value.isEmpty) ? 'Nome é obrigatório' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('TAG'),
                      TextFormField(
                        controller: _tagController,
                        decoration: _inputDecoration(hintText: 'TAG do jogador (Ex: LDR)'),
                        style: const TextStyle(color: Colors.white),
                        maxLength: 5,
                        textCapitalization: TextCapitalization.characters,
                         // No validator needed for optional field
                      ),
                      const SizedBox(height: 30),

                      // Save Button
                      ValueListenableBuilder<bool>(
                        valueListenable: _imageUploadService.uploading,
                        builder: (context, isUploading, child) {
                          final bool isSaving = _isLoading && !isUploading; // Show saving indicator only if not uploading
                          return ButtonCustom(
                            title: isUploading ? 'Enviando Foto...' : (isSaving ? 'Salvando...' : 'Salvar Alterações'),
                            onPressed: (isUploading || isSaving) ? null : _saveProfile,
                            disabled: isUploading || isSaving,
                          );
                        },
                      ),
                       const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _imageUploadService.uploading,
          builder: (context, isUploading, _) {
            return GestureDetector(
              onTap: isUploading ? null : _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 63, // Slightly larger for border effect
                    backgroundColor: const Color(0xFFFF1A1A),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF333333),
                      backgroundImage: (_photoURL != null && !isUploading) ? NetworkImage(_photoURL!) : null,
                      child: (_photoURL == null && !isUploading)
                          ? Text(
                              _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 40, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                  if (isUploading)
                    ValueListenableBuilder<double>(
                       valueListenable: _imageUploadService.progress,
                       builder: (context, progressValue, _) {
                          return Container(
                             width: 120,
                             height: 120,
                             decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                             ),
                             child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   CircularProgressIndicator(
                                     value: progressValue / 100,
                                     color: Colors.white,
                                     strokeWidth: 2,
                                   ),
                                   const SizedBox(height: 8),
                                   Text(
                                     '${progressValue.toStringAsFixed(0)}%',
                                     style: const TextStyle(color: Colors.white, fontSize: 12),
                                   ),
                                ],
                             ),
                          );
                       }
                    ),
                  // Edit Icon Overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF1A1A),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 2)),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'Toque na foto para alterar',
          style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      counterText: "", // Hide the counter for maxLength
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF1A1A)),
      ),
      contentPadding: const EdgeInsets.all(15),
    );
  }
}

