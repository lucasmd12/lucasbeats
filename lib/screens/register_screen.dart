import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import '../utils/logger.dart';
import '../widgets/custom_snackbar.dart';
import '../models/user_model.dart'; // Import UserModel

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController(); // Controller for user's display name
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // Function to request permissions after registration
  Future<void> _requestPermissionsAfterRegister() async {
    Logger.info("Requesting permissions after registration...");
    await Permission.notification.request();
    await Permission.storage.request();
    await Permission.microphone.request();
    Logger.info("Initial permission requests completed.");
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('Attempting registration for: ${_emailController.text}');
      // 1. Create user with Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Logger.info('Auth user created successfully: ${credential.user?.uid}');

      if (credential.user != null) {
        final userId = credential.user!.uid;
        final userEmail = _emailController.text.trim();
        final userName = _displayNameController.text.trim(); // Get name from controller

        // 2. Update display name in Firebase Auth
        try {
          await credential.user!.updateDisplayName(userName);
          Logger.info('Auth display name updated.');
        } catch (e) {
          Logger.error('Failed to update Auth display name', error: e);
        }

        // 3. Create user document in Firestore using UserModel
        Logger.info('Attempting to create Firestore document for user: $userId');
        final newUser = UserModel(
          uid: userId,
          username: userName, // Corrected: Use 'username' field from UserModel
          email: userEmail,
          fotoUrl: null, // Default photoUrl
          role: 'recruta', // Corrected: Use 'role' field, set default role
          clanId: null,
          canalVozAtual: null,
          online: false,
          ultimoPing: Timestamp.now(), // Set initial ping time
          fcmTokens: [], // Initialize empty list
        );

        // Use the toMap method to get the Map for Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set(newUser.toMap()); // Corrected: Use toMap() method
          Logger.info('Firestore user document created successfully for: $userId');
        } on FirebaseException catch (firestoreError) {
           Logger.error('Firestore document creation failed', error: firestoreError, stackTrace: firestoreError.stackTrace);
           try { await credential.user!.delete(); Logger.warning('Auth user $userId deleted due to Firestore failure.'); } catch (_) {}
           throw Exception('Falha ao salvar dados no banco de dados: ${firestoreError.message}');
        } catch (otherError, stackTrace) {
           Logger.error('Firestore document creation failed (Unknown Error)', error: otherError, stackTrace: stackTrace);
           try { await credential.user!.delete(); Logger.warning('Auth user $userId deleted due to Firestore failure.'); } catch (_) {}
           throw Exception('Falha ao salvar dados no banco de dados (Erro desconhecido).');
        }

        // 4. Request Permissions
        await _requestPermissionsAfterRegister();

        // 5. Show success and navigate
        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Conta criada com sucesso! Faça o login.');
          Navigator.pop(context); // Go back to login
        }
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase Auth Registration Failed', error: e);
      String errorMessage = 'Ocorreu um erro ao criar a conta.';
      if (e.code == 'weak-password') {
        errorMessage = 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Este email já está em uso.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'O formato do email é inválido.';
      } else {
        errorMessage = 'Erro de autenticação: ${e.message}';
      }
      if (mounted) {
        CustomSnackbar.showError(context, errorMessage);
      }
    } catch (e, stackTrace) {
      Logger.error('Generic Registration Failed', error: e, stackTrace: stackTrace);
      if (mounted) {
        CustomSnackbar.showError(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crie sua conta FEDERACAO MADOUT', // Updated Text
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _displayNameController, // Use the correct controller
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                    decoration: const InputDecoration(
                      labelText: 'Nome de Exibição',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira seu nome de exibição';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                        return 'Por favor, insira um email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('CRIAR CONTA'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.pop(context);
                    },
                    child: const Text('Já tem uma conta? Faça login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

