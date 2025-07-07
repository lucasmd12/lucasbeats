import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart'; // Import CustomRole and Clan models
import 'package:lucasbeatsfederacao/utils/logger.dart';
// Assuming Role enum might be needed later

class ClanCustomRolesScreen extends StatefulWidget {
  final String clanId;

  const ClanCustomRolesScreen({
    Key? key,
    required this.clanId,
  }) : super(key: key);

  @override
  State<ClanCustomRolesScreen> createState() => _ClanCustomRolesScreenState();
}

class _ClanCustomRolesScreenState extends State<ClanCustomRolesScreen> {
  List<CustomRole> _customRoles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomRoles();
  }

  Future<void> _loadCustomRoles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final clanService = Provider.of<ClanService>(context, listen: false);
      final clan = await clanService.getClanDetails(widget.clanId);
      if (mounted) {
        setState(() {
          // Access customRoles from the fetched clan details
          _customRoles = clan?.customRoles ?? [];
          _isLoading = false;
        });
      }
    } catch (e, s) {
      Logger.error('Error loading custom roles for clan ${widget.clanId}', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar cargos customizados: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Cargos Customizados'),
        backgroundColor: Colors.black87, // Dark background for AppBar
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text('Erro: $_error', style: const TextStyle(color: Colors.red)) // Use const TextStyle
                : _customRoles.isEmpty
                    ? const Text('Nenhum cargo customizado encontrado.')
                    : ListView.builder(
                        itemCount: _customRoles.length,
                        itemBuilder: (context, index) {
                          final role = _customRoles[index];
                          return ListTile(
                            title: Text(role.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditRoleDialog(role),
                                  tooltip: 'Editar Cargo',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _showDeleteRoleConfirmationDialog(role),
                                  tooltip: 'Excluir Cargo',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoleDialog,
        tooltip: 'Adicionar Cargo Customizado',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRoleDialog() {
    // TODO: Implement add role dialog with form for name and permissions
    Logger.info('Show add role dialog');
    // Example of showing a simple dialog:
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Novo Cargo'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Implementar formulário para nome e permissões aqui.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Add Save button after implementing form logic
          ],
        );
      },
    );
  }

  void _showEditRoleDialog(CustomRole role) {
    // TODO: Implement edit role dialog with form pre-filled with role data
    Logger.info('Show edit role dialog for: ${role.name}');
    // Example of showing a simple dialog:
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Cargo: ${role.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Implementar formulário para editar permissões aqui.'),
                // Display current permissions
                Text('Permissões atuais: ${role.permissions.join(', ')}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Add Save button after implementing form logic
          ],
        );
      },
    );
  }

  void _showDeleteRoleConfirmationDialog(CustomRole role) {
    // TODO: Implement delete role confirmation dialog and call delete service
    Logger.info('Show delete role confirmation dialog for: ${role.name}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir o cargo "${role.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () async {
                // TODO: Call clanService.deleteCustomRole
                Logger.info('Deleting role: ${role.name}');
                Navigator.of(context).pop(); // Close dialog
                 // After successful deletion, refresh the list:
                 // _loadCustomRoles();
              },
            ),
          ],
        );
      },
    );
  }
}

// Placeholder for available permissions for now
// In a real app, you would fetch available permissions from the backend
const List<String> availablePermissions = [
  'manage_members',
  'manage_roles',
  'manage_channels',
  'send_messages',
  'kick_members',
  'ban_members',
];


// Although CustomRole is defined in clan_model.dart,
// a separate extension might be useful for utility functions.
// Keeping it here for now, but consider if it belongs in clan_model.dart
extension ColorExtension on String {
  Color toColor() {
    // Basic implementation - may need refinement based on actual color strings
    final hexCode = replaceAll('#', '');
    if (hexCode.length == 6) {
       return Color(int.parse('FF$hexCode', radix: 16));
    }
    // Return a default color or throw an error if the format is unexpected
    return Colors.grey;
  }
}