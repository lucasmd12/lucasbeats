import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/widgets/button_custom.dart';
// Assuming navigation setup
// import '../../../../navigation/app_routes.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;

      if (user != null) {
        // 2. Update user profile (display name)
        await user.updateDisplayName(_nameController.text.trim());

        // 3. Create user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'tag': _tagController.text.trim().toUpperCase(), // Store tag in uppercase
          'email': user.email,
          'photoURL': null, // Initially no photo
          'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
          'clanId': null, // Initially no clan
          'uid': user.uid, // Storing uid for easier querying if needed
        });

        // Show success message and navigate to Login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta criada com sucesso! Faça o login.')),
          );
          // Assuming Navigator setup allows popping back to login or specific navigation
          Navigator.of(context).pop(); // Go back to Login screen
          // Or: Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } else {
         throw Exception("Falha ao obter informações do usuário após criação.");
      }

    } on FirebaseAuthException catch (e) {
      String message = 'Falha ao criar conta. Tente novamente.';
      if (e.code == 'email-already-in-use') {
        message = 'Este email já está em uso.';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido.';
      } else if (e.code == 'weak-password') {
        message = 'Senha muito fraca (mínimo 6 caracteres).';
      }
       print('Erro de registro Firebase: ${e.code} - ${e.message}'); // Log para debug
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
       print('Erro inesperado no registro: $e'); // Log para debug
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
      });
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Criar Conta',
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10), // Adjust spacing after AppBar
                const Center(
                  child: Text(
                    'Junte-se à Federação LAMAFIA',
                    style: TextStyle(fontSize: 16, color: Color(0xFFCCCCCC)),
                  ),
                ),
                const SizedBox(height: 30),

                // Form Fields
                _buildLabel('Nome'),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(hintText: 'Seu nome no jogo'),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nome é obrigatório' : null,
                ),
                const SizedBox(height: 15),

                 _buildLabel('TAG', optional: true),
                TextFormField(
                  controller: _tagController,
                  decoration: _inputDecoration(hintText: 'TAG do jogador (Ex: LDR)'),
                  style: const TextStyle(color: Colors.white),
                  maxLength: 5,
                  textCapitalization: TextCapitalization.characters,
                   // No validator needed for optional field
                ),
                const SizedBox(height: 15),

                _buildLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(hintText: 'seu.email@exemplo.com'),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email é obrigatório';
                    }
                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                      return 'Insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _buildLabel('Senha'),
                TextFormField(
                  controller: _passwordController,
                  decoration: _inputDecoration(hintText: 'Mínimo 6 caracteres'),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha é obrigatória';
                    }
                    if (value.length < 6) {
                      return 'Senha deve ter no mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _buildLabel('Confirmar Senha'),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: _inputDecoration(hintText: 'Digite a senha novamente'),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmação de senha é obrigatória';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                 if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                ButtonCustom(
                  title: _isLoading ? 'Registrando...' : 'Registrar',
                  onPressed: _isLoading ? null : _handleRegister,
                  disabled: _isLoading,
                  // style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), // Make button wider
                ),
                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(), // Go back to Login
                    child: const Text(
                      'Já tem uma conta? Faça login',
                      style: TextStyle(color: Color(0xFFFF1A1A), fontSize: 14),
                    ),
                  ),
                ),
                 const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (optional)
            const Text(
              ' (opcional)',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12, fontWeight: FontWeight.normal),
            ),
        ],
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

