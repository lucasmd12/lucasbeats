import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';

class AdminManageClansScreen extends StatefulWidget {
  final String? federationId; // Optional federation ID passed for directed creation

  const AdminManageClansScreen({super.key, this.federationId});

  @override
  State<AdminManageClansScreen> createState() => _AdminManageClansScreenState();
}

class _AdminManageClansScreenState extends State<AdminManageClansScreen> {
  List<Clan> _clans = [];
  List<Federation> _availableFederations = [];
  bool _isDesignatedFederationLeader = false; // Track if current user is leader of the passed federation
  String? _selectedFederationId;
  bool _isLoading = false;
  User? _currentUser;

  final TextEditingController _clanNameController = TextEditingController();
  final TextEditingController _editClanNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUser = authProvider.currentUser;

    if (_currentUser == null) {
      // User not logged in or not available, handle appropriately (e.g., navigate to login)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    await _loadClans();

    // Load federations only for ADMs or if a specific federationId is provided
    if (_currentUser!.role == Role.adm || widget.federationId != null) {
      await _loadFederations();
    }

    // Check if the user is the designated leader of the provided federation
    if (_currentUser!.role != Role.adm && widget.federationId != null) {
      try {
        final federationService = Provider.of<FederationService>(context, listen: false);
        final designatedFederation = await federationService.getFederationDetails(widget.federationId!);

        if (designatedFederation != null) {
          _isDesignatedFederationLeader = designatedFederation.leader.id == _currentUser!.id;
        }

        // If designated leader, pre-select this federation and limit the available federations list
        if (_isDesignatedFederationLeader && designatedFederation != null) {
          if (mounted) {
            setState(() {
              _availableFederations = [designatedFederation];
              _selectedFederationId = widget.federationId;
            });
          }
        }
      } catch (e, s) {
        Logger.error('Error checking federation leader status:', error: e, stackTrace: s);
        if (mounted) {
          _showSnackBar('Failed to check federation leader status: $e', isError: true);
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClans() async {
    Logger.info('Loading clans...');
    if (!mounted) return;

    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final List<Clan> clans;
      if (widget.federationId != null) {
        clans = await clanService.fetchClansByFederation(widget.federationId!);
      } else {
        clans = await clanService.getAllClans();
      }
      if (mounted) {
        // Filter out any potential nulls and ensure it's a List<Clan>
        setState(() {
          _clans = clans.whereType<Clan>().toList();
        });
      }
    } catch (e, s) {
      Logger.error('Error loading clans:', error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar('Failed to load clans: $e', isError: true);
        setState(() {
          _clans = [];
        });
      }
    }
  }

  Future<void> _loadFederations() async {
    Logger.info('Loading federations...');
    if (!mounted) return;

    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      final federations = await federationService.getAllFederations();
      if (mounted) {
        setState(() {
          // Safely assign federations, filtering out any potential nulls
          _availableFederations = federations.whereType<Federation>().toList();
        });
      }
    } catch (e, s) {
      Logger.error('Error loading federations:', error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar('Failed to load federations: $e', isError: true);
        setState(() {
          _availableFederations = [];
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _showCreateClanDialog() {
    // Reset selected federation before showing dialog unless an initial one is provided
    if (widget.federationId == null) {
      _selectedFederationId = null;
    } else {
      // If federationId is provided, make sure _selectedFederationId is set for the dropdown
      _selectedFederationId = widget.federationId;
    }
    _clanNameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser!; // Assumindo que currentUser não é nulo aqui com base na lógica de _loadData
        final bool isAdm = currentUser.role == Role.adm;
        // Determine if the dropdown should be disabled (for designated leaders who are not ADM)
        final bool disableFederationSelection = _isDesignatedFederationLeader && !isAdm;

        return AlertDialog(
          title: const Text('Criar Novo Clã'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _clanNameController,
                  decoration: const InputDecoration(hintText: 'Nome do Clã'),
                ),
                const SizedBox(height: 16),
                // Show dropdown for ADMs or if user is designated leader
                if (isAdm || _isDesignatedFederationLeader)
                  DropdownButtonFormField<String?>(
                    value: _selectedFederationId,
                    decoration: const InputDecoration(
                      labelText: 'Associar a Federação',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      if (isAdm && !_isDesignatedFederationLeader) // Only ADMs not designated leaders can select "Nenhuma Federação"
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Nenhuma Federação'),
                        ),
                      ..._availableFederations.map((federation) {
                        return DropdownMenuItem<String?>(
                          value: federation.id,
                          child: Text(federation.name ?? 'Federação sem nome'),
                        );
                      }).toList(),
                    ],
                    onChanged: disableFederationSelection ? null : (val) {
                      // When user selects a federation manually (only if enabled)
                      setState(() {
                        _selectedFederationId = val;
                      });
                    },
                    // Disable the dropdown if selection is not allowed
                    isDense: true,
                    iconDisabledColor: Colors.grey,
                    autovalidateMode: AutovalidateMode.disabled,
                    // Add explicit disabled property for clarity
                    disabledHint: disableFederationSelection ? Text(_availableFederations.first.name ?? 'Federação sem nome') : null,
                  ),
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
            TextButton(
              child: const Text('Criar'),
              onPressed: () async {
                final clanName = _clanNameController.text.trim();
                if (clanName.isEmpty) {
                  _showSnackBar('Clan name cannot be empty.', isError: true);
                  return;
                }

                // If designated leader, ensure a federation is selected (it should be pre-selected)
                if (_isDesignatedFederationLeader && _selectedFederationId == null) {
                  _showSnackBar('Internal Error: Designated leader must have a federation selected.', isError: true);
                  return;
                }

                Navigator.of(context).pop(); // Dismiss dialog

                try {
                  final clanService = Provider.of<ClanService>(context, listen: false);
                  final Map<String, dynamic> clanData = {'name': clanName};

                  // Use the selected federation ID, which might be from initialFederationId or user selection
                  if (_selectedFederationId != null) {
                    clanData['federationId'] = _selectedFederationId;
                  } else if (isAdm && !_isDesignatedFederationLeader) {
                    // If ADM and not designated leader, and selected null, explicitly pass null
                    clanData['federationId'] = null;
                  } else if (!isAdm && !_isDesignatedFederationLeader && widget.federationId == null) {
                     // If not ADM, not designated leader, and no federationId provided, clan must not be created without federation.
                     _showSnackBar('Error: Only ADMs or designated Federation Leaders can create unassigned clans.', isError: true);
                     return;
                  }


                  final newClan = await clanService.createClan(clanData);

                  if (newClan != null) {
                    _showSnackBar('Clan "${newClan.name}" created successfully!');
                    _loadClans(); // Refresh the list
                    // TODO: Consider navigating back or to the new clan\'s details if created by designated leader
                  } else {
                    _showSnackBar('Failed to create clan.', isError: true);
                  }
                } catch (e, s) {
                  Logger.error('Error creating clan:', error: e, stackTrace: s);
                  _showSnackBar('Failed to create clan: ${e.toString()}', isError: true); // Show detailed error
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditClanDialog(Clan clan) {
    _editClanNameController.text = clan.name; // Assuming name is never null based on model
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser; // currentUser pode ser nulo aqui antes do check de permissão
    // Permission check for editing: ADM or the leader of THIS specific clan
    final bool canEdit = currentUser?.role == Role.adm || (currentUser?.id != null && currentUser?.id == clan.leaderId);

    if (!canEdit) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permissão Negada'),
            content: const Text('Você não tem permissão para editar este clã.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Stop here if no permission
    }


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Clã: ${clan.name}'),
          content: TextField(
            controller: _editClanNameController,
            decoration: const InputDecoration(hintText: 'Novo Nome do Clã'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salvar'),
              onPressed: () async {
                final newName = _editClanNameController.text.trim();
                if (newName.isEmpty) {
                  _showSnackBar('Clan name cannot be empty.', isError: true);
                  return;
                }
                Navigator.of(context).pop(); // Dismiss dialog

                try {
                  final clanService = Provider.of<ClanService>(context, listen: false);
                  final updatedClan = await clanService.updateClanDetails(clan.id, name: newName);
                  if (updatedClan != null) {
                    _showSnackBar('Clan "${updatedClan.name}" updated successfully!');
                    _loadClans(); // Refresh the list
                  } else {
                    _showSnackBar('Failed to update clan.', isError: true);
                  }
                } catch (e, s) {
                   Logger.error('Error updating clan ${clan.id}:', error: e, stackTrace: s);
                   _showSnackBar('Failed to update clan: ${e.toString()}', isError: true); // Show detailed error
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteClanConfirmationDialog(Clan clan) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    // Permission check for deleting: only ADM
    final bool canDelete = currentUser?.role == Role.adm;

    if (!canDelete) {
       showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permissão Negada'),
            content: const Text('Você não tem permissão para excluir clãs.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Stop here if no permission
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir o clã "${clan.name}"?'), // Assuming name is not null
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
                Navigator.of(context).pop(); // Dismiss dialog

                final clanService = Provider.of<ClanService>(context, listen: false);
                try {
                  bool success = await clanService.deleteClan(clan.id);

                  if (success) {
                    _showSnackBar('Clan "${clan.name}" deleted successfully!');
                    _loadClans(); // Refresh the list on success
                  } else {
                    _showSnackBar('Failed to delete clan.', isError: true);
                  }
                } catch (e, s) {
                   Logger.error('Error deleting clan ${clan.id}:', error: e, stackTrace: s);
                   _showSnackBar('Failed to delete clan: ${e.toString()}', isError: true); // Show detailed error
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Helper to check edit permission for a given clan
  bool _canEditClan(Clan clan) {
     if (_currentUser == null) return false;
     return _currentUser!.role == Role.adm || (_currentUser!.id == clan.leaderId);
  }

  // Helper to check delete permission for a given clan (only ADM)
   bool _canDeleteClan() {
     if (_currentUser == null) return false;
     return _currentUser!.role == Role.adm;
  }


  @override
  Widget build(BuildContext context) {
    // Ensure currentUser is available for conditional rendering
    if (_currentUser == null && !_isLoading) {
      // Or show a loading indicator or redirect
      return Scaffold(
        appBar: AppBar(title: const Text('Gerenciar Clãs')),
        body: const Center(child: Text('Por favor, faça login para gerenciar clãs.')), // More informative message
      );
    }

    // Determine if the user can create clans (ADM or designated federation leader)
    final bool canCreateClans = _currentUser?.role == Role.adm || _isDesignatedFederationLeader;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Clãs'),
      ),
      body: _isLoading && _clans.isEmpty // Show loading only initially or when refreshing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _clans.isEmpty
              ? const Center(
                  child: Text('Nenhum clã encontrado.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _clans.length,
                  itemBuilder: (context, index) {
                    final clan = _clans[index];
                    final clanName = clan.name; // Assuming name is not null

                    // Check specific permissions for the current clan in the list
                    final bool canEditThisClan = _canEditClan(clan);
                    final bool canDeleteAnyClan = _canDeleteClan(); // Delete is global for ADM

                    return ListTile(
                      title: Text(clanName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           if (canEditThisClan) // Conditionally show edit button
                             IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditClanDialog(clan);
                                },
                                tooltip: 'Editar Clã',
                             ),
                           if (canDeleteAnyClan) // Conditionally show delete button
                             IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _showDeleteClanConfirmationDialog(clan);
                                },
                                tooltip: 'Excluir Clã',
                             ),
                            // If neither action is allowed, you might hide the Row or show a different indicator
                            if (!canEditThisClan && !canDeleteAnyClan)
                              const SizedBox.shrink(), // Hide the row if no actions
                        ],
                      ),
                    );
                  },
                ),
      // Show FAB for ADMs OR for Federation Leaders when navigating from their federation detail
      floatingActionButton: canCreateClans
          ? FloatingActionButton(
              onPressed: _showCreateClanDialog,
              tooltip: 'Criar Novo Clã',
              child: const Icon(Icons.add),
            )
          : null, // Hide FAB for other users
    );
  }

  @override
  void dispose() {
    _clanNameController.dispose();
    _editClanNameController.dispose();
    super.dispose();
  }
}