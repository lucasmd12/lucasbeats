import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart'; // Importar Clan
import 'package:lucasbeatsfederacao/widgets/clan_info_widget.dart';
import 'package:lucasbeatsfederacao/screens/tabs/members_tab.dart';
import 'package:lucasbeatsfederacao/screens/tabs/settings_tab.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart'; // Importar ClanService
import 'package:lucasbeatsfederacao/utils/logger.dart'; // Importar Logger

class ClanManagementScreen extends StatefulWidget {
  final String clanId;

  const ClanManagementScreen({super.key, this.clanId});

  @override
  State<ClanManagementScreen> createState() => _ClanManagementScreenState(); // Corrigido
}

class _ClanManagementScreenState extends State<ClanManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  // Adicionadas as variáveis de estado para o clã
  Clan? _clan; 
  bool _isLoadingClan = true;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Definido length para 3
    _loadClanDetails(); // Carregar detalhes do clã
  }

  // Função para carregar detalhes do clã
  Future<void> _loadClanDetails() async {
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final clanDetails = await clanService.getClanDetails(widget.clanId);
      if (mounted) {
        setState(() {
          _clan = clanDetails; // Atribui o clã carregado
          _isLoadingClan = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar detalhes do clã', error: e);
      if (mounted) {
        setState(() {
          _isLoadingClan = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentUser;
        
        // Verificar se o usuário é líder de clã, admin de federação ou admin geral
        if (currentUser?.role != Role.clanLeader && currentUser?.role != Role.admMaster && currentUser?.role != Role.federationLeader) {
         return Scaffold(
            appBar: AppBar(
              title: const Text('Acesso Negado'),
              backgroundColor: Colors.red,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Acesso restrito a líderes de clã, federação ou ADM Master',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Gerenciamento do Clã'),
              ],
            ),
            backgroundColor: Colors.blue.shade900,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade400,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Dashboard', icon: Icon(Icons.dashboard, size: 16)),
                Tab(text: 'Membros', icon: Icon(Icons.people, size: 16)),
                Tab(text: 'Configurações', icon: Icon(Icons.settings, size: 16)),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900,
                  Colors.black,
                ],
              ),
            ),
            child: TabBarView(
              controller: _tabController, // Mantém o controller
              // Exibe indicador de carregamento ou o conteúdo
              children: _isLoadingClan 
                  ? [const Center(child: CircularProgressIndicator())] 
                  : _clan == null 
                      ? [const Center(child: Text('Clã não encontrado', style: TextStyle(color: Colors.white)))]
                      : [
                          ClanInfoWidget(clanId: widget.clanId), // Mantém este widget
                          MembersTab(clanId: widget.clanId, clan: _clan!), // Passa o objeto clan
                          SettingsTab(clanId: widget.clanId), // Não passa o objeto clan
                        ],
            ),
            ),
        );
      },
    );
  }
}


