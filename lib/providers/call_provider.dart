import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';
import '../models/user_model.dart'; // Assuming UserModel exists

enenum CallState { idle, calling, receiving, connected, error }

class CallProvider extends ChangeNotifier {
  // --- Connection & State ---
  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  CallState _callState = CallState.idle;
  String? _currentCallId; // ID for the current call session
  String? _remoteUserId; // ID of the user being called or calling
  String? _remoteUserName; // Name of the remote user
  String? _errorMessage;

  // --- Getters ---
  CallState get callState => _callState;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  String? get remoteUserName => _remoteUserName;
  String? get errorMessage => _errorMessage;
  bool get isMicMuted => _localStream?.getAudioTracks()[0].enabled == false;
  bool get isSpeakerOn => true; // TODO: Implement speakerphone toggle if needed

  // --- Signaling Server URL (Replace with actual server URL) ---
  // IMPORTANT: Use HTTPS for production deployments unless testing locally
  final String _signalingServerUrl = 'https://3000-i5baaocv71dcx11ih6kzz-de4a2afc.manus.computer'; // Public URL

  final Uuid _uuid = const Uuid();
  String? _selfId; // Current user's ID

  // --- Initialization & Cleanup ---
  void initialize(UserModel currentUser) {
    _selfId = currentUser.uid;
    _connectSignaling();
  }

  void _connectSignaling() {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = IO.io(_signalingServerUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'query': {'userId': _selfId} // Send user ID on connection
      });

      _socket!.onConnect((_) {
        Logger.info('Signaling connected: ${_socket!.id}');
        // Register user ID with signaling server if needed (handled by query now)
        // _socket!.emit('register', _selfId);
      });

      _socket!.onDisconnect((_) => Logger.warn('Signaling disconnected'));
      _socket!.onError((data) => Logger.error('Signaling error: $data'));

      // --- WebRTC Signaling Handlers ---
      _socket!.on('incoming_call', _handleIncomingCall);
      _socket!.on('call_accepted', _handleCallAccepted);
      _socket!.on('offer', _handleOffer);
      _socket!.on('answer', _handleAnswer);
      _socket!.on('ice_candidate', _handleIceCandidate);
      _socket!.on('call_ended', _handleCallEnded);
      _socket!.on('call_rejected', _handleCallRejected); // Handle rejection

    } catch (e, stackTrace) {
      Logger.error('Failed to connect to signaling server', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Falha ao conectar ao servidor.');
    }
  }

  @override
  void dispose() {
    _cleanUp();
    super.dispose();
  }

  void _cleanUp() {
    Logger.info('Cleaning up CallProvider...');
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.dispose();
    _remoteStream = null;

    _peerConnection?.close();
    _peerConnection = null;

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _callState = CallState.idle;
    _currentCallId = null;
    _remoteUserId = null;
    _remoteUserName = null;
    _errorMessage = null;
    // Don't notify listeners here as dispose is final
  }

  // --- Call Initiation ---
  Future<void> makeCall(String targetUserId, String targetUserName) async {
    if (_callState != CallState.idle || _selfId == null) {
      Logger.warn('Cannot make call: State is not idle or selfId is null.');
      return;
    }
    if (_socket == null || !_socket!.connected) {
       _updateCallState(CallState.error, 'Não conectado ao servidor de sinalização.');
       return;
    }

    _remoteUserId = targetUserId;
    _remoteUserName = targetUserName;
    _currentCallId = _uuid.v4(); // Generate unique call ID
    _updateCallState(CallState.calling);

    try {
      await _createPeerConnection();
      await _createOffer();
      // Send call request via signaling
      _socket!.emit('make_call', {
        'callId': _currentCallId,
        'callerId': _selfId,
        'calleeId': _remoteUserId,
        'callerName': 'Nome do Usuário Atual' // TODO: Get current user's name
      });
      Logger.info('Making call to $targetUserId (Call ID: $_currentCallId)');
    } catch (e, stackTrace) {
      Logger.error('Error making call', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao iniciar chamada.');
      await _endCallLocally();
    }
  }

  // --- Call Handling ---
  void _handleIncomingCall(dynamic data) {
    if (_callState != CallState.idle) {
      Logger.warn('Ignoring incoming call: Already in a call or busy.');
      // Optionally send a 'busy' signal back
      _socket?.emit('reject_call', {'callId': data['callId'], 'reason': 'busy'});
      return;
    }
    _currentCallId = data['callId'];
    _remoteUserId = data['callerId'];
    _remoteUserName = data['callerName'] ?? 'Desconhecido';
    Logger.info('Incoming call from $_remoteUserId (Name: $_remoteUserName, Call ID: $_currentCallId)');
    _updateCallState(CallState.receiving);
    // UI should now show incoming call screen
  }

  Future<void> acceptCall() async {
    if (_callState != CallState.receiving || _currentCallId == null || _remoteUserId == null) {
      Logger.warn('Cannot accept call: Invalid state.');
      return;
    }

    try {
      await _createPeerConnection();
      // Send acceptance signal
      _socket!.emit('accept_call', {'callId': _currentCallId, 'calleeId': _selfId});
      Logger.info('Accepting call ID: $_currentCallId');
      // Offer will be created by the caller upon receiving 'call_accepted'
      // Or handle offer directly if sent with 'incoming_call'
      // For simplicity, let's assume offer comes after acceptance signal
      _updateCallState(CallState.connected); // Tentative state, offer/answer needed
    } catch (e, stackTrace) {
      Logger.error('Error accepting call', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao aceitar chamada.');
      await _endCallLocally();
    }
  }

  void rejectCall() {
    if (_callState != CallState.receiving || _currentCallId == null) {
      Logger.warn('Cannot reject call: Invalid state.');
      return;
    }
    Logger.info('Rejecting call ID: $_currentCallId');
    _socket?.emit('reject_call', {'callId': _currentCallId, 'calleeId': _selfId, 'reason': 'rejected'});
    _resetCallState();
  }

  void _handleCallAccepted(dynamic data) async {
    if (_callState != CallState.calling || data['callId'] != _currentCallId) {
      Logger.warn('Received call_accepted in wrong state or for wrong call ID.');
      return;
    }
    Logger.info('Call accepted by ${data['calleeId']} (Call ID: $_currentCallId)');
    // Now that call is accepted, proceed with sending the offer if not already sent
    // (Offer creation was moved to makeCall for simplicity here)
    // If offer wasn't created yet, create and send it now.
    // await _createOffer(); // Assuming offer was already created in makeCall
    _updateCallState(CallState.connected); // Move to connected state after acceptance
  }

  void _handleCallRejected(dynamic data) {
     if (data['callId'] != _currentCallId) return;
     Logger.info('Call rejected by $_remoteUserId. Reason: ${data['reason']}');
     _updateCallState(CallState.idle, 'Chamada rejeitada.');
     _endCallLocally();
  }

  Future<void> endCall() async {
    if (_callState == CallState.idle) return;

    Logger.info('Ending call ID: $_currentCallId');
    _socket?.emit('end_call', {'callId': _currentCallId, 'userId': _selfId});
    await _endCallLocally();
  }

  void _handleCallEnded(dynamic data) {
    if (data['callId'] != _currentCallId) return;
    Logger.info('Received call_ended signal from remote user.');
    _endCallLocally(notify: false); // End locally without sending another signal
     _updateCallState(CallState.idle, 'Chamada encerrada.');
  }

  Future<void> _endCallLocally({bool notify = true}) async {
    Logger.info('Ending call locally...');
    await _localStream?.getTracks().forEach((track) async => await track.stop());
    await _localStream?.dispose();
    _localStream = null;

    await _remoteStream?.getTracks().forEach((track) async => await track.stop());
    await _remoteStream?.dispose();
    _remoteStream = null;

    await _peerConnection?.close();
    _peerConnection = null;

    if (notify) {
       _resetCallState();
    } else {
       _callState = CallState.idle;
       _currentCallId = null;
       _remoteUserId = null;
       _remoteUserName = null;
       _errorMessage = null;
       // No notifyListeners here, handled by caller (_handleCallEnded)
    }
  }

  void _resetCallState() {
    _callState = CallState.idle;
    _currentCallId = null;
    _remoteUserId = null;
    _remoteUserName = null;
    _errorMessage = null;
    notifyListeners();
  }

  // --- WebRTC Core Logic ---
  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;

    Logger.info('Creating Peer Connection...');
    // IMPORTANT: Add STUN/TURN server configuration for real-world use
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // Add TURN servers here if needed for NAT traversal
        // {
        //   'urls': 'turn:your_turn_server.com:3478',
        //   'username': 'your_username',
        //   'credential': 'your_password',
        // },
      ]
    };
    final Map<String, dynamic> constraints = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    try {
      _peerConnection = await createPeerConnection(configuration, constraints);
      Logger.info('Peer Connection created.');

      // Listeners for Peer Connection events
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        Logger.debug('onIceCandidate: ${candidate.candidate}');
        if (candidate.candidate != null) {
          _socket!.emit('ice_candidate', {
            'callId': _currentCallId,
            'targetId': _remoteUserId,
            'candidate': {
              'sdpMLineIndex': candidate.sdpMLineIndex,
              'sdpMid': candidate.sdpMid,
              'candidate': candidate.candidate,
            }
          });
        }
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        Logger.info('Remote stream added: ${stream.id}');
        _remoteStream = stream;
        _updateCallState(CallState.connected); // Ensure state is connected
      };

      _peerConnection!.onRemoveStream = (MediaStream stream) {
        Logger.warn('Remote stream removed: ${stream.id}');
        _remoteStream?.dispose();
        _remoteStream = null;
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        Logger.info('ICE Connection State: $state');
        // Handle states like disconnected, failed, closed
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
            state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
             if (_callState == CallState.connected) { // Only end if we were connected
                Logger.warn('ICE connection failed/disconnected. Ending call.');
                endCall();
             }
        }
      };

      // Get local media stream
      await _getLocalMedia();

    } catch (e, stackTrace) {
      Logger.error('Error creating Peer Connection', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao criar conexão.');
      await _endCallLocally();
    }
  }

  Future<void> _getLocalMedia() async {
    if (_localStream != null) return;

    Logger.info('Getting local media stream...');
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': false // Set to true if video call is needed
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      Logger.info('Local media stream obtained: ${_localStream!.id}');
      // Add local stream to peer connection
      if (_peerConnection != null && _localStream != null) {
         await _peerConnection!.addStream(_localStream!); // Use await
         Logger.info('Local stream added to Peer Connection.');
      } else {
         Logger.warn('PeerConnection or LocalStream is null, cannot add stream.');
      }
    } catch (e, stackTrace) {
      Logger.error('Error getting local media', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao acessar microfone.');
      await _endCallLocally();
      throw e; // Re-throw to signal failure
    }
  }

  Future<void> _createOffer() async {
    if (_peerConnection == null) {
      Logger.error('Cannot create offer: PeerConnection is null.');
      return;
    }
    Logger.info('Creating SDP Offer...');
    try {
      RTCSessionDescription description = await _peerConnection!.createOffer({'offerToReceiveAudio': 1});
      await _peerConnection!.setLocalDescription(description);
      Logger.info('SDP Offer created and set as local description.');

      // Send offer via signaling
      _socket!.emit('offer', {
        'callId': _currentCallId,
        'targetId': _remoteUserId,
        'offer': description.toMap()
      });
    } catch (e, stackTrace) {
      Logger.error('Error creating offer', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao criar oferta.');
      await _endCallLocally();
    }
  }

  Future<void> _createAnswer() async {
    if (_peerConnection == null) {
      Logger.error('Cannot create answer: PeerConnection is null.');
      return;
    }
    Logger.info('Creating SDP Answer...');
    try {
      RTCSessionDescription description = await _peerConnection!.createAnswer({'offerToReceiveAudio': 1});
      await _peerConnection!.setLocalDescription(description);
      Logger.info('SDP Answer created and set as local description.');

      // Send answer via signaling
      _socket!.emit('answer', {
        'callId': _currentCallId,
        'targetId': _remoteUserId,
        'answer': description.toMap()
      });
    } catch (e, stackTrace) {
      Logger.error('Error creating answer', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao criar resposta.');
      await _endCallLocally();
    }
  }

  void _handleOffer(dynamic data) async {
    if (data['callId'] != _currentCallId || _callState == CallState.idle) {
       Logger.warn('Received offer for wrong call ID or in idle state.');
       return;
    }
    Logger.info('Received SDP Offer from ${data['callerId']}');
    try {
      // Ensure peer connection exists (might be created on incoming call accept)
      await _createPeerConnection();

      final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
      await _peerConnection!.setRemoteDescription(offer);
      Logger.info('Remote description (Offer) set.');

      // Create and send answer
      await _createAnswer();
      _updateCallState(CallState.connected); // Confirm connected state

    } catch (e, stackTrace) {
      Logger.error('Error handling offer', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao processar oferta.');
      await _endCallLocally();
    }
  }

  void _handleAnswer(dynamic data) async {
     if (data['callId'] != _currentCallId || _callState != CallState.connected) {
       Logger.warn('Received answer for wrong call ID or in wrong state.');
       return;
    }
    Logger.info('Received SDP Answer from ${data['calleeId']}');
    try {
      final answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
      await _peerConnection!.setRemoteDescription(answer);
      Logger.info('Remote description (Answer) set.');
      // Connection should be established now
    } catch (e, stackTrace) {
      Logger.error('Error handling answer', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao processar resposta.');
      await _endCallLocally();
    }
  }

  void _handleIceCandidate(dynamic data) async {
     if (data['callId'] != _currentCallId || _peerConnection == null) {
       Logger.warn('Received ICE candidate for wrong call ID or null PeerConnection.');
       return;
    }
    Logger.debug('Received ICE Candidate from remote peer');
    try {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
      Logger.debug('ICE Candidate added.');
    } catch (e, stackTrace) {
      Logger.error('Error adding ICE candidate', error: e, stackTrace: stackTrace);
      // This might not be fatal, but log it.
    }
  }

  // --- Media Controls ---
  void toggleMute() {
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      bool currentMuteState = !_localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = currentMuteState;
      Logger.info('Microphone ${currentMuteState ? "unmuted" : "muted"}');
      notifyListeners();
    }
  }

  void toggleSpeaker() {
    // TODO: Implement speakerphone toggle using platform channels or a suitable plugin
    Logger.warn('Speakerphone toggle not implemented yet.');
    // if (_localStream != null && _localStream.getAudioTracks().isNotEmpty) {
    //   MediaStreamTrack audioTrack = _localStream.getAudioTracks()[0];
    //   Helper.setSpeakerphoneOn(!_speakerOn);
    //   _speakerOn = !_speakerOn;
    //   notifyListeners();
    // }
  }

  // --- Helper Methods ---
  void _updateCallState(CallState newState, [String? message]) {
    if (_callState != newState) {
      Logger.info('Call state changed: $_callState -> $newState');
      _callState = newState;
      _errorMessage = message; // Store error message if state is error
      notifyListeners();
    }
  }
}

