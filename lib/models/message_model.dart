import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para representar uma mensagem em um canal de chat de texto.
enum MessageType { text, image, system } // Adicionar outros tipos se necessário (áudio, vídeo, etc.)

class MessageModel {
  final String id; // ID único da mensagem (ID do documento Firestore)
  final String channelId; // ID do canal de texto onde a mensagem foi enviada
  final String senderId; // UID do remetente (ou 'system' para mensagens do sistema)
  final String senderName; // Nome de exibição do remetente (denormalizado para UI)
  final String? senderAvatarUrl; // URL do avatar do remetente (denormalizado)
  final String textContent; // Conteúdo da mensagem (para tipo texto)
  final String? imageUrl; // URL da imagem (para tipo imagem)
  final MessageType type; // Tipo da mensagem (texto, imagem, sistema)
  final Timestamp timestamp; // Quando a mensagem foi enviada
  // Opcional: Adicionar status de leitura, reações, etc.

  MessageModel({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.textContent,
    this.imageUrl,
    required this.type,
    required this.timestamp,
  });

  /// Converte um documento do Firestore em um objeto MessageModel.
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      channelId: data['channelId'] ?? '',
      senderId: data['senderId'] ?? 'unknown',
      senderName: data['senderName'] ?? 'Desconhecido',
      senderAvatarUrl: data['senderAvatarUrl'],
      textContent: data['textContent'] ?? '',
      imageUrl: data['imageUrl'],
      type: _stringToMessageType(data['type'] ?? 'text'),
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Converte o objeto MessageModel em um Map para salvar no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'channelId': channelId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
      'textContent': textContent,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'type': type.name, // Salva o nome do enum como string
      'timestamp': timestamp, // Ou FieldValue.serverTimestamp()
    };
  }

  /// Converte uma string de volta para o enum MessageType.
  static MessageType _stringToMessageType(String typeString) {
    switch (typeString) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}

