import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Corrigido: Usar barrel files para imports
import '../models/index.dart'; 
import '../utils/index.dart'; 

/// Serviço para gerenciar interações com canais de voz e chat no Firestore.
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Adiciona o usuário ao array 'membros' do canal e atualiza o campo 'canalVozAtual' do usuário.
  Future<void> entrarNoCanal(String userId, String canalId) async {
    Logger.info("Entrando no canal: userId=$userId, canalId=$canalId");
    final userRef = _firestore.collection('users').doc(userId);
    final canalRef = _firestore.collection('canais').doc(canalId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, {
        'canalVozAtual': canalId, 
        'online': true,
        'ultimoPing': FieldValue.serverTimestamp(),
      });
      transaction.update(canalRef, {
        'membros': FieldValue.arrayUnion([userId])
      });
    });
    Logger.info("Usuário $userId adicionado ao canal $canalId e status atualizado.");
  }

  /// Remove o usuário do array 'membros' do canal e limpa o campo 'canalVozAtual' do usuário.
  Future<void> sairDoCanal(String userId, String canalId) async {
    Logger.info("Saindo do canal: userId=$userId, canalId=$canalId");
    final userRef = _firestore.collection('users').doc(userId);
    final canalRef = _firestore.collection('canais').doc(canalId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, {
        'canalVozAtual': null, 
        'ultimoPing': FieldValue.serverTimestamp(),
      });
      transaction.update(canalRef, {
        'membros': FieldValue.arrayRemove([userId])
      });
    });
    Logger.info("Usuário $userId removido do canal $canalId e status atualizado.");
  }

  /// Atualiza o status de presença do usuário (online/offline).
  Future<void> atualizarStatusPresenca(String userId, bool online) async {
    final userRef = _firestore.collection('users').doc(userId);
    try {
      String? currentChannelId;
      if (!online) {
        final userDoc = await userRef.get();
        final data = userDoc.data();
        if (data != null && data.containsKey('canalVozAtual')) {
          currentChannelId = data['canalVozAtual'] as String?;
        }
      }

      await userRef.update({
        'online': online,
        'ultimoPing': FieldValue.serverTimestamp(),
        if (!online) 'canalVozAtual': null,
      });
      Logger.info("Status de presença do usuário $userId atualizado para: $online");

      if (!online && currentChannelId != null && currentChannelId.isNotEmpty) {
        final canalRef = _firestore.collection('canais').doc(currentChannelId);
        try {
          await canalRef.update({'membros': FieldValue.arrayRemove([userId])});
          Logger.info("Usuário $userId removido do canal $currentChannelId ao ficar offline.");
        } catch (e) {
          Logger.warning("Falha ao remover usuário $userId do canal $currentChannelId ao ficar offline (canal pode ter sido excluído): $e");
        }
      }
    } catch (e) {
      Logger.warning("Falha ao atualizar status de presença para $userId (pode ser normal se o user doc ainda não existe): $e");
    }
  }

  // --- Métodos de Chat --- 

  /// Envia uma mensagem de texto para um canal específico.
  Future<void> sendMessage(String channelId, String text, UserModel currentUser) async {
    if (text.trim().isEmpty) {
      Logger.warning("Tentativa de enviar mensagem vazia.");
      return;
    }

    final messageData = MessageModel(
      id: '', // O ID será gerado pelo Firestore
      channelId: channelId,
      senderId: currentUser.uid,
      senderName: currentUser.username, 
      senderAvatarUrl: currentUser.fotoUrl, 
      textContent: text.trim(),
      type: MessageType.text, 
      timestamp: Timestamp.now(),
    );

    try {
      await _firestore
          .collection('canais')
          .doc(channelId)
          .collection('messages')
          .add(messageData.toFirestore()); 
      Logger.info("Mensagem enviada por ${currentUser.uid} para o canal $channelId");
    } catch (e, s) {
      Logger.error("Erro ao enviar mensagem para o canal $channelId", error: e, stackTrace: s);
      throw Exception("Falha ao enviar mensagem.");
    }
  }

  /// Retorna um Stream das mensagens de um canal específico, ordenadas por timestamp.
  Stream<QuerySnapshot> getMessagesStream(String channelId) {
    return _firestore
        .collection('canais')
        .doc(channelId)
        .collection('messages')
        .orderBy('timestamp', descending: true) 
        .limit(50) 
        .snapshots();
  }

}

