import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Assuming provider for state management

import '../../../../shared/widgets/button_custom.dart';
// Assuming a navigator service or direct navigation
// import '../../../../navigation/app_routes.dart'; 
// Assuming an auth service or direct firebase calls
// import '../../../../services/auth_service.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Assuming direct FirebaseAuth usage for simplicity
      // Replace with AuthService call if using one
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigation is typically handled by an auth state listener in main.dart or App widget
      // Navigator.of(context).pushReplacementNamed(AppRoutes.home); 
    } on FirebaseAuthException catch (e) {
      String message = 'Falha ao fazer login. Tente novamente.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Email ou senha incorretos.';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido.';
      } else if (e.code == 'too-many-requests') {
        message = 'Muitas tentativas. Tente novamente mais tarde.';
      } else if (e.code == 'invalid-credential') {
         message = 'Email ou senha incorretos.'; // More generic message for invalid credential
      }
      print('Erro de login Firebase: ${e.code} - ${e.message}'); // Log para debug
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      print('Erro inesperado no login: $e'); // Log para debug
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
      });
    } finally {
      if (mounted) { // Check if the widget is still in the tree
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo Section
                Column(
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'LAMAFIA', // Updated name from pubspec.yaml
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF1A1A),
                        shadows: [
                          Shadow(
                            offset: const Offset(2.0, 2.0),
                            blurRadius: 5.0,
                            color: const Color(0xFF8B0000),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Comunicação e organização para o clã.', // Updated tagline from pubspec.yaml
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),

                // Form Section
                Column(
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
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
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu email';
                        } 
                        // Basic email validation
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                           return 'Por favor, insira um email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'Senha',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
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
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ButtonCustom(
                      title: _isLoading ? 'Entrando...' : 'Entrar',
                      onPressed: _isLoading ? null : _handleLogin,
                      disabled: _isLoading,
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        // Navigate to Register Screen
                        // Navigator.of(context).pushNamed(AppRoutes.register);
                         print("Navigate to Register Screen"); // Placeholder
                      },
                      child: const Text(
                        'Não tem uma conta? Registre-se',
                        style: TextStyle(color: Color(0xFFFF1A1A), fontSize: 14),
                      ),
                    ),
                  ],
                ),

                // Footer Section
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'LAMAFIA v1.0.0+4', // Version from pubspec
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

