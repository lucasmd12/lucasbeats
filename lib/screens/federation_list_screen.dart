import 'package:flutter/material.dart';
import 'package:provider/provider';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/federation_detail_screen.dart';

class FederationListScreen extends StatefulWidget {
  const FederationListScreen({super.key});

  @override
  State<FederationListScreen> createState() => _FederationListScreenState();
}

class _FederationListScreenState extends State<FederationListScreen> {
  @override
  void initState() {
    super.initState();
    // Opcional: Carregar federações ao iniciar a tela
    // Provider.of<FederationService>(context, listen: false).fetchFederations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Federações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implementar criação de federação (apenas ADM)
              Logger.info('Botão Adicionar Federação pressionado');
            },
          ),
        ],
      ),
      body: Consumer<FederationService>(
        builder: (context, federationService, child) {
          if (federationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (federationService.federations.isEmpty) {
            return const Center(child: Text('Nenhuma federação encontrada.'));
          }

          return ListView.builder(
            itemCount: federationService.federations.length,
            itemBuilder: (context, index) {
              final federation = federationService.federations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.account_tree),
                  title: Text(federation.name),
                  subtitle: Text(federation.description),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FederationDetailScreen(federation: federation),
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


