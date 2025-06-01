import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:federacaomad/utils/constants.dart'; // For backendBaseUrl
import 'package:federacaomad/utils/logger.dart'; // For logging
import 'dart:async';

class SocketService {
  IO.Socket? _socket;
  final _secureStorage = const FlutterSecureStorage();
  final String _socketUrl = backendBaseUrl; // Use ws:// for local, wss:// for production usually handled by base URL

  // Stream controllers to broadcast received data
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  final _signalController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get signalStream => _signalController.stream;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      Log.info('Socket already connected.');
      return;
    }

    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) {
      Log.warning('Socket connection attempt failed: No JWT token found.');
      _connectionStatusController.add(false);
      return; // Don't attempt connection without a token
    }

    Log.info('Attempting to connect to Socket.IO server at $_socketUrl');
    try {
      _socket = IO.io(_socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {
          'token': token // Send JWT token for authentication
        }
      });

      _socket!.onConnect((_) {
        Log.info('Socket connected: ${_socket!.id}');
        _connectionStatusController.add(true);
        _setupListeners(); // Setup listeners only after successful connection
      });

      _socket!.onDisconnect((reason) {
        Log.info('Socket disconnected: $reason');
        _connectionStatusController.add(false);
        // Consider implementing reconnection logic here if needed
      });

      _socket!.onConnectError((data) {
        Log.error('Socket connection error: $data');
        _connectionStatusController.add(false);
        // Handle specific auth errors if possible
        if (data.toString().contains('Authentication error')) {
          // Maybe trigger logout or token refresh
        }
      });

      _socket!.onError((data) {
        Log.error('Socket error: $data');
        // General error handling
      });

      _socket!.connect(); // Manually initiate connection

    } catch (e) {
      Log.error('Error initializing socket connection: ${e.toString()}');
      _connectionStatusController.add(false);
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    // Listen for new messages
    _socket!.on('receive_message', (data) {
      Log.info('Received message: $data');
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else {
        Log.warning('Received message data is not a Map: $data');
      }
    });

    // Listen for WebRTC signals
    _socket!.on('signal', (data) {
      Log.info('Received signal: $data');
       if (data is Map<String, dynamic>) {
        _signalController.add(data);
      } else {
        Log.warning('Received signal data is not a Map: $data');
      }
    });

    // Add listeners for other custom events from server if needed (e.g., user_joined, user_left)
  }

  // --- Emit Events ---

  void joinChannel(String channelId, Function(Map<String, dynamic>) callback) {
    if (!isConnected) {
      Log.warning('Cannot join channel: Socket not connected.');
      callback({'status': 'error', 'message': 'Not connected'});
      return;
    }
    Log.info('Emitting join_channel for $channelId');
    _socket!.emitWithAck('join_channel', {'channelId': channelId}, ack: (response) {
      Log.info('join_channel ack: $response');
      if (response is Map<String, dynamic>) {
         callback(response);
      } else {
         callback({'status': 'error', 'message': 'Invalid response format'});
      }
    });
  }

  void sendMessage(String channelId, String content, Function(Map<String, dynamic>) callback) {
    if (!isConnected) {
      Log.warning('Cannot send message: Socket not connected.');
       callback({'status': 'error', 'message': 'Not connected'});
      return;
    }
     Log.info('Emitting send_message to $channelId');
    _socket!.emitWithAck('send_message', {'channelId': channelId, 'content': content}, ack: (response) {
      Log.info('send_message ack: $response');
       if (response is Map<String, dynamic>) {
         callback(response);
      } else {
         callback({'status': 'error', 'message': 'Invalid response format'});
      }
    });
  }

  void sendSignal(String channelId, dynamic signalData) {
    if (!isConnected) {
      Log.warning('Cannot send signal: Socket not connected.');
      return;
    }
    Log.info('Emitting signal to $channelId');
    _socket!.emit('signal', {'channelId': channelId, 'signalData': signalData});
  }

  void leaveChannel(String channelId) {
    if (!isConnected) {
      Log.warning('Cannot leave channel: Socket not connected.');
      return;
    }
    Log.info('Emitting leave_channel for $channelId');
    _socket!.emit('leave_channel', {'channelId': channelId});
  }

  void disconnect() {
    Log.info('Disconnecting socket...');
    _socket?.disconnect();
    _socket = null; // Clear socket instance
    _connectionStatusController.add(false);
  }

  void dispose() {
    Log.info('Disposing SocketService...');
    _messageController.close();
    _signalController.close();
    _connectionStatusController.close();
    _socket?.dispose();
    _socket = null;
  }
}

