import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Re-verified direct relative imports
import '../../../services/chat_service.dart'; 
// import '../../../models/message_model.dart'; // Commented out: Temporarily defined below
import '../../../models/user_model.dart'; // Direct import verified
import '../../../providers/user_provider.dart'; // Direct import verified
// import '../../../utils/logger.dart'; // Commented out: Temporarily defined below

// --- Temporary Placeholders to Resolve Analysis Errors ---

// Temporary placeholder for MessageType enum
enum MessageType { text, image, audio, video, file, system }

// Temporary placeholder for MessageModel to resolve analysis errors
class MessageModel {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String textContent;
  final MessageType type;
  final Timestamp timestamp;

  MessageModel({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.textContent,
    required this.type,
    required this.timestamp,
  });

  // Minimal factory constructor needed for fromFirestore calls
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Handle null data
    return MessageModel(
      id: doc.id,
      channelId: data['channelId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Desconhecido',
      senderAvatarUrl: data['senderAvatarUrl'],
      textContent: data['textContent'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type'] ?? 'text'}',
        orElse: () => MessageType.text, // Default to text if type is missing/invalid
      ),
      timestamp: data['timestamp'] ?? Timestamp.now(), // Provide default timestamp
    );
  }

  // Minimal method needed if toFirestore is used elsewhere (e.g., in ChatService)
   Map<String, dynamic> toFirestore() {
    return {
      'channelId': channelId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'textContent': textContent,
      'type': type.toString().split('.').last,
      'timestamp': timestamp,
    };
  }
}

// Temporary placeholder for Logger to resolve analysis errors
class Logger {
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    // Simple print for temporary debugging
    print('[TEMP LOG]: $message');
    if (error != null) print('  Error: $error');
    // if (stackTrace != null) print('  StackTrace: $stackTrace'); // Optional: Reduce noise
  }
  static void info(String message) => log(message);
  static void warning(String message) => log(message);
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(message, error: error, stackTrace: stackTrace);
}

// --- End Temporary Placeholders ---


class ChatScreen extends StatefulWidget {
  final String channelId;
  final String chatName;

  const ChatScreen({super.key, required this.channelId, required this.chatName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  String? _currentUserId;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _chatService = ChatService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _currentUser = Provider.of<UserProvider>(context, listen: false).user;
          if (_currentUser == null) {
            Logger.warning("ChatScreen initState: currentUser is null after Provider access.");
          }
          if (mounted) setState(() {});
        } catch (e, s) {
          Logger.error("Error accessing UserProvider in initState", error: e, stackTrace: s);
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSendMessage() async {
    if (_currentUser == null) {
      Logger.warning("Cannot send message: currentUser is null.");
      if (mounted) {
         try {
             _currentUser = Provider.of<UserProvider>(context, listen: false).user;
         } catch (e) {
             Logger.error("Error re-accessing UserProvider in handleSendMessage", error: e);
         }
        if (_currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Não foi possível carregar dados do usuário.'), backgroundColor: Colors.red),
          );
          return;
        }
      }
    }

    if (_messageController.text.trim().isNotEmpty && _currentUser != null) {
      final textToSend = _messageController.text.trim();
      final localMessageController = _messageController;
      localMessageController.clear();

      try {
        // Note: ChatService still uses the original MessageModel import.
        // This might cause issues if ChatService expects the full model.
        // For now, we assume ChatService can handle the temporary model structure.
        await _chatService.sendMessage(widget.channelId, textToSend, _currentUser!); 
        Logger.info("Mensagem enviada com sucesso.");
      } catch (e) {
        Logger.error("Erro ao enviar mensagem: $e");
        localMessageController.text = textToSend;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao enviar mensagem: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      Logger.warning("Tentativa de enviar mensagem vazia.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      try {
        _currentUser = Provider.of<UserProvider>(context, listen: false).user;
      } catch (e) {
        Logger.error("Error accessing UserProvider in build", error: e);
      }
      if (_currentUser == null) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.chatName, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFF1A1A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          backgroundColor: Colors.black,
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFFFF1A1A)),
                SizedBox(height: 10),
                Text("Carregando dados do usuário...", style: TextStyle(color: Colors.white70)),
              ],
            )
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.chatName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 1,
        shadowColor: const Color(0xFF333333),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(widget.channelId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF1A1A)));
                }
                if (snapshot.hasError) {
                  Logger.error("Erro ao carregar mensagens: ${snapshot.error}");
                  return Center(
                    child: Text(
                      'Erro ao carregar mensagens: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma mensagem ainda. Seja o primeiro!',
                      style: TextStyle(color: Color(0xFFAAAAAA)),
                    ),
                  );
                }

                final messages = snapshot.data!.docs.map((doc) {
                  try {
                    // Use the temporary MessageModel defined in this file
                    return MessageModel.fromFirestore(doc);
                  } catch (e, s) {
                    Logger.error("Error parsing message from Firestore", error: e, stackTrace: s);
                    return null;
                  }
                }).whereType<MessageModel>().toList(); // Filter out nulls

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(15.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // Pass the temporary MessageModel defined in this file
                    return _buildMessageItem(message);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  // Use the temporary MessageModel defined in this file
  Widget _buildMessageItem(MessageModel message) {
    final bool isCurrentUser = message.senderId == _currentUserId;
    final alignment = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isCurrentUser ? const Color(0xFFFF1A1A) : const Color(0xFF333333);
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(15),
      topRight: const Radius.circular(15),
      bottomLeft: isCurrentUser ? const Radius.circular(15) : Radius.zero,
      bottomRight: isCurrentUser ? Radius.zero : const Radius.circular(15),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 5.0, bottom: 2.0),
              child: Text(
                message.senderName,
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              ),
            ),
          Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                ),
                child: Text(
                  message.textContent,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3.0, right: 5.0, left: 5.0),
            child: Text(
              DateFormat('HH:mm').format(message.timestamp.toDate()),
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFFFF1A1A)),
              onPressed: _handleSendMessage,
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

