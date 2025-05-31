import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para representar um canal de chat de texto no Firestore.
class ChatChannelModel {
  final String id; // ID único do canal (ID do documento Firestore)
  final String nome;
  final String clanId; // ID do clã ao qual este canal pertence
  final String? topico; // Tópico ou descrição curta do canal
  final List<String> membrosPermitidos; // Opcional: UIDs de quem pode ver/participar (se não for público para o clã)
  final Timestamp criadoEm;
  final String? ultimoRemetenteId; // UID do último usuário que enviou mensagem
  final String? ultimaMensagem; // Texto da última mensagem (para preview)
  final Timestamp? ultimaMensagemEm; // Timestamp da última mensagem

  ChatChannelModel({
    required this.id,
    required this.nome,
    required this.clanId,
    this.topico,
    this.membrosPermitidos = const [],
    required this.criadoEm,
    this.ultimoRemetenteId,
    this.ultimaMensagem,
    this.ultimaMensagemEm,
  });

  /// Converte um documento do Firestore em um objeto ChatChannelModel.
  factory ChatChannelModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatChannelModel(
      id: doc.id,
      nome: data['nome'] ?? 'Canal Sem Nome',
      clanId: data['clanId'] ?? '', // Importante ter o ID do clã
      topico: data['topico'],
      membrosPermitidos: List<String>.from(data['membrosPermitidos'] ?? []),
      criadoEm: data['criadoEm'] as Timestamp? ?? Timestamp.now(),
      ultimoRemetenteId: data['ultimoRemetenteId'],
      ultimaMensagem: data['ultimaMensagem'],
      ultimaMensagemEm: data['ultimaMensagemEm'] as Timestamp?,
    );
  }

  /// Converte o objeto ChatChannelModel em um Map para salvar no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'clanId': clanId,
      if (topico != null) 'topico': topico,
      'membrosPermitidos': membrosPermitidos,
      'criadoEm': criadoEm, // Ou FieldValue.serverTimestamp()
      if (ultimoRemetenteId != null) 'ultimoRemetenteId': ultimoRemetenteId,
      if (ultimaMensagem != null) 'ultimaMensagem': ultimaMensagem,
      if (ultimaMensagemEm != null) 'ultimaMensagemEm': ultimaMensagemEm, // Ou FieldValue.serverTimestamp()
    };
  }
}

