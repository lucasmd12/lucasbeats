import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import '../utils/logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart'; // Para RTCSessionDescription e RTCIceCandidate

/// Gerencia a sinalização WebRTC usando o Firebase Realtime Database
/// dentro do contexto de um canal específico.
class SignalingService {
  final String _userId;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  DatabaseReference? _channelRef;
  String? _currentChannelId;

  // Streams para notificar o CallProvider sobre eventos de sinalização recebidos
  final _onOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _onAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final _onCandidateController = StreamController<Map<String, dynamic>>.broadcast();
  final _onPeerJoinedController = StreamController<String>.broadcast();
  final _onPeerLeftController = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get onOfferReceived => _onOfferController.stream;
  Stream<Map<String, dynamic>> get onAnswerReceived => _onAnswerController.stream;
  Stream<Map<String, dynamic>> get onCandidateReceived => _onCandidateController.stream;
  Stream<String> get onPeerJoined => _onPeerJoinedController.stream;
  Stream<String> get onPeerLeft => _onPeerLeftController.stream;

  // Inscrições para os listeners do Firebase
  StreamSubscription? _offersSubscription;
  StreamSubscription? _answersSubscription;
  StreamSubscription? _candidatesSubscription;
  StreamSubscription? _membersSubscription;

  SignalingService(this._userId);

  /// Conecta-se a um canal específico no Realtime Database e começa a ouvir eventos.
  void connect(String channelId) {
    if (_currentChannelId == channelId && _channelRef != null) {
      Logger.info("Already connected to channel $channelId");
      return;
    }
    disconnect(); // Garante limpeza antes de conectar a um novo canal

    _currentChannelId = channelId;
    _channelRef = _database.ref('channels/$_currentChannelId');
    Logger.info("Connecting to signaling channel: $_currentChannelId for user $_userId");

    _listenToMembers();
    _listenToOffers();
    _listenToAnswers();
    _listenToCandidates();

    // Anuncia a entrada no canal
    _channelRef!.child('members/$_userId').set(true);
    // Configura para remover ao desconectar
    _channelRef!.child('members/$_userId').onDisconnect().remove();
  }

  /// Para de ouvir eventos e remove a presença do canal atual.
  void disconnect() {
    if (_channelRef == null || _currentChannelId == null) return;

    Logger.info("Disconnecting from signaling channel: $_currentChannelId");
    _offersSubscription?.cancel();
    _answersSubscription?.cancel();
    _candidatesSubscription?.cancel();
    _membersSubscription?.cancel();
    _offersSubscription = null;
    _answersSubscription = null;
    _candidatesSubscription = null;
    _membersSubscription = null;

    // Remove a presença imediatamente (onDisconnect é um fallback)
    _channelRef!.child('members/$_userId').remove();

    // Limpa referências de sinalização pendentes para este usuário
    _channelRef!.child('signaling/$_userId').remove();

    _channelRef = null;
    _currentChannelId = null;
  }

  /// Ouve por mudanças na lista de membros do canal.
  void _listenToMembers() {
    _membersSubscription = _channelRef!.child('members').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final members = Map<String, dynamic>.from(event.snapshot.value as Map);
        members.keys.where((peerId) => peerId != _userId).forEach((peerId) {
          // Aqui poderíamos diferenciar entre join e leave, mas onPeerJoined/
          // onPeerLeft é mais explícito se usarmos onChildAdded/onChildRemoved.
          // Por simplicidade com onValue, vamos tratar como 'peer detected'.
          // O CallProvider decidirá se inicia a conexão.
          _onPeerJoinedController.add(peerId);
        });
        // TODO: Detectar quem saiu comparando com a lista anterior se necessário,
        // ou usar onChildRemoved listener para _onPeerLeftController.
      }
    }, onError: (error) {
      Logger.error("Error listening to channel members", error: error);
    });

    // Listener específico para entrada de novos membros
    _channelRef!.child('members').onChildAdded.listen((event) {
       final peerId = event.snapshot.key;
       if (peerId != null && peerId != _userId) {
          Logger.info("Peer $peerId detected via onChildAdded.");
          _onPeerJoinedController.add(peerId);
       }
    });

     // Listener específico para saída de membros
    _channelRef!.child('members').onChildRemoved.listen((event) {
       final peerId = event.snapshot.key;
       if (peerId != null && peerId != _userId) {
          Logger.info("Peer $peerId left via onChildRemoved.");
          _onPeerLeftController.add(peerId);
       }
    });
  }

  /// Ouve por ofertas SDP recebidas neste canal para este usuário.
  void _listenToOffers() {
    final offersRef = _channelRef!.child('signaling/$_userId/offers');
    _offersSubscription = offersRef.onChildAdded.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final senderId = event.snapshot.key;
        final sdpData = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (senderId != null) {
          Logger.info("Offer received from $senderId");
          _onOfferController.add({'senderId': senderId, 'sdp': sdpData});
          // Remove a oferta após processar para evitar reprocessamento
          event.snapshot.ref.remove();
        }
      }
    }, onError: (error) {
      Logger.error("Error listening to offers", error: error);
    });
  }

  /// Ouve por respostas SDP recebidas neste canal para este usuário.
  void _listenToAnswers() {
    final answersRef = _channelRef!.child('signaling/$_userId/answers');
    _answersSubscription = answersRef.onChildAdded.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final senderId = event.snapshot.key;
        final sdpData = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (senderId != null) {
          Logger.info("Answer received from $senderId");
          _onAnswerController.add({'senderId': senderId, 'sdp': sdpData});
          event.snapshot.ref.remove();
        }
      }
    }, onError: (error) {
      Logger.error("Error listening to answers", error: error);
    });
  }

  /// Ouve por candidatos ICE recebidos neste canal para este usuário.
  void _listenToCandidates() {
    final candidatesRef = _channelRef!.child('signaling/$_userId/candidates');
    _candidatesSubscription = candidatesRef.onChildAdded.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final senderId = event.snapshot.key;
        final candidateGroup = Map<String, dynamic>.from(event.snapshot.value as Map);
        // Processa cada candidato dentro do grupo do remetente
        candidateGroup.forEach((candidateId, candidateData) {
          if (candidateData is Map) {
             Logger.debug("Candidate received from $senderId");
             _onCandidateController.add({
               'senderId': senderId,
               'candidate': Map<String, dynamic>.from(candidateData)
             });
          }
        });
         // Remove o grupo de candidatos do remetente após processar
         event.snapshot.ref.remove();
      }
    }, onError: (error) {
      Logger.error("Error listening to candidates", error: error);
    });
  }

  /// Envia uma oferta SDP para um peer específico dentro do canal.
  Future<void> sendOffer(String peerId, RTCSessionDescription description) async {
    if (_channelRef == null) return;
    Logger.info("Sending offer to $peerId");
    final offerRef = _channelRef!.child('signaling/$peerId/offers/$_userId');
    await offerRef.set(description.toMap());
  }

  /// Envia uma resposta SDP para um peer específico dentro do canal.
  Future<void> sendAnswer(String peerId, RTCSessionDescription description) async {
    if (_channelRef == null) return;
    Logger.info("Sending answer to $peerId");
    final answerRef = _channelRef!.child('signaling/$peerId/answers/$_userId');
    await answerRef.set(description.toMap());
  }

  /// Envia um candidato ICE para um peer específico dentro do canal.
  Future<void> sendCandidate(String peerId, RTCIceCandidate candidate) async {
    if (_channelRef == null) return;
    Logger.debug("Sending candidate to $peerId");
    // Agrupa candidatos por remetente e usa push() para ID único do candidato
    final candidateRef = _channelRef!.child('signaling/$peerId/candidates/$_userId').push();
    await candidateRef.set(candidate.toMap());
  }

  /// Limpa os streams e listeners.
  void dispose() {
    Logger.info("Disposing SignalingService for user $_userId");
    disconnect(); // Garante que a presença seja removida
    _onOfferController.close();
    _onAnswerController.close();
    _onCandidateController.close();
    _onPeerJoinedController.close();
    _onPeerLeftController.close();
  }
}

