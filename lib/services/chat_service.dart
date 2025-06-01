import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:federacaomad/services/api_service.dart';
import 'package:federacaomad/services/socket_service.dart';
import 'package:federacaomad/models/chat_channel_model.dart'; // Assuming this exists or create it
import 'package:federacaomad/models/message_model.dart'; // Assuming this exists or create it
import 'package:federacaomad/utils/logger.dart';

class ChatService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  List<ChatChannel> _channels = [];
  List<ChatChannel> get channels => _channels;

  ChatChannel? _currentChannel;
  ChatChannel? get currentChannel => _currentChannel;

  List<Message> _messages = [];
  List<Message> get messages => _messages;

  bool _isLoadingChannels = false;
  bool get isLoadingChannels => _isLoadingChannels;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  StreamSubscription? _messageSubscription;
  String? _activeChannelId;

  ChatService() {
    // Listen to incoming messages from SocketService
    _messageSubscription = _socketService.messageStream.listen(_handleIncomingMessage);
  }

  void _handleIncomingMessage(Map<String, dynamic> messageData) {
    try {
      final message = Message.fromJson(messageData);
      // Only add message if it belongs to the currently active channel
      if (message.channel == _activeChannelId) {
        _messages.add(message);
        // Sort messages? Or assume they arrive in order?
        // _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        Log.info('Added incoming message to channel $_activeChannelId');
        notifyListeners();
      }
    } catch (e) {
      Log.error('Error handling incoming message: ${e.toString()} Data: $messageData');
    }
  }

  Future<void> fetchChannels() async {
    _isLoadingChannels = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/api/channels');
      if (response is List) {
        _channels = response.map((data) => ChatChannel.fromJson(data)).toList();
        Log.info('Fetched ${_channels.length} channels.');
      } else {
        _channels = [];
        Log.warning('Unexpected response format when fetching channels: $response');
      }
    } catch (e) {
      Log.error('Error fetching channels: ${e.toString()}');
      _channels = []; // Clear channels on error
    } finally {
      _isLoadingChannels = false;
      notifyListeners();
    }
  }

  Future<ChatChannel?> fetchChannelDetails(String channelId) async {
     // Optionally implement fetching full details if needed beyond the list view
     try {
       final response = await _apiService.get('/api/channels/$channelId');
       if (response != null) {
         return ChatChannel.fromJson(response);
       }
     } catch (e) {
       Log.error('Error fetching channel details for $channelId: ${e.toString()}');
     }
     return null;
  }

  Future<void> joinChannelAndFetchMessages(String channelId) async {
    if (_activeChannelId == channelId) {
      Log.info('Already in channel $channelId');
      return; // Already in this channel
    }

    _isLoadingMessages = true;
    _messages = []; // Clear previous messages
    _activeChannelId = channelId;
    notifyListeners();

    // Leave previous socket room if any
    // if (_currentChannel != null) {
    //   _socketService.leaveChannel(_currentChannel!.id);
    // }

    // Find channel details from the fetched list or fetch again
    _currentChannel = _channels.firstWhere((c) => c.id == channelId, orElse: () => ChatChannel(id: channelId, name: 'Loading...', owner: '', members: [])); // Placeholder

    try {
      // Join Socket.IO room and get history
      _socketService.joinChannel(channelId, (response) {
        if (response['status'] == 'ok' && response['messages'] is List) {
          final history = (response['messages'] as List)
              .map((data) => Message.fromJson(data))
              .toList();
          _messages = history;
          Log.info('Joined channel $channelId and received ${history.length} messages.');
        } else {
          Log.error('Error joining channel $channelId via socket: ${response['message']}');
          // Optionally try fetching via REST as fallback?
          // fetchMessagesREST(channelId);
        }
         _isLoadingMessages = false;
         notifyListeners();
      });
    } catch (e) {
      Log.error('Error initiating join channel $channelId: ${e.toString()}');
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Optional: Fallback or alternative method to fetch messages via REST
  Future<void> fetchMessagesREST(String channelId) async {
    _isLoadingMessages = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/api/channels/$channelId/messages');
      if (response is List) {
        _messages = response.map((data) => Message.fromJson(data)).toList();
        Log.info('Fetched ${_messages.length} messages for channel $channelId via REST.');
      } else {
         _messages = [];
         Log.warning('Unexpected response format fetching messages via REST: $response');
      }
    } catch (e) {
      Log.error('Error fetching messages for channel $channelId via REST: ${e.toString()}');
       _messages = [];
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (_activeChannelId == null || content.trim().isEmpty) {
      Log.warning('Cannot send message: No active channel or empty content.');
      return;
    }
    try {
      _socketService.sendMessage(_activeChannelId!, content, (response) {
        if (response['status'] == 'ok') {
          Log.info('Message sent successfully to channel $_activeChannelId');
          // Message will be added via the receive_message listener
        } else {
          Log.error('Error sending message: ${response['message']}');
          // Handle UI feedback for send failure
        }
      });
    } catch (e) {
      Log.error('Error initiating send message: ${e.toString()}');
      // Handle UI feedback for send failure
    }
  }

  void leaveCurrentChannel() {
    if (_activeChannelId != null) {
      Log.info('Leaving channel $_activeChannelId');
      _socketService.leaveChannel(_activeChannelId!);
      _activeChannelId = null;
      _currentChannel = null;
      _messages = [];
      notifyListeners();
    }
  }

   Future<void> createChannel(String name, String? description) async {
    try {
      final response = await _apiService.post('/api/channels', {
        'name': name,
        if (description != null) 'description': description,
      });
      if (response != null) {
        final newChannel = ChatChannel.fromJson(response);
        _channels.add(newChannel);
        Log.info('Channel created successfully: ${newChannel.name}');
        notifyListeners();
        // Optionally navigate to the new channel or refresh list
      } else {
         Log.error('Channel creation failed: No response data.');
         throw Exception('Failed to create channel');
      }
    } catch (e) {
      Log.error('Error creating channel: ${e.toString()}');
      rethrow; // Let UI handle the error
    }
  }

  @override
  void dispose() {
    Log.info('Disposing ChatService...');
    _messageSubscription?.cancel();
    // Ensure leaving the channel if active when service is disposed
    if (_activeChannelId != null) {
       _socketService.leaveChannel(_activeChannelId!);
    }
    super.dispose();
  }
}

