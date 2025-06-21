import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class ClanDetailScreen extends StatelessWidget {
  final Clan clan;

  const ClanDetailScreen({super.key, required this.clan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(clan.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (clan.bannerImageUrl != null && clan.bannerImageUrl!.isNotEmpty)
              Image.network(
                clan.bannerImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
              ),
            const SizedBox(height: 16),
            Text(
              'Tag: ${clan.tag}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Líder ID: ${clan.leaderId}', // Será substituído pelo nome do líder
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              clan.description ?? 'Nenhuma descrição disponível.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Regras:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              clan.rules ?? 'Nenhuma regra definida.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Membros:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (clan.members == null || clan.members!.isEmpty)
              const Text('Nenhum membro neste clã ainda.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clan.members!.length,
                itemBuilder: (context, index) {
                  final memberId = clan.members![index];
                  return ListTile(
                    title: Text('Membro ID: $memberId'), // Será substituído pelo nome do membro e cargo
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Cargos dos Membros:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (clan.memberRoles == null || clan.memberRoles!.isEmpty)
              const Text('Nenhum cargo definido para membros.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clan.memberRoles!.length,
                itemBuilder: (context, index) {
                  final role = clan.memberRoles![index];
                  return ListTile(
                    title: Text('Usuário: ${role['userId']} - Cargo: ${role['roleName']}'),
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Canais de Voz:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (clan.voiceChannels == null || clan.voiceChannels!.isEmpty)
              const Text('Nenhum canal de voz neste clã.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clan.voiceChannels!.length,
                itemBuilder: (context, index) {
                  final channel = clan.voiceChannels![index];
                  return ListTile(
                    title: Text('Canal de Voz ID: $channel'),
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Canais de Texto:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (clan.textChannels == null || clan.textChannels!.isEmpty)
              const Text('Nenhum canal de texto neste clã.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clan.textChannels!.length,
                itemBuilder: (context, index) {
                  final channel = clan.textChannels![index];
                  return ListTile(
                    title: Text('Canal de Texto ID: $channel'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}


