import 'dart:async'; // Importa StreamSubscription
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import 'permission_service.dart'; // Para solicitar permissão de notificação

// Função de handler para mensagens em background/terminated.
// Deve ser uma função de nível superior (fora de qualquer classe).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Se você estiver usando outros plugins Firebase em background, inicialize o Firebase:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Nota: A inicialização aqui pode causar o erro 'duplicate-app' se não for cuidadosa.
  // É geralmente melhor lidar com a lógica de background de forma simples ou
  // usar workmanager/outra solução para tarefas complexas.

  Logger.info("Handling a background message: ${message.messageId}");
  Logger.debug("Background Message data: ${message.data}");
  if (message.notification != null) {
    Logger.debug('Background Message also contained a notification: ${message.notification?.title}');
  }
  // Aqui você pode processar a notificação de dados (data payload)
  // Ex: Atualizar um badge, salvar dados localmente.
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PermissionService _permissionService = PermissionService();

  StreamSubscription? _tokenSubscription;
  StreamSubscription? _foregroundMessageSubscription;

  /// Inicializa o serviço de notificações, solicita permissões e configura handlers.
  Future<void> initialize() async {
    Logger.info("Initializing NotificationService...");

    // 1. Solicitar Permissão (iOS, Web e Android 13+)
    bool permissionGranted = await _requestNotificationPermissions();
    if (!permissionGranted) {
      Logger.warning("Notification permission not granted.");
      // Opcional: Informar o usuário ou desabilitar funcionalidades
    }

    // 2. Obter e Salvar Token FCM
    await _setupToken();

    // 3. Configurar Handlers de Mensagem
    _setupMessageHandlers();

    Logger.info("NotificationService initialized.");
  }

  /// Solicita permissão para receber notificações.
  Future<bool> _requestNotificationPermissions() async {
    // Usa o PermissionService existente para centralizar a lógica de permissões
    bool notificationPermission = await PermissionService.requestNotificationPermission();
    if (notificationPermission) {
        Logger.info("Notification permission granted.");
        return true;
    } else {
        Logger.warning("Notification permission denied.");
        return false;
    }
    /* // Lógica antiga movida para PermissionService
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      Logger.info('User granted notification permission on Apple/Web: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ requer permissão explícita
      // Usar permission_handler para consistência
      bool granted = await _permissionService.requestNotificationPermission();
      return granted;
    }
    return false; // Plataforma não suportada para permissão explícita
    */
  }

  /// Obtém o token FCM, monitora atualizações e salva no Firestore.
  Future<void> _setupToken() async {
    try {
      // Obter token inicial
      String? token = await _firebaseMessaging.getToken();
      Logger.info("FCM Token: ${token?.substring(0, 15)}...");
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Monitorar atualizações do token
      _tokenSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) {
        Logger.info("FCM Token refreshed: ${newToken.substring(0, 15)}...");
        _saveTokenToFirestore(newToken);
      }, onError: (error) {
        Logger.error("Error listening to FCM token refresh", error: error);
      });
    } catch (e, s) {
      Logger.error("Error getting/setting up FCM token", error: e, stackTrace: s);
    }
  }

  /// Salva o token FCM no documento do usuário no Firestore.
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Logger.warning("Cannot save FCM token: User not logged in.");
      return;
    }

    try {
      final userRef = _firestore.collection('users').doc(userId);
      // Usamos um array para suportar múltiplos dispositivos/tokens por usuário
      await userRef.set({
        'fcmTokens': FieldValue.arrayUnion([token])
      }, SetOptions(merge: true)); // Merge para não sobrescrever outros campos
      Logger.info("FCM token saved/updated in Firestore for user $userId.");
    } catch (e, s) {
      Logger.error("Error saving FCM token to Firestore", error: e, stackTrace: s);
    }
  }

  /// Configura os handlers para mensagens recebidas em foreground e background.
  void _setupMessageHandlers() {
    // Handler para mensagens recebidas enquanto o app está em primeiro plano
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.info('Foreground message received!');
      Logger.debug('Message data: ${message.data}');

      if (message.notification != null) {
        Logger.debug('Message also contained a notification: ${message.notification?.title}');
        // Aqui você pode exibir uma notificação local (usando flutter_local_notifications)
        // ou atualizar a UI diretamente.
        // Exemplo: Mostrar um SnackBar ou dialog
        // _showLocalNotification(message.notification!);
      }

      // Processar dados da mensagem (payload)
      _handleDataPayload(message.data);

    }, onError: (error) {
       Logger.error("Error listening to foreground messages", error: error);
    });

    // Handler para quando o usuário toca na notificação e abre o app (vindo de background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.info('Message clicked!');
      Logger.debug('Message data: ${message.data}');
      // Navegar para uma tela específica baseada nos dados da mensagem
      _handleNotificationTap(message.data);
    });

    // Handler para mensagens recebidas enquanto o app está em background ou terminated
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Verificar se o app foi aberto a partir de uma notificação terminada
    _checkForInitialMessage();
  }

  /// Verifica se o app foi iniciado a partir de uma notificação quando estava terminado.
  Future<void> _checkForInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      Logger.info('App opened from terminated state via notification!');
      Logger.debug('Initial message data: ${initialMessage.data}');
      // Navegar para uma tela específica
      _handleNotificationTap(initialMessage.data);
    }
  }

  /// Processa o payload de dados de uma notificação.
  void _handleDataPayload(Map<String, dynamic> data) {
    Logger.info("Processing data payload: $data");
    // Exemplo: Se a notificação for sobre uma nova chamada
    if (data['type'] == 'incoming_call') {
      final channelId = data['channelId'];
      final callerName = data['callerName'];
      Logger.info("Incoming call notification for channel $channelId from $callerName");
      // TODO: Acionar a UI de chamada recebida ou navegar para o canal
    }
    // Adicionar mais lógica para outros tipos de notificação (mensagens, etc.)
  }

  /// Lida com o toque do usuário em uma notificação.
  void _handleNotificationTap(Map<String, dynamic> data) {
    Logger.info("Handling notification tap with data: $data");
    // Exemplo: Navegar para a tela de chat ou canal específico
    if (data['screen'] == 'chat') {
      final chatId = data['chatId'];
      Logger.info("Navigate to chat screen: $chatId");
      // TODO: Implementar navegação (ex: usando um GlobalKey<NavigatorState>)
      // navigatorKey.currentState?.pushNamed('/chat', arguments: chatId);
    } else if (data['screen'] == 'channel') {
       final channelId = data['channelId'];
       Logger.info("Navigate to channel: $channelId");
       // TODO: Implementar navegação ou talvez juntar-se ao canal diretamente
       // Provider.of<CallProvider>(context, listen: false).joinChannel(channelId);
    }
  }

  /// Cancela as inscrições e limpa recursos.
  void dispose() {
    Logger.info("Disposing NotificationService...");
    _tokenSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
  }
}

