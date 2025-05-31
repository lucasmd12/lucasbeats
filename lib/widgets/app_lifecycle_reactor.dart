import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/chat_service.dart'; // Para atualizar presença
import '../providers/call_provider.dart'; // Para potencialmente sair do canal
import '../utils/logger.dart';

/// Um widget que reage às mudanças no ciclo de vida do aplicativo.
/// Utilizado para atualizar o status de presença online/offline do usuário
/// e potencialmente limpar recursos de chamada ao ir para background.
class AppLifecycleReactor extends StatefulWidget {
  final Widget child;

  const AppLifecycleReactor({super.key, required this.child});

  @override
  State<AppLifecycleReactor> createState() => _AppLifecycleReactorState();
}

class _AppLifecycleReactorState extends State<AppLifecycleReactor> with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Logger.info("AppLifecycleReactor initialized and observing.");
    // Define o status inicial como online ao iniciar/reativar
    _updatePresence(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Logger.info("AppLifecycleReactor disposed and stopped observing.");
    // Tenta definir como offline ao fechar (pode não executar sempre)
    // _updatePresence(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    Logger.info("App lifecycle state changed: $state");

    final userId = context.read<UserProvider>().user?.uid;
    if (userId == null) {
      Logger.warning("Cannot update presence: userId is null in AppLifecycleReactor.");
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _updatePresence(true);
        break;
      case AppLifecycleState.inactive:
      // App está inativo, mas ainda pode estar visível (ex: chamada do sistema)
      // Pode ser um bom momento para salvar estado, mas não necessariamente ficar offline.
        break;
      case AppLifecycleState.paused:
      // App está em background.
        _updatePresence(false);
        // Opcional: Desconectar da chamada ativa para economizar recursos/dados?
        // context.read<CallProvider>().leaveChannel(); // CUIDADO: Pode ser abrupto para o usuário.
        break;
      case AppLifecycleState.detached:
      // App está sendo finalizado. Tenta marcar como offline.
        _updatePresence(false);
        break;
      case AppLifecycleState.hidden: // Novo estado, similar a paused/detached
         _updatePresence(false);
         break;
    }
  }

  /// Atualiza o status de presença no Firestore.
  Future<void> _updatePresence(bool isOnline) async {
    final userId = context.read<UserProvider>().user?.uid;
    if (userId != null) {
      Logger.info("Updating presence for user $userId to: ${isOnline ? 'online' : 'offline'}");
      // Não aguarda aqui para não bloquear a UI
      _chatService.atualizarStatusPresenca(userId, isOnline).catchError((e, s) {
         Logger.error("Error updating presence in background", error: e, stackTrace: s);
      });
    } else {
       Logger.warning("Cannot update presence: userId is null when trying to update.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

