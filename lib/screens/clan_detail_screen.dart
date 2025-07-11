import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/screens/tabs/members_tab.dart'; // Import MembersTab
import 'package:lucasbeatsfederacao/screens/tabs/settings_tab.dart'; // Import SettingsTab

class ClanDetailScreen extends StatefulWidget {
  final Clan clan;

  const ClanDetailScreen({super.key, required this.clan});

  @override
  State<ClanDetailScreen> createState() => _ClanDetailScreenState();
}

class _ClanDetailScreenState extends State<ClanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // DefaultTabController no AppBar para tabs na AppBar inferior
        title: Text(widget.clan.name), // Título com o nome do clã
        bottom: TabBar(
          tabs: [
            Tab(text: 'Membros'),
            Tab(text: 'Configurações'),
          ],
        ),
      ),
      body: DefaultTabController( // Adicionado DefaultTabController para gerenciar as tabs
        length: 2, // Número de tabs
        child: TabBarView( // TabBarView para exibir o conteúdo das tabs
          children: [
            MembersTab(clanId: widget.clan.id), // Passa o clanId para MembersTab
            SettingsTab(clanId: widget.clan.id), // Passa o clanId para SettingsTab
          ],
        ),
      ),
    );
  }
}


