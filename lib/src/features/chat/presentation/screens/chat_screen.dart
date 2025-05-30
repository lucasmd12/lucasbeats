import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart'; // Assuming provider for service access

import '../data/chat_service.dart';
import '../../../../shared/widgets/button_custom.dart'; // If needed for retry

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String chatName;

  const ChatScreen({Key? key, required this.roomId, required this.chatName})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Initialize the service for the given room ID
    _chatService = ChatService(roomId: widget.roomId);

    // Listener to scroll to bottom when messages update
    _chatService.messages.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.messages.removeListener(_scrollToBottom);
    _chatService.dispose(); // Dispose the service and its notifiers
    super.dispose();
  }

  void _scrollToBottom() {
    // Needs a slight delay for the list view to update its layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    if (_messageController.text.trim().isNotEmpty && _currentUserId != null) {
      final textToSend = _messageController.text.trim();
      _messageController.clear(); // Clear input field immediately

      final success = await _chatService.sendMessage(textToSend);
      if (!success && mounted) {
        // Optionally show an error if sending failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_chatService.error.value ?? 'Falha ao enviar mensagem'), backgroundColor: Colors.red),
        );
        // Restore text if needed, or handle retry logic
        // _messageController.text = textToSend;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.chatName,
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
            child: ValueListenableBuilder<bool>(
              valueListenable: _chatService.loading,
              builder: (context, isLoading, _) {
                if (isLoading && _chatService.messages.value.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF1A1A)));
                }

                return ValueListenableBuilder<String?>(
                  valueListenable: _chatService.error,
                  builder: (context, errorMsg, _) {
                    if (errorMsg != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                Text(errorMsg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                                const SizedBox(height: 10),
                                ButtonCustom(title: "Tentar Novamente", onPressed: () => _chatService._listenToMessages()) // Example retry
                             ]
                          ),
                        ),
                      );
                    }

                    return ValueListenableBuilder<List<ChatMessage>>(
                      valueListenable: _chatService.messages,
                      builder: (context, messages, _) {
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'Nenhuma mensagem ainda. Seja o primeiro!',
                              style: TextStyle(color: Color(0xFFAAAAAA)),
                            ),
                          );
                        }
                        // Use ListView.builder for performance
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(15.0),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _buildMessageItem(message);
                          },
                        );
                      },
                    );
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

  Widget _buildMessageItem(ChatMessage message) {
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
                message.senderName ?? 'Usuário',
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
                    message.text,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
             ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3.0, right: 5.0, left: 5.0),
            child: Text(
              message.createdAt != null
                  ? DateFormat('HH:mm').format(message.createdAt!.toDate())
                  : '',
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

