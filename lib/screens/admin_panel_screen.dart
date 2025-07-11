import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart'; // Import adicionado
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/screens/federation_leader_panel_screen.dart'; // Import adicionado
import 'package:lucasbeatsfederacao/screens/clan_leader_panel_screen.dart'; // Import adicionado
import 'package:lucasbeatsfederacao/providers/auth_provider.dart'; // Import adicionado

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}
class _AdminPanelScreenState extends State<AdminPanelScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<User> _allUsers = [];
  List<Map<String, dynamic>> _systemLogs = [];
  bool _isLoading = true;

  // Estado e função para carregar Federações
  List<Federation> _allFederations = [];
  bool _isLoadingFederations = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAdminData();

    // Listener para carregar dados das abas quando selecionadas
    _tabController.addListener(_handleTabSelection);
  }

  Future<void> _loadAdminData() async {
    try {
      setState(() => _isLoading = true);
      
      final apiService = ApiService();
      
      // Carregar usuários
      final usersResponse = await apiService.get("/api/admin/users");
      _allUsers = (usersResponse["users"] as List)
          .map((user) => User.fromJson(user))
          .toList();
      
      // Carregar logs do sistema
      final logsResponse = await apiService.get("/api/admin/logs");
      _systemLogs = List<Map<String, dynamic>>.from(logsResponse["logs"] ?? []);
      
      setState(() => _isLoading = false);
    } catch (e) {
      Logger.error("Erro ao carregar dados do admin: $e");
      setState(() => _isLoading = false);
    }
  }

  // Estado e função para carregar Clãs
  List<Clan> _allClans = [];
  bool _isLoadingClans = false;

  Future<void> _loadClans() async {
    if (_isLoadingClans) return; // Prevent double loading
    setState(() => _isLoadingClans = true);
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      _allClans = await clanService.getAllClans();
    } catch (e, s) {
      Logger.error("Error loading all clans in AdminPanel", error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _isLoadingClans = false);
    }
  }

  void _handleTabSelection() {
     if (!_tabController.indexIsChanging && mounted) {
      if (_tabController.index == 1) { // Aba de Clãs
        _loadClans();
      } else if (_tabController.index == 2) { // Aba de Federações
        _loadFederationsData();
      }
    }
  }

  // Estado e função para carregar Federações
   Future<void> _loadFederationsData() async {
    if (_isLoadingFederations) return; // Prevent double loading
    setState(() => _isLoadingFederations = true);
    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      _allFederations = await federationService.getAllFederations();
    } catch (e, s) {
      Logger.error("Error loading all federations in AdminPanel", error: e, stackTrace: s);
      // Handle error (e.g., show snackbar)
    } finally {
      if (mounted) {
        setState(() => _isLoadingFederations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser; // Obter o usuário logado

    // Verificar se o usuário logado é ADM_MASTER
    final bool isAdmMaster = currentUser?.role == Role.admMaster;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFFF44336)),
            SizedBox(width: 8),
            Text("Painel Administrativo"),
          ],
        ),
        backgroundColor: const Color(0xFFB71C1C),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Usuários"),
            Tab(icon: Icon(Icons.shield), text: "Clãs"), // Ícone para Clãs
            Tab(icon: Icon(Icons.account_tree), text: "Federações"), // Ícone para Federações
            Tab(icon: Icon(Icons.security), text: "Permissões"),
            Tab(icon: Icon(Icons.analytics), text: "Relatórios"),
            Tab(icon: Icon(Icons.settings), text: "Sistema"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildClansTab(isAdmMaster), // Passar isAdmMaster para a aba de Clãs
                _buildFederationsTab(isAdmMaster), // Passar isAdmMaster para a aba de Federações
                _buildPermissionsTab(),
                _buildReportsTab(),
                _buildSystemTab(),
              ],
            ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        return Card(
          color: const Color(0xFF424242),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user.username ?? 'Usuário Desconhecido',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Login: ${user.username ?? 'N/A'}",
                  style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
                ),
                Text(
                  "Clã: ${user.clanName ?? "N/A"} (Papel: ${user.clanRole.displayName})",
                  style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
                ),
                Text(
                  "Federação: ${user.federationName ?? "N/A"}",
                  style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleUserAction(user, action),
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: "edit_role",
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Editar Papel"),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: "reset_password",
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, color: Colors.purple),
                      SizedBox(width: 8),
                      Text("Resetar Senha"),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: "view_details",
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Ver Detalhes"),
                    ],
                  ),
                ),
                // Impedir suspensão de ADM Master
                if (user.role != Role.admMaster)
                  const PopupMenuItem<String>(
                    value: "suspend",
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.orange),
                        SizedBox(width: 8),
                        Text("Suspender"),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para a aba de Federações
  Widget _buildFederationsTab(bool isAdmMaster) {
    if (_isLoadingFederations) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allFederations.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Nenhuma federação encontrada.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (isAdmMaster) // Apenas ADM_MASTER pode criar federações
            ElevatedButton.icon(
              onPressed: _showCreateFederationDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Criar Nova Federação', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary, // Cor de fundo do botão
              ),
            ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _allFederations.length,
            itemBuilder: (context, index) {
              final federation = _allFederations[index];
              return Card(
                 color: const Color(0xFF424242),
                 margin: const EdgeInsets.only(bottom: 8),
                 child: ListTile(
                   leading: Icon(Icons.account_tree, color: Theme.of(context).colorScheme.primary), // Ícone para federação
                   title: Text(federation.name ?? 'Federação sem nome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   subtitle: Text('Tag: ${federation.tag ?? 'N/A'}', style: const TextStyle(color: Color(0xFFBDBDBD))), // Exibir tag
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       // Botão de exclusão existente (apenas para ADM_MASTER)
                       if (isAdmMaster)
                         IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent), // Botão de exclusão
                            onPressed: () {
                              _showDeleteFederationConfirmationDialog(federation); // Chamar o diálogo de confirmação
                            },
                            tooltip: 'Excluir Federação',
                         ),
                       // Menu de opções para a federação
                       PopupMenuButton<String>(
                         onSelected: (action) => _handleFederationAction(federation, action),
                         itemBuilder: (context) => <PopupMenuEntry<String>>[
                           const PopupMenuItem<String>(
                             value: "transfer_leadership",
                             child: Text("Transferir Liderança"),
                           ),
                           const PopupMenuItem<String>(
                             value: "manage_clans",
                             child: Text("Gerenciar Clãs"),
                           ),
                           const PopupMenuItem<String>(
                             value: "manage_members",
                             child: Text("Gerenciar Membros"),
                           ),
                           const PopupMenuItem<String>(
                             value: "open_leader_panel",
                             child: Text("Abrir Painel do Líder"),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
               );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: isAdmMaster // Apenas ADM_MASTER pode criar federações
            ? ElevatedButton.icon(
              onPressed: _showCreateFederationDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Criar Nova Federação', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary, // Cor de fundo do botão
              ),
            ) : Container(), // Se não for ADM_MASTER, não mostra o botão
        ),
      ],
    );
  }
  // Widget para a aba de Clãs
  Widget _buildClansTab(bool isAdmMaster) {
    if (_isLoadingClans) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allClans.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Nenhum clã encontrado.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (isAdmMaster) // Apenas ADM_MASTER pode criar clãs
            ElevatedButton.icon(
              onPressed: _showCreateClanDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Criar Novo Clã', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary, // Cor de fundo do botão
              ),
            ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _allClans.length,
            itemBuilder: (context, index) {
              final clan = _allClans[index];
              return Card(
                 color: const Color(0xFF424242),
                 margin: const EdgeInsets.only(bottom: 8),
                 child: ListTile(
                   leading: Icon(Icons.shield, color: Theme.of(context).colorScheme.primary), // Ícone para clã
                   title: Text(clan.name ?? 'Clã sem nome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   subtitle: Text('Tag: ${clan.tag ?? 'N/A'}', style: const TextStyle(color: Color(0xFFBDBDBD))), // Exibir tag
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       if (isAdmMaster) // Apenas ADM_MASTER pode excluir clãs
                         IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent), // Botão de exclusão
                            onPressed: () {
                              _showDeleteClanConfirmationDialog(clan); // Chama o diálogo de confirmação
                            },
                            tooltip: 'Excluir Clã',
                         ),
                       PopupMenuButton<String>(
                         onSelected: (action) => _handleClanAction(clan, action),
                         itemBuilder: (context) => <PopupMenuEntry<String>>[
                           const PopupMenuItem<String>(
                             value: "transfer_leadership",
                             child: Text("Transferir Liderança"),
                           ),
                           const PopupMenuItem<String>(
                             value: "manage_members",
                             child: Text("Gerenciar Membros"),
                           ),
                           const PopupMenuItem<String>(
                             value: "open_leader_panel",
                             child: Text("Abrir Painel do Líder"),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
               );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: isAdmMaster // Apenas ADM_MASTER pode criar clãs
            ? ElevatedButton.icon(
              onPressed: _showCreateClanDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Criar Novo Clã', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary, // Cor de fundo do botão
              ),
            ) : Container(), // Se não for ADM_MASTER, não mostra o botão
        ),
      ],
    );
  }

  // Diálogo de confirmação de exclusão de Clã (adaptado)
  Future<void> _showDeleteClanConfirmationDialog(Clan clan) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tem certeza que deseja excluir o clã "${clan.name ?? 'este clã'}"?', style: const TextStyle(color: Colors.white70)),
                const Text('Esta ação não pode ser desfeita.', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                try {
                  final clanService = Provider.of<ClanService>(context, listen: false);
                  final success = await clanService.deleteClan(clan.id);
                  if (success) {
                    _showSnackBar('Clã "${clan.name ?? 'excluído'}" excluído com sucesso!');
                    _loadClans(); // Recarregar a lista de clãs
                  } else {
                    _showSnackBar('Falha ao excluir clã.', isError: true);
                  }
                } catch (e, s) {
                   Logger.error('Error deleting clan ${clan.id}:', error: e, stackTrace: s);
                   _showSnackBar('Erro ao excluir clã: ${e.toString()}', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Diálogo de confirmação de exclusão de Federação
  Future<void> _showDeleteFederationConfirmationDialog(Federation federation) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tem certeza que deseja excluir a federação "${federation.name ?? 'esta federação'}"?', style: const TextStyle(color: Colors.white70)),
                const Text('Esta ação não pode ser desfeita.', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                // Chamar o serviço para excluir a federação
                try {
                  final federationService = Provider.of<FederationService>(context, listen: false);
                  final success = await federationService.deleteFederation(federation.id);
                  if (success) {
                    _showSnackBar('Federação "${federation.name ?? 'excluída'}" excluída com sucesso!');
                    _loadFederationsData(); // Recarregar a lista de federações
                  } else {
                    _showSnackBar('Falha ao excluir federação.', isError: true);
                  }
                } catch (e, s) {
                   Logger.error('Error deleting federation ${federation.id}:', error: e, stackTrace: s);
                   _showSnackBar('Erro ao excluir federação: ${e.toString()}', isError: true); // Mostrar erro detalhado
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleFederationAction(Federation federation, String action) {
    switch (action) {
      case "transfer_leadership":
        _showTransferFederationLeadershipDialog(federation);
        break;
      case "manage_clans":
        _showManageFederationClansDialog(federation);
        break;
      case "manage_members":
        _showManageFederationMembersDialog(federation);
        break;
      case "open_leader_panel":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FederationLeaderPanelScreen(federation: federation),
          ),
        );
        break;
    }
  }

  // Implemente a função _handleClanAction para a aba de Clãs
  void _handleClanAction(Clan clan, String action) {
    switch (action) {
      case "transfer_leadership":
        _showTransferClanLeadershipDialog(clan);
        break;
      case "manage_members":
        _showManageClanMembersDialog(clan);
        break;
      case "open_leader_panel":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClanLeaderPanelScreen(clan: clan),
          ),
        );
        break;
    }
  }

  Widget _buildPermissionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hierarquia de Permissões",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPermissionCard(
            Role.admMaster.displayName, // Usando displayName para ADM Master
            "Controle total do sistema",
            Icons.admin_panel_settings,
            Colors.red,
            [
              "Gerenciar todos os usuários",
              "Criar/excluir clãs e federações",
              "Acessar logs do sistema",
              "Configurar servidor",
              "Promover outros admins",
            ],
          ),
          _buildPermissionCard(
            Role.leader.displayName, // Usando displayName
            "Gerencia membros do clã ou federação",
            Icons.star,
            Colors.orange,
            [
              "Promover/rebaixar membros",
              "Expulsar membros",
              "Criar canais de voz",
              "Moderar chat",
            ],
          ),
          _buildPermissionCard(
            Role.subLeader.displayName, // Usando displayName
            "Assistente do líder",
            Icons.star_half,
            const Color(0xFFFBC02D),
            [
              "Moderar chat",
              "Convidar novos membros",
              "Organizar eventos",
            ],
          ),
          _buildPermissionCard(
            Role.member.displayName, // Usando displayName
            "Participante ativo",
            Icons.person,
            Colors.blue,
            [
              "Participar de chamadas",
              "Enviar mensagens",
              "Acessar canais",
            ],
          ),
          _buildPermissionCard(
            Role.user.displayName, // Usando displayName
            "Usuário padrão",
            Icons.person_outline,
            Colors.grey,
            [
              "Acessar funcionalidades básicas",
              "Visualizar perfis",
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  "Usuários Ativos",
                  _allUsers.where((u) => u.online).length.toString(),
                  Icons.people,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReportCard(
                  "Total de Usuários",
                  _allUsers.length.toString(),
                  Icons.group,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  "Admins Master",
                  _allUsers.where((u) => u.role == Role.admMaster).length.toString(),
                  Icons.admin_panel_settings,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReportCard(
                  "Líderes (Clã/Fed.)",
                  _allUsers.where((u) => u.role == Role.leader || u.role == Role.clanLeader).length.toString(),
                  Icons.star,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Logs do Sistema",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._systemLogs.map((log) => Card(
          color: const Color(0xFF424242),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getLogIcon(log["type"]),
              color: _getLogColor(log["type"]),
            ),
            title: Text(
              log.containsKey("message") ? log["message"] : "Log sem mensagem",
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              log.containsKey("timestamp") ? log["timestamp"] : "Sem timestamp",
              style: const TextStyle(color: Color(0xFFBDBDBD)),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPermissionCard(String title, String description, IconData icon, Color color, List<String> permissions) {
    return Card(
      color: const Color(0xFF424242),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Color(0xFFBDBDBD)),
            ),
            const SizedBox(height: 12),
            ...permissions.map((permission) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    permission,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF424242),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Color(0xFFBDBDBD)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
        ),
      );
    }
  }
  void _handleUserAction(User user, String action) {
    switch (action) {
      case "edit_role":
        _showEditRoleDialog(user);
        break;
      case "reset_password":
        _showResetPasswordDialog(user);
        break;
      case "view_details":
        _showUserDetailsDialog(user);
        break;
      case "suspend":
        _showSuspendDialog(user);
        break;
    }
  }

  void _showEditRoleDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text("Editar Papel - ${user.username ?? 'Usuário Desconhecido'}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Role.values.where((role) => role != Role.guest).map((role) => ListTile(
            title: Text(role.displayName, style: const TextStyle(color: Colors.white)),
            leading: Radio<Role>(
              value: role,
              groupValue: user.role,
              onChanged: (Role? value) async {
                if (value != null) {
                  try {
                    final apiService = ApiService();
                    await apiService.put(
                      "/api/admin/users/${user.id}/role",
                      {
                        "role": roleToString(value),
                      },
                    );
                    // Atualizar a lista de usuários após a alteração
                    if (mounted) {
                      _loadAdminData();
                      Navigator.pop(context);
                      _showSnackBar("Papel de ${user.username ?? 'Usuário'} alterado para ${value.displayName} com sucesso!");
                    }
                  } catch (e) {
                    Logger.error("Erro ao alterar papel: $e");
                    if (mounted) {
                      _showSnackBar("Erro ao alterar papel: ${e.toString()}", isError: true);
                    }
                  }
                }
              },
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _showUserDetailsDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text("Detalhes - ${user.username ?? 'Usuário Desconhecido'}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${user.id}", style: const TextStyle(color: Colors.white)),
            Text("Usuário: ${user.username ?? 'N/A'}", style: const TextStyle(color: Colors.white)),
            Text("Papel: ${user.role.displayName}", style: const TextStyle(color: Colors.white)),
            Text("Online: ${user.online ? "Sim" : "Não"}", style: const TextStyle(color: Colors.white)),
            Text("Clã: ${user.clanName ?? "N/A"} (Papel: ${user.clanRole.displayName})", style: const TextStyle(color: Colors.white)),
            Text("Federação: ${user.federationName ?? "N/A"} (Papel: ${user.federationRole.displayName})", style: const TextStyle(color: Colors.white)),
            Text("Última Atividade: ${user.ultimaAtividade != null ? user.ultimaAtividade!.toLocal().toString().split(".")[0] : "N/A"}", style: const TextStyle(color: Colors.white)),
            Text("Última Vez Visto: ${user.lastSeen != null ? user.lastSeen!.toLocal().toString().split(".")[0] : "N/A"}", style: const TextStyle(color: Colors.white)),
            Text("Criado Em: ${user.createdAt != null ? user.createdAt!.toLocal().toString().split(".")[0] : "N/A"}", style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(User user) {
    final TextEditingController _newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text("Resetar Senha - ${user.username ?? 'Usuário Desconhecido'}", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Nova Senha",
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (_newPasswordController.text.isEmpty) {
                _showSnackBar("A nova senha não pode ser vazia.", isError: true);
                return;
              }
              try {
                final apiService = ApiService();
                await apiService.post(
                  "/api/admin/users/${user.id}/reset-password",
                  {},
                );
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar("Senha de ${user.username ?? 'Usuário'} resetada com sucesso!");
                }
              } catch (e) {
                Logger.error("Erro ao resetar senha: $e");
                if (mounted) {
                  _showSnackBar("Erro ao resetar senha: ${e.toString()}", isError: true);
                }
              }
            },
            child: const Text("Resetar", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text("Suspender Usuário - ${user.username ?? 'Usuário Desconhecido'}", style: const TextStyle(color: Colors.white)),
        content: Text(
          "Tem certeza que deseja suspender o usuário ${user.username ?? 'este usuário'}? Ele não poderá mais fazer login.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                final apiService = ApiService();
                await apiService.post(
                  "/api/admin/users/${user.id}/suspend",
                  {},
                );
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar("Usuário ${user.username ?? 'Usuário'} suspenso com sucesso!");
                  _loadAdminData(); // Recarregar dados para refletir a suspensão
                }
              } catch (e) {
                Logger.error("Erro ao suspender usuário: $e");
                if (mounted) {
                  _showSnackBar("Erro ao suspender usuário: ${e.toString()}", isError: true);
                }
              }
            },
            child: const Text("Suspender", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // Diálogo para selecionar usuário para transferência de liderança de Federação
  Future<void> _showTransferFederationLeadershipDialog(Federation federation) async {
    User? selectedUser; // Variável para armazenar o usuário selecionado

    await showDialog<void>( // Usamos await para esperar o diálogo fechar
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text('Transferir Liderança de ${federation.name ?? 'Federação'}', style: const TextStyle(color: Colors.white)),
        content: Container( // Use Container para limitar a altura do diálogo
           width: double.maxFinite,
           height: 300, // Ajuste a altura conforme necessário
           child: ListView.builder(
              itemCount: _allUsers.length,
              itemBuilder: (context, index) {
                final user = _allUsers[index];
                return ListTile(
                  title: Text(user.username ?? 'Usuário Desconhecido', style: const TextStyle(color: Colors.white)),
                  subtitle: Text('ID: ${user.id}', style: const TextStyle(color: Colors.white70)),
                  onTap: () {
                    // Ao tocar, seleciona o usuário e fecha o diálogo
                    selectedUser = user; // Armazena o usuário selecionado
                    Navigator.pop(context); // Fecha o diálogo de seleção
                  },
                );
              },
           ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Fechar apenas o diálogo de seleção
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );

    // Lógica após o diálogo de seleção de usuário fechar
    if (selectedUser != null) {
      // Chamar o diálogo de confirmação FINAL antes de transferir
      final bool confirmTransfer = await showDialog<bool>( // Espera a resposta do diálogo de confirmação
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirmar Transferência', style: TextStyle(color: Colors.white)),
          content: Text('Tem certeza que deseja transferir a liderança da federação "${federation.name ?? 'esta federação'}" para o usuário "${selectedUser!.username ?? 'este usuário'}"?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context, false), // Retorna false ao cancelar
            ),
            TextButton(
              child: const Text('Transferir', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () => Navigator.pop(context, true), // Retorna true ao confirmar
            ),
          ],
        ),
      ) ?? false; // Retorna false se o diálogo for dismissido sem botão

      if (confirmTransfer) {
        _performFederationLeadershipTransfer(federation.id, selectedUser!.id, federation.name);
      }
    }
  }

  // Função para realizar a transferência de liderança da Federação via API
  Future<void> _performFederationLeadershipTransfer(String federationId, String newLeaderId, String? federationName) async {
    setState(() => _isLoadingFederations = true); // Opcional: mostrar loading enquanto a API responde
    try {
      final apiService = ApiService();
      // Assumindo um endpoint PUT para transferência de liderança, ajuste conforme sua API
      final response = await apiService.put(
        "/api/admin/federations/$federationId/transfer-leadership",
        {
          "newLeaderId": newLeaderId,
        },
      );

      // Verificar a resposta da API
      if (response["success"] == true) { // Adapte a verificação de sucesso conforme a sua API
        _showSnackBar('Liderança da federação "${federationName ?? 'Federação'}" transferida com sucesso!');
        _loadFederationsData(); // Recarregar a lista de federações para refletir a mudança
      } else {
        // Lidar com erro retornado pela API
        final errorMessage = response["message"] ?? "Erro desconhecido ao transferir liderança.";
        _showSnackBar('Falha ao transferir liderança: $errorMessage', isError: true);
      }
    } catch (e, s) {
      Logger.error('Erro ao transferir liderança da federação $federationId:', error: e, stackTrace: s);
      _showSnackBar('Erro ao transferir liderança: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingFederations = false); // Opcional: esconder loading
    }
  }

  // Diálogo para criar um novo Clã
  Future<void> _showCreateClanDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController tagController = TextEditingController();
    User? selectedLeader; // Para selecionar o líder do clã

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text('Criar Novo Clã', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nome do Clã",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(
                  labelText: "Tag do Clã",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              // Dropdown ou lista para selecionar o líder
              ListTile(
                title: Text(
                  selectedLeader == null ? "Selecionar Líder" : "Líder: ${selectedLeader.username ?? 'Usuário Desconhecido'}",
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
                onTap: () async {
                  final User? user = await _selectUserDialog();
                  if (user != null) {
                    setState(() {
                      selectedLeader = user;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty || tagController.text.isEmpty || selectedLeader == null) {
                _showSnackBar('Preencha todos os campos e selecione um líder.', isError: true);
                return;
              }
              try {
                final clanService = Provider.of<ClanService>(context, listen: false);
                final success = await clanService.createClan({
 'name': nameController.text,
 'tag': tagController.text,
 'leaderId': selectedLeader!.id,
 });
                if (success) {
                  _showSnackBar('Clã "${nameController.text}" criado com sucesso!');
                  _loadClans(); // Recarregar a lista de clãs
                  Navigator.pop(context);
                } else {
                  _showSnackBar('Falha ao criar clã.', isError: true);
                }
              } catch (e, s) {
                Logger.error('Erro ao criar clã:', error: e, stackTrace: s);
                _showSnackBar('Erro ao criar clã: ${e.toString()}', isError: true);
              }
            },
            child: const Text('Criar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  // Diálogo para selecionar um usuário (reutilizável)
  Future<User?> _selectUserDialog() async {
    return await showDialog<User?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text('Selecionar Usuário', style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _allUsers.length,
            itemBuilder: (context, index) {
              final user = _allUsers[index];
              return ListTile(
                title: Text(user.username ?? 'Usuário Desconhecido', style: const TextStyle(color: Colors.white)),
                subtitle: Text('ID: ${user.id}', style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context, user);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // Diálogo para transferir liderança de Clã
  Future<void> _showTransferClanLeadershipDialog(Clan clan) async {
    User? selectedUser; // Variável para armazenar o usuário selecionado

    await showDialog<void>( // Usamos await para esperar o diálogo fechar
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text('Transferir Liderança de ${clan.name ?? 'Clã'}', style: const TextStyle(color: Colors.white)),
        content: Container(
           width: double.maxFinite,
           height: 300,
           child: ListView.builder(
              itemCount: _allUsers.length,
              itemBuilder: (context, index) {
                final user = _allUsers[index];
                return ListTile(
                  title: Text(user.username ?? 'Usuário Desconhecido', style: const TextStyle(color: Colors.white)),
                  subtitle: Text('ID: ${user.id}', style: const TextStyle(color: Colors.white70)),
                  onTap: () {
                    selectedUser = user;
                    Navigator.pop(context);
                  },
                );
              },
           ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Fechar apenas o diálogo de seleção
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );

    if (selectedUser != null) {
      final bool confirmTransfer = await showDialog<bool>( // Espera a resposta do diálogo de confirmação
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirmar Transferência', style: TextStyle(color: Colors.white)),
          content: Text('Tem certeza que deseja transferir a liderança do clã "${clan.name ?? 'este clã'}" para o usuário "${selectedUser!.username ?? 'este usuário'}"?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text('Transferir', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ?? false;

      if (confirmTransfer) {
        _performClanLeadershipTransfer(clan.id, selectedUser!.id, clan.name);
      }
    }
  }

  // Função para realizar a transferência de liderança do Clã via API
  Future<void> _performClanLeadershipTransfer(String clanId, String newLeaderId, String? clanName) async {
    setState(() => _isLoadingClans = true);
    try {
      final apiService = ApiService();
      final response = await apiService.put(
        "/api/admin/clans/$clanId/transfer-leadership",
        {
          "newLeaderId": newLeaderId,
        },
      );

      if (response["success"] == true) {
        _showSnackBar('Liderança do clã "${clanName ?? 'Clã'}" transferida com sucesso!');
        _loadClans();
      } else {
        final errorMessage = response["message"] ?? "Erro desconhecido ao transferir liderança.";
        _showSnackBar('Falha ao transferir liderança: $errorMessage', isError: true);
      }
    } catch (e, s) {
      Logger.error('Erro ao transferir liderança do clã $clanId:', error: e, stackTrace: s);
      _showSnackBar('Erro ao transferir liderança: ${e.toString()}', isError: true);
    }
  }

  // Diálogo para gerenciar membros do Clã
  Future<void> _showManageClanMembersDialog(Clan clan) async {
    // Carregar membros do clã e usuários disponíveis
    List<User> clanMembers = [];
    List<User> availableUsers = [];
    bool loadingMembers = true;

    try {
      final apiService = ApiService();
      final membersResponse = await apiService.get("/api/clans/${clan.id}/members");
      clanMembers = (membersResponse["members"] as List)
          .map((user) => User.fromJson(user))
          .toList();

      // Filtrar usuários que já estão no clã
      availableUsers = _allUsers.where((user) => !clanMembers.any((member) => member.id == user.id)).toList();
    } catch (e, s) {
      Logger.error('Erro ao carregar membros do clã ou usuários disponíveis:', error: e, stackTrace: s);
      _showSnackBar('Erro ao carregar membros: ${e.toString()}', isError: true);
    } finally {
      loadingMembers = false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF212121),
            title: Text('Gerenciar Membros - ${clan.name ?? 'Clã'}', style: const TextStyle(color: Colors.white)),
            content: loadingMembers
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Membros Atuais
                        const Text('Membros Atuais', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (clanMembers.isEmpty)
                          const Text('Nenhum membro no clã.', style: TextStyle(color: Colors.white70))
                        else
                          ...clanMembers.map((member) => ListTile(
                            title: Text(member.username ?? 'Usuário Desconhecido', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Papel: ${member.clanRole?.displayName ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) => _handleClanMemberAction(clan, member, action, setState), // Passar setState
                              itemBuilder: (context) => <PopupMenuEntry<String>>[
                                if ((member.clanRole != Role.clanLeader) as bool) // Não pode rebaixar o líder
                                  const PopupMenuItem<String>(
                                    value: "promote_leader",
                                    child: Text("Promover a Líder"),
                                  ),
                                if ((member.clanRole != Role.clanMember) as bool) // Não pode promover o membro
                                  const PopupMenuItem<String>( // Add const
                                    value: "demote",
                                    child: Text("Rebaixar a Membro"),
                                  ),
                                const PopupMenuItem<String>(
                                  value: "remove",
                                  child: Text("Remover do Clã"),
                                ),
                              ],
                            ),
                          )).toList(),
                        const Divider(color: Colors.white70),
                        // Adicionar Membros
                        const Text('Adicionar Membros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (availableUsers.isEmpty)
                          const Text('Nenhum usuário disponível para adicionar.', style: TextStyle(color: Colors.white70))
                        else
                          ...availableUsers.map((user) => ListTile(
                            title: Text(user.username ?? 'Usuário Desconhecido', style: const TextStyle(color: Colors.white)),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                              onPressed: () => _addMemberToClan(clan, user, setState), // Passar setState
                            ),
                          )).toList(),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
    _loadClans(); // Recarregar clãs após fechar o gerenciamento de membros
    _loadAdminData(); // Recarregar dados do admin para atualizar a lista de usuários
  }

  // Ações para membros do clã (promover, rebaixar, remover)
  Future<void> _handleClanMemberAction(Clan clan, User member, String action, StateSetter setState) async {
    try {
      final apiService = ApiService();
      String endpoint;
      // Map<String, dynamic> body = {}; // Removed unused variable
      switch (action) {
        case "promote_leader": // Changed from "promote"
        case "promote":
          endpoint = "/api/admin/clans/${clan.id}/members/${member.id}/promote";
          break;
        case "demote":
          endpoint = "/api/admin/clans/${clan.id}/members/${member.id}/demote";
          break;
        case "remove":
          endpoint = "/api/admin/clans/${clan.id}/members/${member.id}/remove";
          break;
        default:
          return;
      }

      final response = await apiService.post(endpoint, {}); // Assumindo POST para essas ações, body vazio conforme exemplo

      if (response["success"] == true) {
        _showSnackBar('Membro ${member.username ?? 'Usuário'} ${action == "promote_leader" ? "promovido" : action == "demote" ? "rebaixado" : "removido"} com sucesso!'); // Updated action message
        // Recarregar membros do clã dentro do diálogo
        List<User> updatedClanMembers = (response["members"] as List) // Assumindo que a API retorna a lista atualizada
            .map((user) => User.fromJson(user)) // Corrected variable name
            .toList();
        List<User> updatedAvailableUsers = _allUsers.where((user) => !updatedClanMembers.any((m) => m.id == user.id)).toList();
        setState(() {
          // Atualizar as listas no StatefulBuilder
          // clanMembers = updatedClanMembers;
          // availableUsers = updatedAvailableUsers;
        });
        Navigator.pop(context); // Fechar o diálogo atual
        _showManageClanMembersDialog(clan); // Abrir novamente com dados atualizados
      } else {
        final errorMessage = response["message"] ?? "Erro desconhecido.";
        _showSnackBar('Falha ao ${action} membro: $errorMessage', isError: true);
      }
    } catch (e, s) {
      Logger.error('Erro ao ${action} membro do clã:', error: e, stackTrace: s);
      _showSnackBar('Erro ao ${action} membro: ${e.toString()}', isError: true);
    }
  }

  // Adicionar membro ao clã
  Future<void> _addMemberToClan(Clan clan, User user, StateSetter setState) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        "/api/admin/clans/${clan.id}/members/${user.id}/add",
        {},
      );

      if (response["success"] == true) {
        _showSnackBar('Membro ${user.username ?? 'Usuário'} adicionado ao clã com sucesso!');
        // Recarregar membros do clã dentro do diálogo
        List<User> updatedClanMembers = (response["members"] as List)
            .map((u) => User.fromJson(u))
            .toList();
        List<User> updatedAvailableUsers = _allUsers.where((u) => !updatedClanMembers.any((m) => m.id == u.id)).toList();
        setState(() {
          // Atualizar as listas no StatefulBuilder
          // clanMembers = updatedClanMembers;
          // availableUsers = updatedAvailableUsers;
        });
        Navigator.pop(context); // Fechar o diálogo atual
        _showManageClanMembersDialog(clan); // Abrir novamente com dados atualizados
      } else {
        final errorMessage = response["message"] ?? "Erro desconhecido ao adicionar membro.";
        _showSnackBar('Falha ao adicionar membro: $errorMessage', isError: true);
      }
    } catch (e, s) {
      Logger.error('Erro ao adicionar membro ao clã:', error: e, stackTrace: s);
      _showSnackBar('Erro ao adicionar membro: ${e.toString()}', isError: true);
    }
  }

  // Diálogo para criar uma nova Federação
  Future<void> _showCreateFederationDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController tagController = TextEditingController();
    User? selectedLeader; // Para selecionar o líder da federação

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text('Criar Nova Federação', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nome da Federação",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(
                  labelText: "Tag da Federação",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              // Dropdown ou lista para selecionar o líder
              ListTile(
                title: Text(
                  selectedLeader == null ? "Selecionar Líder" : "Líder: ${selectedLeader.username ?? 'Usuário Desconhecido'}",
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
                onTap: () async {
                  final User? user = await _selectUserDialog();
                  if (user != null) {
                    setState(() {
                      selectedLeader = user;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty || tagController.text.isEmpty || selectedLeader == null) {
                _showSnackBar('Preencha todos os campos e selecione um líder.', isError: true);
                return;
              }
              try {
                final federationService = Provider.of<FederationService>(context, listen: false);
                final success = await federationService.createFederation(
                  {'name': nameController.text, 'tag': tagController.text, 'leaderId': selectedLeader!.id,},
                );
                if (success) {
                  _showSnackBar('Federação "${nameController.text}" criada com sucesso!');
                  _loadFederationsData(); // Recarregar a lista de federações
                  Navigator.pop(context);
                } else {
                  _showSnackBar('Falha ao criar federação.', isError: true);
                }
              } catch (e, s) {
                Logger.error('Erro ao criar federação:', error: e, stackTrace: s);
                _showSnackBar('Erro ao criar federação: ${e.toString()}', isError: true);
              }
            },
            child: const Text('Criar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  // Diálogo para gerenciar clãs de uma Federação
  Future<void> _showManageFederationClansDialog(Federation federation) async {
    List<Clan> federationClans = [];
    List<Clan> availableClans = [];
    bool loadingClans = true;

    try {
      final apiService = ApiService();
      final clansResponse = await apiService.get("/api/federations/${federation.id}/clans");
      federationClans = (clansResponse["clans"] as List)
          .map((clan) => Clan.fromJson(clan))
          .toList();

      // Filtrar clãs que já estão na federação
      availableClans = _allClans.where((clan) => !federationClans.any((fc) => fc.id == clan.id)).toList();
    } catch (e, s) {
      Logger.error('Erro ao carregar clãs da federação ou clãs disponíveis:', error: e, stackTrace: s);
      _showSnackBar('Erro ao carregar clãs: ${e.toString()}', isError: true);
    } finally {
      loadingClans = false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF212121),
            title: Text('Gerenciar Clãs - ${federation.name ?? 'Federação'}', style: const TextStyle(color: Colors.white)),
            content: loadingClans
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clãs Atuais na Federação
                        const Text('Clãs na Federação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (federationClans.isEmpty)
                          const Text('Nenhum clã nesta federação.', style: TextStyle(color: Colors.white70))
                        else
                          ...federationClans.map((clan) => ListTile(
                            title: Text(clan.name ?? 'Clã sem nome', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Tag: ${clan.tag ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                              onPressed: () => _removeClanFromFederation(federation, clan, setState), // Passar setState
                            ),
                          )).toList(),
                        const Divider(color: Colors.white70),
                        // Adicionar Clãs à Federação
                        const Text('Adicionar Clãs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (availableClans.isEmpty)
                          const Text('Nenhum clã disponível para adicionar.', style: TextStyle(color: Colors.white70))
                        else
                          ...availableClans.map((clan) => ListTile(
                            title: Text(clan.name ?? 'Clã sem nome', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Tag: ${clan.tag ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                              onPressed: () => _addClanToFederation(federation, clan, setState), // Passar setState
                            ),
                          )).toList(),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
    _loadFederationsData(); // Recarregar federações após fechar o gerenciamento de clãs
    _loadClans(); // Recarregar clãs para garantir que a lista de clãs disponíveis esteja atualizada
  }

  // Remover clã da federação
  Future<void> _removeClanFromFederation(Federation federation, Clan clan, StateSetter setState) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        "/api/admin/federations/${federation.id}/clans/${clan.id}/remove",
        {},
      );

      if (response["success"] == true) {
        _showSnackBar('Clã "${clan.name ?? 'Clã'}" removido da federação com sucesso!');
        // Recarregar clãs da federação dentro do diálogo
        List<Clan> updatedFederationClans = (response["clans"] as List)
            .map((c) => Clan.fromJson(c))
            .toList();
        List<Clan> updatedAvailableClans = _allClans.where((c) => !updatedFederationClans.any((fc) => fc.id == c.id)).toList();
        setState(() {
          // Atualizar as listas no StatefulBuilder
          // federationClans = updatedFederationClans;
          // availableUsers = updatedAvailableUsers;
        });
        Navigator.pop(context); // Fechar o diálogo atual
        _showManageFederationClansDialog(federation); // Abrir novamente com dados atualizados
      } else {
        final errorMessage = response["message"] ?? "Erro desconhecido ao remover clã da federação.";
        _showSnackBar('Falha ao remover clã da federação: $errorMessage', isError: true);
      }
    } catch (e, s) {
      Logger.error('Erro ao remover clã da federação:', error: e, stackTrace: s);
      _showSnackBar('Erro ao remover clã da federação: ${e.toString()}', isError: true);
    }
  }

  // Adicionar clã à federação
  Future<void> _addClanToFederation(Federation federation, Clan clan, StateSetter setState) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        "/api/admin/federations/${federation.id}/clans/${clan.id}/add",
        {},
      );

      if (response["success"] == true) {
        _showSnackBar('Clã "${clan.name ?? 'Clã'}" adicionado à federação com sucesso!');
        // Recarregar clãs da federação dentro do diálogo
        List<Clan> updatedFederationClans = (response["clans"] as List)
            .map((c) => Clan.fromJson(c))
            .toList();
        List<Clan> updatedAvailableClans = _allClans.where((c) => !updatedFederationClans.any((fc) => fc.id == c.id)).toList();
        setState(() {
          // Atualizar as listas no StatefulBuilder
          // federationClans = updatedFederationClans;
          // availableUsers = updatedAvailableUsers;
        });
        Navigator.pop(context); // Fechar o diálogo atual
        _showManageFederationClansDialog(federation); // Abrir novamente com dados atualizados
      } else {
        final errorMessage = response["message"] ?? "Erro desconhecido ao adicionar clã à federação.";
        _showSnackBar('Falha ao adicionar clã à federação: $errorMessage', isError: true);
      }
    } catch (e, s) {
      Logger.error('Erro ao adicionar clã à federação:', error: e, stackTrace: s);
      _showSnackBar('Erro ao adicionar clã à federação: ${e.toString()}', isError: true);
    }
  }

  // Diálogo para gerenciar membros de uma Federação
  Future<void> _showManageFederationMembersDialog(Federation federation) async {
    List<User> federationMembers = [];
    List<User> availableUsers = [];
    bool loadingMembers = true;

    try {
      final apiService = ApiService();
      final membersResponse = await apiService.get("/api/federations/${federation.id}/members");
      federationMembers = (membersResponse["members"] as List)
          .map((user) => User.fromJson(user))
          .toList();

      // Filtrar usuários que já estão na federação
      availableUsers = _allUsers.where((user) => !federationMembers.any((member) => member.id == user.id)).toList();
    } catch (e, s) {
      Logger.error('Erro ao carregar membros da federação ou usuários disponíveis:', error: e, stackTrace: s);
      _showSnackBar('Erro ao carregar membros: ${e.toString()}', isError: true);
    } finally {
      loadingMembers = false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF212121),
            title: Text('Gerenciar Membros - ${federation.name ?? 'Federação'}', style: const TextStyle(color: Colors.white)),
            content: loadingMembers
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Membros Atuais
                        const Text('Membros Atuais', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (federationMembers.isEmpty)
                          const Text('Nenhum membro na federação.', style: TextStyle(color: Colors.white70))
                        else
                          ...federationMembers.map((member) => ListTile(
                            title: Text(member.username ?? 'Usuário Desconhecido', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Papel: ${member.federationRole?.displayName ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) => _handleFederationMemberAction(federation, member, action, setState), // Passar setState
                              itemBuilder: (context) => <PopupMenuEntry<String>>[
                                if ((member.federationRole != Role.leader) as bool) // Não pode rebaixar o líder
                                  const PopupMenuItem<String>(
                                    value: "promote_leader",
                                    child: Text("Promover a Líder"),
                                  ),
                                if ((member.federationRole != Role.member) as bool) // Não pode promover o membro
                                  const PopupMenuItem<String>(
                                    value: "demote",
                                    child: Text("Rebaixar a Membro"),
                                  ),
                                const PopupMenuItem<String>(
                                    value: "remove",
                                    child: Text("Remover da Federação"),
                                  ),
                              ],
                            ),
                          )).toList(),
                        const Divider(color: Colors.white70),
                        // Adicionar Membros
                        const Text('Adicionar Membros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (availableUsers.isEmpty)
                          const Text('Nenhum usuário disponível para adicionar.', style: TextStyle(color: Colors.white70))
                        else
                          ...availableUsers.map((user) => ListTile(
                            title: Text(user.username ?? 'Usuário Desconhecido', style: const TextStyle(color: Colors.white)),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                              onPressed: () => _addMemberToFederation(federation, user, setState), // Passar setState
                            ),
                          )).toList(),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
    _loadFederationsData(); // Recarregar federações após fechar o gerenciamento de membros
    _loadAdminData(); // Recarregar dados do admin para atualizar a lista de usuários
  }

  // Ações para membros da federação (promover, rebaixar, remover)
  Future<void> _handleFederationMemberAction(Federation federation, User member, String action, StateSetter setState) async {
    try {
      final apiService = ApiService();
      String endpoint;
      // Map<String, dynamic> body = {}; // Removed unused variable
      switch (action) {
        case "promote_leader": // Changed from "promote"
        case "promote":
          endpoint = "/api/admin/federations/${federation.id}/members/${member.id}/promote";
          break;
        case "demote":
          endpoint = "/api/admin/federations/${federation.id}/members/${member.id}/demote";
          break;
        case "remove":
          endpoint = "/api/admin/federations/${federation.id}/members/${member.id}/remove";
          break;
        default:
          return;
      }

      final response = await apiService.post(endpoint, {}); // Assumindo POST para essas ações, body vazio conforme example

      if (response["success"] == true) {
        _showSnackBar('Membro ${member.username ?? 'Usuário'} ${action == "promote_leader" ? "promovido" : action == "demote" ? "rebaixado" : "removido"} com sucesso!'); // Updated action message
        // Recarregar membros da federação dentro do diálogo
        List<User> updatedFederationMembers = (response["members"] as List)
            .map((user) => User.fromJson(user)) // Corrected variable name
            .toList();
        List<User> updatedAvailableUsers = _allUsers.where((user) => !updatedFederationMembers.any((m) => m.id == user.id)).toList();
        setState(() {
          // Atualizar as listas no StatefulBuilder
          // federationMembers = updatedFederationMembers;
          // availableUsers = updatedAvailableUsers;
        });
        Navigator.pop(context); // Fechar o diálogo atual
        _showManageFederationMembersDialog(federation); // Abrir novamente com dados atualizados
      } else {
        final errorMessage = response["message"] ?? "Erro desconhecido.";
        _showSnackBar('Falha ao ${action} membro: $errorMessage', isError: true);
      }
    } catch (e, s) {
      Logger.error('Erro ao ${action} membro da federação:', error: e, stackTrace: s);
      _showSnackBar('Erro ao ${action} membro: ${e.toString()}', isError: true);
    }
  }

  // Adicionar membro à federação
  Future<void> _addMemberToFederation(Federation federation, User user, StateSetter setState) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        "/api/admin/federations/${federation.id}/members/${user.id}/add",
        {},
      );

      if (response["success"] == true) {
        _showSnackBar('Membro ${user.username ?? 'Usuário'} adicionado à federação com sucesso!');
        // Recarregar membros da federação dentro do diálogo
        List<User> updatedFederationMembers = (response["members"] as List)
            .map((u) => User.fromJson(u))
            .toList();
        List<User> updatedAvailableUsers = _allUsers.where((u) => !updatedFederationMembers.any((m) => m.id == u.id)).toList();
        setState(() {
          // Atualizar as listas no StatefulBuilder
          // federationMembers = updatedFederationMembers;
          // availableUsers = updatedAvailableUsers;
        });
        Navigator.pop(context); // Fechar o diálogo atual
        _showManageFederationMembersDialog(federation); // Abrir novamente com dados atualizados
      } else {
        final errorMessage = response["message"] ?? "Erro desconhecido ao adicionar membro.";
        _showSnackBar('Falha ao adicionar membro: $errorMessage', isError: true);
      }
    } catch (e, s) {
      Logger.error('Erro ao adicionar membro à federação:', error: e, stackTrace: s);
      _showSnackBar('Erro ao adicionar membro: ${e.toString()}', isError: true);
    }
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.admMaster: return Colors.red; // Cor para ADM Master
      case Role.leader: return Colors.orange;
      case Role.subLeader: return const Color(0xFFFBC02D);
      case Role.member: return Colors.blue;
      case Role.user: return Colors.grey;
      case Role.clanLeader: return Colors.orange; // Manter para compatibilidade se ainda usado
      case Role.clanSubLeader: return const Color(0xFFFBC02D); // Manter para compatibilidade se ainda usado
      case Role.clanMember: return Colors.blue; // Manter para compatibilidade se ainda usado
      case Role.guest: return Colors.grey;
    }
  }

  IconData _getLogIcon(String? type) {
    switch (type) {
      case "error": return Icons.error;
      case "warning": return Icons.warning;
      case "info": return Icons.info;
      default: return Icons.notes;
    }
  }

  Color _getLogColor(String? type) {
    switch (type) {
      case "error": return Colors.red;
      case "warning": return Colors.orange;
      case "info": return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

