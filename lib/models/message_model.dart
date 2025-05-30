import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio, video } // Add other types as needed

class Message {
  final String id; // Unique message ID
  final String chatId; // ID of the chat room or conversation
  final String senderId;
  final String senderName; // Store sender name for display
  final String? text; // Nullable for media messages
  final String? mediaUrl; // URL for image, audio, video
  final MessageType type;
  final Timestamp timestamp;
  final bool isRead; // Optional: track read status

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.text,
    this.mediaUrl,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text, // Default to text if type is invalid
      ),
      timestamp: json['timestamp'] as Timestamp,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type.toString(),
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}

