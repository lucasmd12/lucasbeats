import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For ValueNotifier

// Represents a single chat message
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String? senderName;
  final String? senderPhotoURL;
  final Timestamp? createdAt;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    this.senderName,
    this.senderPhotoURL,
    this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'],
      senderPhotoURL: data['senderPhotoURL'],
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

// Service to handle chat functionalities for a specific room
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String roomId;

  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier<List<ChatMessage>>([]);
  final ValueNotifier<bool> loading = ValueNotifier<bool>(true);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  StreamSubscription? _messagesSubscription;

  ChatService({required this.roomId}) {
    _listenToMessages();
  }

  void _listenToMessages() {
    if (roomId.isEmpty) {
      error.value = "ID da sala inválido.";
      loading.value = false;
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      final messagesRef = _firestore
          .collection('clas') // Assuming 'clas' is the collection for clans/rooms
          .doc(roomId)
          .collection('mensagens');

      final query = messagesRef.orderBy('createdAt', descending: false).limitToLast(50); // Order ascending, limit to last 50

      _messagesSubscription = query.snapshots().listen((snapshot) {
        final messageData = snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
        messages.value = messageData; // Already ordered ascending
        loading.value = false;
      }, onError: (err) {
        print('Erro ao carregar mensagens: $err');
        error.value = 'Falha ao carregar mensagens.';
        loading.value = false;
      });
    } catch (err) {
      print('Erro ao configurar listener de mensagens: $err');
      error.value = 'Falha ao configurar o chat.';
      loading.value = false;
    }
  }

  Future<bool> sendMessage(String text) async {
    final currentUser = _auth.currentUser;
    if (text.trim().isEmpty || roomId.isEmpty || currentUser == null) {
      error.value = "Não é possível enviar a mensagem.";
      return false;
    }

    try {
       final messagesRef = _firestore
          .collection('clas') // Assuming 'clas' is the collection for clans/rooms
          .doc(roomId)
          .collection('mensagens');

      await messagesRef.add({
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Usuário Anônimo',
        'senderPhotoURL': currentUser.photoURL,
      });
      return true;
    } catch (err) {
      print('Erro ao enviar mensagem: $err');
      error.value = 'Falha ao enviar mensagem.';
      return false;
    }
  }

  void dispose() {
    _messagesSubscription?.cancel();
    messages.dispose();
    loading.dispose();
    error.dispose();
  }
}

