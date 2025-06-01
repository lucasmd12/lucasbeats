import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para buscar nomes de usuário
import '../services/signaling_service.dart';
import '../utils/logger.dart';
import '../models/user_model.dart'; // Para obter dados do usuário atual

enum CallState { idle, joining, leaving, connected, error }

/// Gerencia o estado da chamada WebRTC e a interação com o serviço de sinalização.
class CallProvider extends ChangeNotifier {
  // --- Dependências ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SignalingService? _signalingService;

  // --- Estado da Conexão WebRTC ---
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};
  MediaStream? _localStream;
  String? _currentChannelId;
  CallState _callState = CallState.idle;
  String? _errorMessage;
  bool _isMicMuted = false;
  bool _isSpeakerOn = true; // Padrão para viva-voz em chamadas de grupo

  // --- Getters ---
  CallState get callState => _callState;
  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams => _remoteStreams;
  String? get errorMessage => _errorMessage;
  bool get isMicMuted => _isMicMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get currentChannelId => _currentChannelId;

  // --- Configuração WebRTC ---
  // Usar STUN do Google como padrão. Adicionar TURN se necessário.
  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // {'urls': 'stun:stun1.l.google.com:19302'},
      // Adicionar servidores TURN aqui
    ]
  };
  final Map<String, dynamic> _rtcConstraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  StreamSubscription? _offerSubscription;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _candidateSubscription;
  StreamSubscription? _peerJoinedSubscription; // Para detectar novos peers (simplificado)
  StreamSubscription? _peerLeftSubscription; // Para detectar peers saindo (simplificado)

  // --- Inicialização e Limpeza ---

  /// Inicializa o CallProvider com o UserModel do usuário atual.
  void initialize(UserModel currentUser) {
    Logger.info("Initializing CallProvider for user: ${currentUser.uid}");
    _signalingService = SignalingService(currentUser.uid);
    // Não conecta a um canal aqui, espera o usuário entrar em um
  }

  @override
  void dispose() {
    Logger.info('Disposing CallProvider...');
    _cleanUpCurrentCall();
    _signalingService?.dispose();
    super.dispose();
  }

  /// Limpa todos os recursos relacionados à chamada atual (streams, conexões).
  Future<void> _cleanUpCurrentCall() async {
    Logger.info('Cleaning up current call resources...');
    _updateCallState(CallState.leaving);

    // Parar e liberar stream local
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
      Logger.info('Local stream stopped and disposed.');
    }

    // Fechar e limpar todas as conexões peer
    await Future.forEach(_peerConnections.entries, (entry) async {
      final peerId = entry.key;
      final pc = entry.value;
      await pc.close();
      Logger.info('Peer connection closed for peer: $peerId');
    });
    _peerConnections.clear();

    // Limpar streams remotos
    await Future.forEach(_remoteStreams.entries, (entry) async {
       final stream = entry.value;
       await stream.dispose();
    });
    _remoteStreams.clear();
    Logger.info('Remote streams disposed.');

    // Cancelar inscrições de sinalização
    _offerSubscription?.cancel();
    _answerSubscription?.cancel();
    _candidateSubscription?.cancel();
    _peerJoinedSubscription?.cancel();
    _peerLeftSubscription?.cancel();
    _offerSubscription = null;
    _answerSubscription = null;
    _candidateSubscription = null;
    _peerJoinedSubscription = null;
    _peerLeftSubscription = null;
    Logger.info('Signaling subscriptions cancelled.');

    // Desconectar do serviço de sinalização
    _signalingService?.disconnect();

    _currentChannelId = null;
    _updateCallState(CallState.idle);
    Logger.info('Call cleanup complete.');
  }

  // --- Gerenciamento de Canal ---

  /// Entra em um canal de voz, inicializa mídia local e sinalização.
  Future<void> joinChannel(String channelId) async {
    if (_callState != CallState.idle || _signalingService == null) {
      Logger.warning('Cannot join channel: State is not idle or signaling service not initialized.');
      return;
    }
    if (_auth.currentUser == null) {
       Logger.error('Cannot join channel: User not logged in.');
       _updateCallState(CallState.error, 'Usuário não autenticado.');
       return;
    }

    Logger.info('Joining channel: $channelId');
    _updateCallState(CallState.joining);
    _currentChannelId = channelId;

    try {
      // 1. Obter mídia local (microfone)
      await _getLocalMedia();

      // 2. Conectar ao serviço de sinalização para este canal
      _signalingService!.connect(channelId);
      _listenToSignalingEvents();

      // 3. Anunciar presença ou buscar peers existentes (simplificado)
      // Uma lógica mais robusta buscaria a lista de membros do Firestore
      // e iniciaria conexões com eles.
      // Por simplicidade, vamos esperar por ofertas ou criar conexões reativamente.

      _updateCallState(CallState.connected); // Estado inicial no canal
      Logger.info('Successfully joined channel: $channelId');

    } catch (e, stackTrace) {
      Logger.error('Error joining channel $channelId', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao entrar no canal.');
      await _cleanUpCurrentCall();
    }
  }

  /// Sai do canal de voz atual, limpando recursos.
  Future<void> leaveChannel() async {
    if (_callState == CallState.idle || _callState == CallState.leaving) {
      Logger.info('Already idle or leaving channel.');
      return;
    }
    Logger.info('Leaving channel: $_currentChannelId');
    await _cleanUpCurrentCall();
  }

  // --- Lógica WebRTC ---

  /// Obtém o stream de áudio local do microfone.
  Future<void> _getLocalMedia() async {
    if (_localStream != null) return; // Já possui stream

    Logger.info('Getting local media stream...');
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': false // Apenas áudio por enquanto
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream!.getAudioTracks()[0].enabled = !_isMicMuted; // Aplica estado mudo inicial
      Logger.info('Local media stream obtained: ${_localStream!.id}');
      notifyListeners(); // Notifica a UI sobre o stream local
    } catch (e, stackTrace) {
      Logger.error('Error getting local media', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao acessar microfone.');
      throw e; // Re-propaga o erro para quem chamou (joinChannel)
    }
  }

  /// Cria ou obtém uma conexão RTCPeerConnection para um peer específico.
  Future<RTCPeerConnection> _getOrCreatePeerConnection(String peerId) async {
    RTCPeerConnection? pc = _peerConnections[peerId];
    if (pc != null) {
      return pc;
    }

    Logger.info('Creating new Peer Connection for peer: $peerId');
    pc = await createPeerConnection(_rtcConfiguration, _rtcConstraints);
    _peerConnections[peerId] = pc;

    // Adiciona o stream local à nova conexão
    if (_localStream != null) {
      // pc.addStream(_localStream!); // Método antigo
      _localStream!.getTracks().forEach((track) {
        pc!.addTrack(track, _localStream!); // Método novo
        Logger.debug('Local track ${track.kind} added to PC for $peerId');
      });
    } else {
      Logger.warning('Local stream is null when creating PC for $peerId');
    }

    // --- Handlers para a conexão Peer ---
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      Logger.debug('onIceCandidate for $peerId: ${candidate.candidate?.substring(0, 15)}...');
      _signalingService?.sendCandidate(peerId, candidate);
    };

    pc.onTrack = (RTCTrackEvent event) {
      Logger.info('onTrack received from $peerId: ${event.streams.length} streams, track: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        Logger.info('Remote stream ${stream.id} added for peer $peerId');
        _remoteStreams[peerId] = stream;
        notifyListeners(); // Notifica a UI sobre o novo stream remoto
      }
    };

    // pc.onAddStream = (MediaStream stream) { // Método antigo
    //   Logger.info('Remote stream ${stream.id} added for peer $peerId');
    //   _remoteStreams[peerId] = stream;
    //   notifyListeners(); // Notifica a UI sobre o novo stream remoto
    // };

    pc.onRemoveStream = (MediaStream stream) { // Ainda pode ser útil para limpeza
      Logger.warning('Remote stream ${stream.id} removed for peer $peerId');
      _remoteStreams.remove(peerId);
      stream.dispose();
      notifyListeners();
    };

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      Logger.info('ICE Connection State for $peerId: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        Logger.warning('ICE connection failed/disconnected for $peerId. Cleaning up connection.');
        _closePeerConnection(peerId);
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
       Logger.info('Peer Connection State for $peerId: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          Logger.warning('Peer connection failed/disconnected for $peerId. Cleaning up connection.');
          _closePeerConnection(peerId);
        }
    };

    return pc;
  }

  /// Fecha e remove a conexão com um peer específico.
  Future<void> _closePeerConnection(String peerId) async {
    final pc = _peerConnections.remove(peerId);
    if (pc != null) {
      await pc.close();
      Logger.info('Peer connection closed and removed for $peerId');
    }
    final stream = _remoteStreams.remove(peerId);
    if (stream != null) {
       await stream.dispose();
       Logger.info('Remote stream disposed for $peerId');
    }
    notifyListeners();
  }

  /// Inicia a escuta por eventos de sinalização do SignalingService.
  void _listenToSignalingEvents() {
    if (_signalingService == null) return;

    _offerSubscription = _signalingService!.onOfferReceived.listen(_handleOffer);
    _answerSubscription = _signalingService!.onAnswerReceived.listen(_handleAnswer);
    _candidateSubscription = _signalingService!.onCandidateReceived.listen(_handleCandidate);

    // TODO: Implementar lógica de descoberta de peers mais robusta
    // Exemplo: Ouvir por um nó 'members' no Realtime DB ou Firestore
    _peerJoinedSubscription = _signalingService!.onPeerJoined.listen((peerId) {
      if (peerId != _auth.currentUser?.uid) {
        Logger.info('Peer $peerId joined the channel. Initiating connection.');
        _initiateConnection(peerId);
      }
    });

    _peerLeftSubscription = _signalingService!.onPeerLeft.listen((peerId) {
      if (peerId != _auth.currentUser?.uid) {
        Logger.info('Peer $peerId left the channel. Closing connection.');
        _closePeerConnection(peerId);
      }
    });
     Logger.info('Listening to signaling events.');
  }

  /// Inicia a conexão com um novo peer que entrou no canal.
  Future<void> _initiateConnection(String peerId) async {
    if (_peerConnections.containsKey(peerId)) {
      Logger.info('Connection already exists or being initiated for peer $peerId');
      return;
    }
    try {
      final pc = await _getOrCreatePeerConnection(peerId);
      final offer = await pc.createOffer({'offerToReceiveAudio': 1});
      await pc.setLocalDescription(offer);
      Logger.info('Created offer for peer $peerId');
      _signalingService?.sendOffer(peerId, offer);
    } catch (e, stackTrace) {
      Logger.error('Error initiating connection with $peerId', error: e, stackTrace: stackTrace);
      _closePeerConnection(peerId); // Limpa se falhar
    }
  }

  /// Lida com uma oferta recebida de um peer.
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    final senderId = data['senderId'] as String?;
    final sdpData = data['sdp'] as Map?;

    if (senderId == null || sdpData == null) {
      Logger.warning('Invalid offer data received: $data');
      return;
    }

    Logger.info('Received offer from $senderId');
    try {
      final pc = await _getOrCreatePeerConnection(senderId);
      final offer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);

      await pc.setRemoteDescription(offer);
      Logger.info('Remote description (offer) set for $senderId');

      final answer = await pc.createAnswer({'offerToReceiveAudio': 1});
      await pc.setLocalDescription(answer);
      Logger.info('Created answer for $senderId');

      _signalingService?.sendAnswer(senderId, answer);
    } catch (e, stackTrace) {
      Logger.error('Error handling offer from $senderId', error: e, stackTrace: stackTrace);
      _closePeerConnection(senderId); // Limpa se falhar
    }
  }

  /// Lida com uma resposta recebida de um peer.
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final senderId = data['senderId'] as String?;
    final sdpData = data['sdp'] as Map?;

    if (senderId == null || sdpData == null) {
      Logger.warning('Invalid answer data received: $data');
      return;
    }

    Logger.info('Received answer from $senderId');
    final pc = _peerConnections[senderId];
    if (pc == null) {
      Logger.warning('Received answer from $senderId but no PeerConnection found.');
      return;
    }

    try {
      final answer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);
      await pc.setRemoteDescription(answer);
      Logger.info('Remote description (answer) set for $senderId');
      // Conexão deve estar estabelecida agora
    } catch (e, stackTrace) {
      Logger.error('Error handling answer from $senderId', error: e, stackTrace: stackTrace);
      _closePeerConnection(senderId);
    }
  }

  /// Lida com um candidato ICE recebido de um peer.
  Future<void> _handleCandidate(Map<String, dynamic> data) async {
    final senderId = data['senderId'] as String?;
    final candidateData = data['candidate'] as Map?;

    if (senderId == null || candidateData == null) {
      Logger.warning('Invalid ICE candidate data received: $data');
      return;
    }

    final pc = _peerConnections[senderId];
    if (pc == null) {
      Logger.warning('Received ICE candidate from $senderId but no PeerConnection found.');
      return;
    }

    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      await pc.addCandidate(candidate);
      Logger.debug('ICE Candidate added for $senderId');
    } catch (e) {
      // Ignorar erros "Invalid candidate" que podem ocorrer
      if (!e.toString().contains("Error(addIceCandidate)")) {
         Logger.error('Error adding ICE candidate for $senderId: $e');
      }
    }
  }

  // --- Controles de Mídia ---

  /// Ativa/desativa o microfone.
  void toggleMute() {
    _isMicMuted = !_isMicMuted;
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      _localStream!.getAudioTracks()[0].enabled = !_isMicMuted;
      Logger.info('Microphone ${_isMicMuted ? "muted" : "unmuted"}');
    } else {
      Logger.warning('Cannot toggle mute: Local stream or audio track not available.');
    }
    notifyListeners();
  }

  /// Ativa/desativa o viva-voz (speaker).
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    Logger.info('Speakerphone ${_isSpeakerOn ? "ON" : "OFF"}');
    // Aplica a configuração a todos os streams remotos
    _remoteStreams.values.forEach((stream) {
      stream.getAudioTracks().forEach((track) {
        // A API `setSpeakerphoneOn` pode não estar disponível diretamente no track
        // ou pode requerer um helper específico da plataforma.
        // Por enquanto, apenas logamos e notificamos a UI.
        // Helper.setSpeakerphoneOn(_isSpeakerOn); // Exemplo de como poderia ser
      });
    });
    // CORREÇÃO: Comentando a linha que causa erro, pois MediaStreamTrack.setSpeakerphoneOn não existe.
    // A funcionalidade de speaker/earpiece geralmente é controlada por helpers ou platform channels.
    // MediaStreamTrack.setSpeakerphoneOn(_isSpeakerOn);
    Logger.warning('Toggling speakerphone via MediaStreamTrack.setSpeakerphoneOn is not directly supported by flutter_webrtc. Use platform-specific helpers if needed.');

    notifyListeners();
  }

  // --- Métodos Auxiliares ---

  /// Atualiza o estado da chamada e notifica os ouvintes.
  void _updateCallState(CallState newState, [String? message]) {
    if (_callState != newState) {
      Logger.info('Call state changed: $_callState -> $newState');
      _callState = newState;
      _errorMessage = message; // Armazena mensagem de erro se aplicável
      notifyListeners();
    }
  }
}

