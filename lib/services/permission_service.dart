import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io'; // For Platform check
import '../utils/logger.dart'; // Assuming logger is in utils

/// Serviço para gerenciar e solicitar permissões essenciais do aplicativo.
class PermissionService {

  /// Solicita permissão para notificações.
  /// Retorna `true` se concedida, `false` caso contrário.
  static Future<bool> requestNotificationPermission() async {
    Logger.info('Requesting notification permission...');
    try {
      final status = await Permission.notification.request();
      Logger.info('Notification permission status: $status');
      if (status.isGranted) {
        return true;
      } else {
        if (status.isPermanentlyDenied) {
          Logger.error('Notification permission permanently denied.');
          // Consider opening app settings here if needed, but keep the method focused
          // await openAppSettings();
        }
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error('Error requesting notification permission', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Solicita as permissões críticas necessárias para as funcionalidades de VoIP.
  ///
  /// Retorna `true` se todas as permissões essenciais foram concedidas, `false` caso contrário.
  static Future<bool> requestVoipPermissions() async {
    Logger.info('Requesting VoIP permissions...');

    // Define as permissões necessárias
    Map<Permission, PermissionStatus> statuses = {};

    // Permissões comuns para Android e iOS
    final commonPermissions = [
      Permission.microphone,
      // Notification permission is often handled separately or upon first notification send
      // Permission.notification, // Removido daqui, solicitado separadamente se necessário
    ];

    // Adiciona permissão de Bluetooth específica para Android (se não for web)
    if (!kIsWeb && Platform.isAndroid) {
      // A permissão exata pode depender da versão do Android e do uso (scan, connect, advertise)
      // Usaremos bluetoothConnect como exemplo, ajuste se necessário.
      // Verifique se bluetoothConnect é realmente necessário para VoIP no seu caso.
      // commonPermissions.add(Permission.bluetoothConnect);
      // Se for apenas para áudio via bluetooth, microphone pode ser suficiente.
      // Vamos manter simples por enquanto.
    }

    try {
      // Solicita todas as permissões de uma vez
      statuses = await commonPermissions.request();
      Logger.info('Permission statuses: $statuses');

      // Verifica se todas as permissões foram concedidas
      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (allGranted) {
        Logger.info('All essential VoIP permissions granted.');
        return true;
      } else {
        Logger.warning('Not all VoIP permissions were granted.');
        // Log detalhado das permissões não concedidas
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            Logger.warning('Permission denied: $permission - Status: $status');
          }
        });
        // Opcional: Mostrar um diálogo ao usuário explicando a necessidade das permissões
        // e talvez direcionando para as configurações do app.
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error('Error requesting permissions', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Verifica o status atual de uma permissão específica.
  static Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    final status = await permission.status;
    Logger.info('Status for $permission: $status');
    return status;
  }

  /// Abre as configurações do aplicativo para que o usuário possa gerenciar as permissões manualmente.
  static Future<void> openAppSettings() async {
    Logger.info('Opening app settings...');
    // CORREÇÃO: Chamada corrigida para usar a função diretamente do pacote importado.
    await openAppSettings(); // Correção: Removido o prefixo 'permission_handler.'
  }
}

