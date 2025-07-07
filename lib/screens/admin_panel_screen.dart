import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminData();
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

  @override
  Widget build(BuildContext context) {
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
                user.username[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user.username,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
 user.username,
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
                if (user.role != Role.federationAdmin)
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
            Role.adm.displayName, // Usando displayName
            "Controle total do sistema",
            Icons.admin_panel_settings,
            Colors.red,
            [
              "Gerenciar todos os usuários",
              "Criar/excluir clãs",
              "Acessar logs do sistema",
              "Configurar servidor",
              "Promover outros admins (limitado)",
            ],
          ),
          _buildPermissionCard(
            Role.clanLeader.displayName, // Usando displayName
            "Gerencia membros do clã",
            Icons.star,
            Colors.orange,
            [
              "Promover/rebaixar membros",
              "Expulsar membros",
              "Criar canais de voz",
              "Moderar chat do clã",
            ],
          ),
          _buildPermissionCard(
            Role.clanSubLeader.displayName, // Usando displayName
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
            Role.clanMember.displayName, // Usando displayName
            "Participante ativo",
            Icons.person,
            Colors.blue,
            [
              "Participar de chamadas",
              "Enviar mensagens",
              "Acessar canais do clã",
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
                  "Admins",
                  _allUsers.where((u) => u.role == Role.federationAdmin).length.toString(),
                  Icons.admin_panel_settings,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReportCard(
                  "Líderes",
                  _allUsers.where((u) => u.role == Role.clanLeader).length.toString(),
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
              log["message"] ?? "Log sem mensagem",
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              log["timestamp"] ?? "Sem timestamp",
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
        title: Text("Editar Papel - ${user.username}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Role.values.map((role) => ListTile(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Papel de ${user.username} alterado para ${value.displayName} com sucesso!")),
                      );
                    }
                  } catch (e) {
                    Logger.error("Erro ao alterar papel: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erro ao alterar papel: $e")),
                      );
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
        title: Text("Detalhes - ${user.username}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${user.id}", style: const TextStyle(color: Colors.white)),
 Text("Usuário: ${user.username}", style: const TextStyle(color: Colors.white)),
            Text("Papel: ${user.role.displayName}", style: const TextStyle(color: Colors.white)),
            Text("Online: ${user.online ? "Sim" : "Não"}", style: const TextStyle(color: Colors.white)),
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
    // Implementar lógica para resetar senha
    Logger.info("Resetar senha para ${user.username}");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Funcionalidade de reset de senha para ${user.username} ainda não implementada.")),
      );
    }
  }

  void _showSuspendDialog(User user) {
    // Implementar lógica para suspender usuário
    Logger.info("Suspender usuário ${user.username}");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Funcionalidade de suspensão de usuário para ${user.username} ainda não implementada.")),
      );
    }
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.adm: return Colors.red;
      case Role.adminReivindicado: return Colors.deepOrange;
      case Role.descolado: return Colors.yellow;
      case Role.leader: return Colors.orange;
      case Role.subLeader: return const Color(0xFFFBC02D);
      case Role.member: return Colors.blue;
      case Role.user: return Colors.grey;
      case Role.federationAdmin: return Colors.red;
      case Role.clanLeader: return Colors.orange;
      case Role.clanSubLeader: return const Color(0xFFFBC02D);
      case Role.clanMember: return Colors.blue;
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


