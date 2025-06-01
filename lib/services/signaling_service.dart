import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:federacaomad/services/socket_service.dart';
import 'package:federacaomad/utils/logger.dart';

class SignalingService with ChangeNotifier {
  final SocketService _socketService = SocketService();
  StreamSubscription? _signalSubscription;

  // Stream controller to broadcast received signals to the UI/Call logic
  final _receivedSignalController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get receivedSignalStream => _receivedSignalController.stream;

  String? _currentChannelId;

  SignalingService() {
    // Listen to incoming signals from SocketService
    _signalSubscription = _socketService.signalStream.listen(_handleIncomingSignal);
  }

  void _handleIncomingSignal(Map<String, dynamic> signalData) {
    // Check if the signal is for the current active call/channel if necessary
    // For now, just forward it
    Log.info('Received signal via SignalingService: $signalData');
    _receivedSignalController.add(signalData);
  }

  // Call this when entering a channel where signaling might occur
  void setActiveChannel(String channelId) {
    _currentChannelId = channelId;
    Log.info('SignalingService active for channel: $channelId');
    // No specific action needed here for socket connection, as ChatService handles joining the room.
    // Ensure SocketService is connected via AuthService/AuthProvider.
  }

  // Call this when leaving a channel
  void clearActiveChannel() {
    Log.info('SignalingService cleared active channel: $_currentChannelId');
    _currentChannelId = null;
  }

  // Send WebRTC signal (offer, answer, candidate)
  void sendSignal(dynamic signalData) {
    if (_currentChannelId == null) {
      Log.warning('Cannot send signal: No active channel set in SignalingService.');
      return;
    }
    if (!_socketService.isConnected) {
       Log.warning('Cannot send signal: SocketService is not connected.');
       return;
    }
    Log.info('Sending signal for channel $_currentChannelId');
    _socketService.sendSignal(_currentChannelId!, signalData);
  }

  @override
  void dispose() {
    Log.info('Disposing SignalingService...');
    _signalSubscription?.cancel();
    _receivedSignalController.close();
    super.dispose();
  }
}

