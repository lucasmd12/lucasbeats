import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voip_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_identity_widget.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String channelType; // 'global', 'clan', 'federation'
  final bool isVideoCall;
  final List<Map<String, dynamic>>? participants;

  const VoiceCallScreen({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.channelType,
    this.isVideoCall = false,
    this.participants,
  });

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final VoIPService _voipService = VoIPService();
  bool _isConnecting = true;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  String? _error;
  List<Map<String, dynamic>> _currentParticipants = [];

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Configurar callbacks
      _voipService.setCallbacks(
        onCallStarted: (roomId) {
          setState(() {
            _isConnecting = false;
            // _isConnected = true; // This line caused the error and is removed
          });
        },
        onCallEnded: (roomId) {
          Navigator.pop(context);
        },
      );

      // Gerar ID da sala baseado no canal
      final roomId = VoIPService.generateRoomId(
        prefix: widget.channelType,
        entityId: widget.channelId,
      );

      // Criar nome de exibição com identidade visual
      String displayName = user.username;
      if (user.federationTag != null && user.federationTag!.isNotEmpty) {
        displayName = '[${user.federationTag}] $displayName';
      }

      // Iniciar chamada
      if (widget.isVideoCall) {
        await _voipService.startVideoCall(
          roomId: roomId,
          displayName: displayName,
        );
      } else {
        await _voipService.startVoiceCall(
          roomId: roomId,
          displayName: displayName,
        );
      }

      // Inicializar lista de participantes
      if (widget.participants != null) {
        setState(() {
          _currentParticipants = List.from(widget.participants!);
        });
      }

    } catch (e) {
      setState(() {
        _isConnecting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleMute() async {
    try {
      await _voipService.toggleAudio();
      setState(() {
        _isMuted = !_isMuted;
      });
    } catch (e) {
      _showError('Erro ao alternar microfone: $e');
    }
  }

  Future<void> _toggleVideo() async {
    try {
      await _voipService.toggleVideo();
      setState(() {
        _isVideoEnabled = !_isVideoEnabled;
      });
    } catch (e) {
      _showError('Erro ao alternar câmera: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      _voipService.switchCamera();
    } catch (e) {
      _showError('Erro ao trocar câmera: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      await _voipService.endCall();
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Participantes (${_currentParticipants.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _currentParticipants.length,
                  itemBuilder: (context, index) {
                    final participant = _currentParticipants[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: UserIdentityWidget(
                        userId: participant['id'] ?? '',
                        username: participant['username'] ?? 'Usuário',
                        avatar: participant['avatar'],
                        clanFlag: participant['clanFlag'],
                        federationTag: participant['federationTag'],
                        role: participant['role'],
                        clanRole: participant['clanRole'],
                        size: 40,
                        showFullIdentity: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro na Chamada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isConnecting) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Conectando ao ${widget.channelName}...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isVideoCall ? 'Chamada de Vídeo' : 'Chamada de Voz',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    widget.channelName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isVideoCall ? Icons.videocam : Icons.mic,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isVideoCall ? 'Chamada de Vídeo' : 'Chamada de Voz',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Área principal (será ocupada pelo Jitsi Meet)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.grey,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Interface do Jitsi Meet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'A interface de vídeo aparecerá aqui',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controles da chamada
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botão de participantes
                  _buildControlButton(
                    icon: Icons.people,
                    label: '${_currentParticipants.length}',
                    onPressed: _showParticipants,
                    backgroundColor: const Color(0xFF2D2D2D),
                  ),

                  // Botão de microfone
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted ? Colors.red : const Color(0xFF2D2D2D),
                  ),

                  // Botão de vídeo (apenas para chamadas de vídeo)
                  if (widget.isVideoCall)
                    _buildControlButton(
                      icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      onPressed: _toggleVideo,
                      backgroundColor: _isVideoEnabled ? const Color(0xFF2D2D2D) : Colors.red,
                    ),

                  // Botão de trocar câmera (apenas para chamadas de vídeo)
                  if (widget.isVideoCall)
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      onPressed: _switchCamera,
                      backgroundColor: const Color(0xFF2D2D2D),
                    ),

                  // Botão de encerrar chamada
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    size: 56,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    String? label,
    double size = 48,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: size * 0.4,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}