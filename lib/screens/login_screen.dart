import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/logger.dart';
import '../widgets/custom_snackbar.dart'; // Assuming a custom snackbar exists

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(); // Changed to email
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if form is invalid
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('Attempting login for: ${_emailController.text}');
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Logger.info('Login successful for UID: ${credential.user?.uid}');

      if (mounted && credential.user != null) {
        // UserProvider might load data based on auth state changes, or trigger manually
        // Provider.of<UserProvider>(context, listen: false).loadUserData(credential.user!.uid);

        // Navigation is handled by the StreamBuilder in main.dart
        // Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase Login Failed', error: e);
      String errorMessage = 'Ocorreu um erro ao fazer login.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Email ou senha inválidos.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'O formato do email é inválido.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Este usuário foi desabilitado.';
      }
      if (mounted) {
        CustomSnackbar.showError(context, errorMessage);
      }
    } catch (e, stackTrace) {
      Logger.error('Generic Login Failed', error: e, stackTrace: stackTrace);
      if (mounted) {
        CustomSnackbar.showError(context, 'Ocorreu um erro inesperado.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      CustomSnackbar.showError(context, 'Digite seu email para redefinir a senha.');
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Logger.info('Password reset email sent to: $email');
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Email de redefinição de senha enviado para $email.');
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('Password Reset Failed', error: e);
      String errorMessage = 'Erro ao enviar email de redefinição.';
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = 'Email não encontrado ou inválido.';
      }
      if (mounted) {
        CustomSnackbar.showError(context, errorMessage);
      }
    } catch (e, stackTrace) {
      Logger.error('Generic Password Reset Failed', error: e, stackTrace: stackTrace);
      if (mounted) {
        CustomSnackbar.showError(context, 'Ocorreu um erro inesperado.');
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Use background image if available, otherwise fallback color
      // decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/images_png/background_image_login.png'), fit: BoxFit.cover)),
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
                  // Use actual logo asset
                  Image.asset(
                    'assets/images_png/app_icon_login_splash.jpg', // Use the specified icon/logo
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shield_moon, // Fallback icon
                      size: 80,
                      color: Color(0xFF9147FF),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'LAMAFIA',
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Faça login para continuar',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium,
                  ),
                  const SizedBox(height: 48),

                  // Email Field
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
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Por favor, insira um email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
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
                      // Add more password validation if needed (e.g., length)
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ENTRAR'),
                  ),
                  const SizedBox(height: 16),

                  // Forgot Password & Register Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : _handlePasswordReset,
                        child: const Text('Esqueceu a senha?'),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Criar conta'),
                      ),
                    ],
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

