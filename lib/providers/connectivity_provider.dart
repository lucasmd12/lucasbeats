import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../utils/logger.dart'; // Assuming logger is in utils

/// Provider para monitorar o estado da conexão com a internet.
class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  // CORREÇÃO: Alterado o tipo do StreamSubscription para corresponder à versão 5.0.2 do connectivity_plus
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Retorna `true` se o dispositivo estiver conectado à internet.
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    Logger.info('ConnectivityProvider Initialized.');
    _checkInitialConnection();
    _listenToConnectivityChanges();
  }

  /// Verifica a conexão inicial.
  Future<void> _checkInitialConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      // CORREÇÃO: Envolver o resultado em uma lista para corresponder à assinatura de _updateStatus
      _updateStatus([result]);
      Logger.info('Initial connectivity check result: $result');
    } catch (e, stackTrace) {
      Logger.error('Error checking initial connectivity', error: e, stackTrace: stackTrace);
      // Assume offline if check fails
      _updateStatus([ConnectivityResult.none]);
    }
  }

  /// Ouve as mudanças no estado da conectividade.
  void _listenToConnectivityChanges() {
    // CORREÇÃO: Alterada a assinatura do callback para receber ConnectivityResult (singular)
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      Logger.info('Connectivity changed: $result');
      // CORREÇÃO: Envolver o resultado em uma lista para corresponder à assinatura de _updateStatus
      _updateStatus([result]);
    }, onError: (e, stackTrace) {
      Logger.error('Error listening to connectivity changes', error: e, stackTrace: stackTrace);
      // Assume offline on error
      _updateStatus([ConnectivityResult.none]);
    });
  }

  /// Atualiza o status da conexão e notifica os listeners se houver mudança.
  // Mantém a lógica que espera uma lista, pois agora sempre passamos uma lista.
  void _updateStatus(List<ConnectivityResult> result) {
    // Considera online se houver qualquer conexão ativa (wifi, mobile, etc.), exceto 'none'.
    // A lista pode conter mais de um resultado se houver múltiplas conexões (ex: VPN + Wifi).
    // Mesmo com a versão antiga, tratamos como lista para manter a lógica unificada.
    bool newStatus = !result.contains(ConnectivityResult.none) && result.isNotEmpty;

    if (_isOnline != newStatus) {
      _isOnline = newStatus;
      Logger.info('Connectivity status changed: ${_isOnline ? 'Online' : 'Offline'}');
      notifyListeners();
    }
  }

  /// Cancela a inscrição do listener ao descartar o provider.
  @override
  void dispose() {
    Logger.info('Disposing ConnectivityProvider.');
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

