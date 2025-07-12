import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/user_service.dart'; // Adjust import path
import 'package:lucasbeatsfederacao/models/user_model.dart'; // Adjust import path
// Adjust import path
import 'package:lucasbeatsfederacao/utils/logger.dart'; // Adjust import path


class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _users = [];
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final users = await userService.getAllUsers();

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e, stacktrace) {
      Logger.error('Error loading users:', error: e, stackTrace: stacktrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'Falha ao carregar usuários: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum usuário encontrado.',
                        style: TextStyle(color: Colors.white, fontSize: 16), // Adjust text style as needed
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          title: Text(user.username),
                        );
                      },
                    ),
    );
  }
}