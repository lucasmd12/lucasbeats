import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/screens/clan_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';

class ClanListScreen extends StatefulWidget {
  final String federationId;

  const ClanListScreen({super.key, required this.federationId});

  @override
  State<ClanListScreen> createState() => _ClanListScreenState();
}

class _ClanListScreenState extends State<ClanListScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClanService>(context, listen: false).fetchClansByFederation(widget.federationId);
    });
  }

  void _showCreateClanDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Novo Clã'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome do Clã'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(labelText: 'Tag do Clã (Opcional)'),
              ),
            ],
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
                final String name = nameController.text.trim();
                final String tag = tagController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome do clã não pode ser vazio.')),
                  );
                  return;
                }

                final clanService = Provider.of<ClanService>(context, listen: false);

                try {
                  final dynamic newClan = await clanService.createClan({
                    "name": name,
                    "tag": tag.isNotEmpty ? tag : null,
                    "federationId": widget.federationId,
                  });

                  if (mounted) {
                    if (newClan != null && newClan is Clan) {
                      clanService.fetchClansByFederation(widget.federationId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Clã "${newClan.name}" criado com sucesso!')),
                      );
                      Navigator.of(context).pop();
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro ao criar clã. Tente novamente mais tarde.')),
                      );
                    }
                  }
                } catch (e) {
                  Logger.error("Erro ao criar clã:", error: e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar clã: ${e.toString()}')),
                  );
                } finally {
                   Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    final bool canCreateClan = currentUser != null && (currentUser.role == Role.adm || currentUser.role == Role.federationAdmin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clãs da Federação'),
        actions: [
          if (canCreateClan)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Logger.info('Botão Adicionar Clã pressionado por usuário com permissão.');
                _showCreateClanDialog();
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
                  leading: clan.flag != null && clan.flag!.isNotEmpty
 ? CachedNetworkImage(
                          imageUrl: clan.flag!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.shield),
                        )
                      : const Icon(Icons.shield),
 subtitle: Text('Tag Clã: ${clan.tag}'),
                  title: Text(clan.name),
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