import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/chat_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';


class ClanTextChatScreen extends StatefulWidget {
  final String clanId;
  final String clanName;

  const ClanTextChatScreen({super.key, required this.clanId, required this.clanName});

  @override
  State<ClanTextChatScreen> createState() => _ClanTextChatScreenState();
}

class _ClanTextChatScreenState extends State<ClanTextChatScreen> {
  final List<types.Message> _messages = [];
  final _uuid = const Uuid();
  ChatService? _chatService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    _chatService?.listenToMessages(entityId: widget.clanId, chatType: 'clan').listen((messages) {
      setState(() {
        _messages.clear();
        _messages.addAll(messages.map((msg) => types.TextMessage(
          author: types.User(
            id: msg.senderId ?? "", 
            firstName: msg.senderName,
            imageUrl: msg.senderAvatarUrl,
            metadata: {
              'clanFlag': msg.senderClanFlag,
              'federationTag': msg.senderFederationTag,
              'role': msg.senderRole,
              'clanRole': msg.senderClanRole, // Usando o getter diretamente
            },
          ),
          createdAt: msg.createdAt.millisecondsSinceEpoch,
          id: msg.id,
          text: msg.message,
        )).toList().reversed); // Reverse to show latest at bottom
      });
    });

    _loadMessages();
  }

  void _loadMessages() async {
    try {
      final fetchedMessages = await _chatService?.getMessages(entityId: widget.clanId, chatType: 'clan');
      if (fetchedMessages != null) {
        setState(() {
          _messages.clear();
          _messages.addAll(fetchedMessages.map((msg) => types.TextMessage(
          author: types.User(id: msg.senderId ?? "", firstName: msg.senderName),
          createdAt: msg.createdAt.millisecondsSinceEpoch,
          id: msg.id ?? "",
          text: msg.message ?? "",
        )).toList().reversed); // Reverse to show latest at bottom
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar mensagens do clã: $e');
    }
  }

  void _handleSendPressed(types.PartialText message) {
    _chatService?.sendMessage(
      entityId: widget.clanId,
      message: message.text,
      chatType: 'clan',
    );
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: types.User(id: _currentUserId!),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: _uuid.v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      setState(() {
        _messages.insert(0, message); // Add the message to the local list for instant display
      });

      _chatService?.sendMessage(
        entityId: widget.clanId,
        message: '', // Mensagem vazia para imagem
        chatType: 'clan',
        fileUrl: result.path,
        messageType: 'image',
      );
    }
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final pickedFile = result.files.single;
      final message = types.FileMessage(
        author: types.User(id: _currentUserId!),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _uuid.v4(),
        name: pickedFile.name,
        size: pickedFile.size,
        uri: pickedFile.path!,
      );

      setState(() {
        _messages.insert(0, message); // Add the message to the local list for instant display
      });

      _chatService?.sendMessage(
        entityId: widget.clanId,
        message: "", // Mensagem vazia para arquivo
        chatType: "clan",
        fileUrl: pickedFile.path,
        messageType: "file",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = types.User(id: _currentUserId!); // O usuário atual para o chat UI

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat do Clã: ${widget.clanName}'),
        centerTitle: true,
      ),
      body: Chat(
        messages: _messages,
        onAttachmentPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) => SafeArea(
              child: SizedBox(
                height: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleImageSelection();
                      },
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('Foto'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleFileSelection();
                      },
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('Arquivo'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('Cancelar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        onSendPressed: _handleSendPressed,
        user: user,
        theme: const DefaultChatTheme(
          backgroundColor: Color(0xFF212121),
          primaryColor: Color(0xFFF44336),
          secondaryColor: Color(0xFF424242),
          inputBackgroundColor: Color(0xFF424242),
          inputTextColor: Colors.white,
          inputTextDecoration: InputDecoration(
            hintText: 'Digite sua mensagem...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          messageBorderRadius: 12,
          messageInsetsVertical: 8,
          messageInsetsHorizontal: 12,
          receivedMessageBodyTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          sentMessageBodyTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          receivedMessageCaptionTextStyle: TextStyle(color: Colors.grey, fontSize: 12),
          sentMessageCaptionTextStyle: TextStyle(color: Colors.grey, fontSize: 12),
          receivedMessageDocumentIconColor: Colors.white,
          sentMessageDocumentIconColor: Colors.white,
          receivedMessageBodyBoldTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          sentMessageBodyBoldTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          receivedMessageBodyCodeTextStyle: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14),
          sentMessageBodyCodeTextStyle: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14),
          dateDividerTextStyle: TextStyle(color: Colors.grey, fontSize: 12),
          errorColor: Colors.red,
        ),
      ),
    );
  }
}


