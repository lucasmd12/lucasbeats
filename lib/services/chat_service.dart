import 'package:flutter/foundation.dart';
import 'package:lucasbeatsfederacao/models/message_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/firebase_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart'; // Importar SocketService

class ChatService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseService? _firebaseService;
  final AuthService _authService;
  final SocketService _socketService; // Adicionar SocketService

  final Map<String, List<Message>> _messages = {};

  ChatService({FirebaseService? firebaseService, required AuthService authService, required SocketService socketService})
      : _firebaseService = firebaseService,
        _authService = authService,
        _socketService = socketService {
    _socketService.messageStream.listen((messageData) {
      _handleRealtimeMessage(messageData);
    });
  }
