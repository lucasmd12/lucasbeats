import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/clan_list_screen.dart'; // Nova tela para listar clãs

class FederationDetailScreen extends StatelessWidget {
  final Federation federation;

  const FederationDetailScreen({super.key, required this.federation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(federation.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (federation.banner != null && federation.banner!.isNotEmpty)
              Image.network(
                federation.banner!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
              ),
            const SizedBox(height: 16),
            Text(
              'Líder: ${federation.leader.username}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              federation.description ?? 'Nenhuma descrição disponível.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Regras:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              federation.rules ?? 'Nenhuma regra definida.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Logger.info('Botão Ver Clãs pressionado para federação ${federation.name}');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ClanListScreen(federationId: federation.id),
                  ),
                );
              },
              child: const Text('Ver Clãs desta Federação'),
            ),
            const SizedBox(height: 16),
            Text(
              'Clãs na Federação:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (federation.clans.isEmpty)
              const Text('Nenhum clã nesta federação ainda.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: federation.clans.length,
                itemBuilder: (context, index) {
                  final clan = federation.clans[index];
                  return ListTile(
                    title: Text(clan.name),
                    subtitle: Text('Tag: ${clan.tag ?? 'N/A'}'),
                    // TODO: Adicionar onTap para ir para ClanDetailScreen
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Aliados:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (federation.allies.isEmpty)
              const Text('Nenhum aliado definido.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: federation.allies.length,
                itemBuilder: (context, index) {
                  final ally = federation.allies[index];
                  return ListTile(
                    title: Text(ally.name),
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Inimigos:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (federation.enemies.isEmpty)
              const Text('Nenhum inimigo definido.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: federation.enemies.length,
                itemBuilder: (context, index) {
                  final enemy = federation.enemies[index];
                  return ListTile(
                    title: Text(enemy.name),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}


