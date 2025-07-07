import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucasbeatsfederacao/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      // Optionally show a loading indicator or redirect
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(50.0), // Ajuste o raio conforme necessário
              child: CachedNetworkImage(
                imageUrl: currentUser.avatar ?? '', // Use empty string as a fallback
                placeholder: (context, url) => const Icon(Icons.person),
                errorWidget: (context, url, error) => const Icon(Icons.person),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              currentUser.username,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}