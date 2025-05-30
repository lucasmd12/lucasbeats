import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../utils/logger.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Get message stream for a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return; // Don't send empty messages

    final messageId = _uuid.v4();
    final timestamp = Timestamp.now();

    final newMessage = Message(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      type: MessageType.text,
      timestamp: timestamp,
    );

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toJson());
      Logger.info('Text message sent successfully to chat: $chatId');
      // Optionally update the last message preview in the chat document
      await _updateChatPreview(chatId, newMessage);
    } catch (e, stackTrace) {
      Logger.error('Failed to send text message', error: e, stackTrace: stackTrace);
      // Handle error appropriately (e.g., show snackbar)
    }
  }

  // Send an image message
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required XFile imageFile,
  }) async {
    final messageId = _uuid.v4();
    final timestamp = Timestamp.now();
    final fileName = '$messageId-${imageFile.name}';
    final storageRef = _storage.ref().child('chat_media/$chatId/$fileName');

    try {
      // 1. Upload image to Firebase Storage
      Logger.info('Uploading image to Storage: ${storageRef.fullPath}');
      UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
      TaskSnapshot snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      Logger.info('Image uploaded successfully. URL: $downloadUrl');

      // 2. Create message document in Firestore
      final newMessage = Message(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        mediaUrl: downloadUrl,
        type: MessageType.image,
        timestamp: timestamp,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toJson());
      Logger.info('Image message sent successfully to chat: $chatId');
      await _updateChatPreview(chatId, newMessage);

    } catch (e, stackTrace) {
      Logger.error('Failed to send image message', error: e, stackTrace: stackTrace);
      // Handle error
    }
  }

  // Helper to update chat preview (last message, timestamp)
  Future<void> _updateChatPreview(String chatId, Message lastMessage) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': lastMessage.type == MessageType.text
            ? lastMessage.text
            : '[${lastMessage.type.name.capitalize()}]', // e.g., [Image], [Audio]
        'lastMessageTimestamp': lastMessage.timestamp,
        'lastSenderName': lastMessage.senderName,
        // Keep other chat metadata like participants, chat name, etc.
      }, SetOptions(merge: true)); // Merge to avoid overwriting other fields
    } catch (e, stackTrace) {
      Logger.warn('Failed to update chat preview for $chatId', error: e, stackTrace: stackTrace);
    }
  }

  // TODO: Implement methods for sending audio/video messages similarly
  // TODO: Implement methods for creating/managing chat rooms (e.g., getOrCreateChat)
}

// Helper extension for capitalizing enum names
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

