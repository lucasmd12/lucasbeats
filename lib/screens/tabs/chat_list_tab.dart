import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/canal_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart'; // Para obter o UID e dados do usuário atual
import '../../utils/logger.dart';
import '../../services/chat_service.dart'; // Assumindo que teremos um serviço para gerenciar canais

class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key});

  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService(); // Instancia o serviço

  String? _meuCanalAtual;

  @override
  void initState() {
    super.initState();
    _carregarCanalAtual();
    // Escuta mudanças no UserProvider para atualizar o canal atual se necessário
    // Isso pode ser útil se o canal for alterado em outra parte do app
    Provider.of<UserProvider>(context, listen: false).addListener(_carregarCanalAtual);
  }

  @override
  void dispose() {
    Provider.of<UserProvider>(context, listen: false).removeListener(_carregarCanalAtual);
    super.dispose();
  }

  /// Carrega o canal atual do usuário logado a partir do Firestore ou Provider
  Future<void> _carregarCanalAtual() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      // CORREÇÃO: Usar userProvider.user?.canal em vez de userProvider.userModel?.canal
      // Tenta obter do provider primeiro (pode ser mais rápido se já carregado)
      if (userProvider.user?.canal != _meuCanalAtual) {
         if (mounted) { // Verifica se o widget ainda está montado
            setState(() {
              // CORREÇÃO: Usar userProvider.user?.canal
              _meuCanalAtual = userProvider.user?.canal;
              Logger.info("Canal atual (via Provider): $_meuCanalAtual");
            });
         }
      }
      // Confirma com o Firestore para garantir consistência
      try {
        final userDoc = await _firestore.collection('users').doc(userProvider.user!.uid).get();
        if (userDoc.exists && mounted) {
          final canalFirestore = userDoc.data()?['canal'];
          if (canalFirestore != _meuCanalAtual) {
            setState(() {
              _meuCanalAtual = canalFirestore;
              Logger.info("Canal atual (via Firestore): $_meuCanalAtual");
            });
          }
        }
      } catch (e, s) {
        Logger.error("Erro ao buscar canal atual do Firestore", error: e, stackTrace: s);
      }
    }
  }

  /// Lógica para entrar em um canal de voz
  Future<void> _entrarNoCanal(String canalId, String nomeCanal) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Logger.error("Usuário não logado, impossível entrar no canal.");
      return;
    }

    Logger.info("Usuário $userId tentando entrar no canal $canalId ($nomeCanal)");

    try {
      // Se já estiver em um canal, sai dele primeiro
      if (_meuCanalAtual != null && _meuCanalAtual!.isNotEmpty) {
        await _chatService.sairDoCanal(userId, _meuCanalAtual!);
      }

      // Entra no novo canal
      await _chatService.entrarNoCanal(userId, canalId);

      // Atualiza o estado local imediatamente para feedback rápido
      if (mounted) {
        setState(() {
          _meuCanalAtual = nomeCanal; // Usa o nome para exibição
        });
      }
      Logger.info("Usuário $userId entrou no canal $canalId com sucesso.");
      // TODO: Iniciar a lógica de conexão WebRTC aqui

    } catch (e, s) {
      Logger.error("Erro ao entrar no canal $canalId", error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao entrar no canal: ${e.toString()}')),
        );
      }
    }
  }

  /// Lógica para sair do canal de voz atual
  Future<void> _sairDoCanal() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _meuCanalAtual == null || _meuCanalAtual!.isEmpty) {
      Logger.warning("Usuário não está em um canal ou não está logado.");
      return;
    }

    Logger.info("Usuário $userId tentando sair do canal $_meuCanalAtual");
    // Precisamos do ID do canal, não apenas do nome, para atualizar o Firestore.
    // Vamos buscar o ID baseado no nome armazenado em _meuCanalAtual.
    try {
       final canalSnapshot = await _firestore.collection('canais').where('nome', isEqualTo: _meuCanalAtual).limit(1).get();
       if (canalSnapshot.docs.isNotEmpty) {
          final canalId = canalSnapshot.docs.first.id;
          await _chatService.sairDoCanal(userId, canalId);
          if (mounted) {
            setState(() {
              _meuCanalAtual = null;
            });
          }
          Logger.info("Usuário $userId saiu do canal $canalId com sucesso.");
          // TODO: Desconectar a lógica WebRTC aqui
       } else {
         Logger.error("Não foi possível encontrar o ID do canal '$_meuCanalAtual' para sair.");
         // Força a limpeza local se o canal não for encontrado no DB
         if (mounted) {
            setState(() {
              _meuCanalAtual = null;
            });
          }
       }
    } catch (e, s) {
      Logger.error("Erro ao sair do canal $_meuCanalAtual", error: e, stackTrace: s);
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair do canal: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false); // Não precisa ouvir aqui
    final currentUserId = userProvider.user?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('canais').where('ativo', isEqualTo: true).orderBy('nome').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          Logger.error("Erro ao carregar canais", error: snapshot.error);
          return Center(child: Text('Erro ao carregar canais: ${snapshot.error}', style: theme.textTheme.bodyMedium));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Nenhum canal de voz ativo encontrado.', style: theme.textTheme.bodyMedium));
        }

        final canais = snapshot.data!.docs;

        return ListView.builder(
          itemCount: canais.length,
          itemBuilder: (context, index) {
            final doc = canais[index];
            final canal = CanalModel.fromFirestore(doc);
            final bool estouNesteCanal = canal.nome == _meuCanalAtual;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: estouNesteCanal ? theme.primaryColor.withOpacity(0.3) : theme.cardColor,
              child: ListTile(
                leading: Icon(
                  Icons.headset_mic, // Ícone de canal de voz
                  color: estouNesteCanal ? theme.primaryColor : theme.iconTheme.color,
                ),
                title: Text(canal.nome, style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
                subtitle: _buildMembrosOnline(canal.membros, theme),
                trailing: estouNesteCanal
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text("Sair"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _sairDoCanal,
                      )
                    : ElevatedButton(
                        child: const Text("Entrar"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _entrarNoCanal(canal.id, canal.nome),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  /// Constrói o widget que exibe os membros online no canal.
  Widget _buildMembrosOnline(List<String> membrosIds, ThemeData theme) {
    if (membrosIds.isEmpty) {
      return Text("Ninguém online", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12));
    }

    // Usamos um FutureBuilder para buscar os nomes dos membros online
    // Isso pode ser otimizado se houver muitos canais/membros
    return FutureBuilder<List<String>>(
      future: _buscarNomesDosMembrosOnline(membrosIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Carregando membros...", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12));
        }
        if (snapshot.hasError) {
          Logger.error("Erro ao buscar nomes de membros", error: snapshot.error);
          return Text("Erro", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.redAccent));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text("Ninguém online", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12));
        }
        // Limita a exibição para não poluir a UI
        final nomesExibidos = snapshot.data!.take(3).join(', ');
        final maisMembros = snapshot.data!.length > 3 ? '...' : '';
        return Text(
          "Online: $nomesExibidos$maisMembros (${snapshot.data!.length})",
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  /// Busca os nomes dos usuários online a partir de uma lista de UIDs.
  Future<List<String>> _buscarNomesDosMembrosOnline(List<String> uids) async {
    if (uids.isEmpty) return [];

    List<String> nomesOnline = [];
    try {
      // Busca todos os documentos de uma vez para otimizar
      final querySnapshot = await _firestore.collection('users')
          .where(FieldPath.documentId, whereIn: uids)
          .where('online', isEqualTo: true) // Filtra apenas os online
          .get();

      for (var doc in querySnapshot.docs) {
        nomesOnline.add(doc.data()['nome'] ?? 'Sem Nome');
      }
    } catch (e, s) {
      Logger.error("Erro ao buscar múltiplos usuários", error: e, stackTrace: s);
      // Retorna lista vazia em caso de erro para não quebrar a UI
    }
    return nomesOnline;
  }
}

