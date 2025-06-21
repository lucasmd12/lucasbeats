import 'package:flutter/material.dart';
import 'package:provider/provider';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/clan_detail_screen.dart';

class ClanListScreen extends StatefulWidget {
  final String federationId;

  const ClanListScreen({super.key, required this.federationId});

  @override
  State<ClanListScreen> createState() => _ClanListScreenState();
}

class _ClanListScreenState extends State<ClanListScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar clãs da federação ao iniciar a tela
    Provider.of<ClanService>(context, listen: false).fetchClansByFederation(widget.federationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clãs da Federação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implementar criação de clã (apenas ADM/Líder de Federação)
              Logger.info('Botão Adicionar Clã pressionado');
            },
          ),
        ],
      ),
      body: Consumer<ClanService>(
        builder: (context, clanService, child) {
          if (clanService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (clanService.clans.isEmpty) {
            return const Center(child: Text('Nenhum clã encontrado nesta federação.'));
          }

          return ListView.builder(
            itemCount: clanService.clans.length,
            itemBuilder: (context, index) {
              final clan = clanService.clans[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.shield),
                  title: Text(clan.name),
                  subtitle: Text('Tag: ${clan.tag}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClanDetailScreen(clan: clan),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}


