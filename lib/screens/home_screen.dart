import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/tabs/home_tab.dart';
import 'package:lucasbeatsfederacao/screens/tabs/missions_tab.dart';
import 'package:lucasbeatsfederacao/screens/tabs/chat_list_tab.dart';
import 'package:lucasbeatsfederacao/screens/global_chat_screen.dart';
import 'package:lucasbeatsfederacao/screens/voice_rooms_screen.dart';
import 'package:lucasbeatsfederacao/screens/federation_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/invite_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/settings_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Importar Role

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late AudioPlayer _audioPlayer;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    ChatListTab(),
    GlobalChatScreen(),
    MissionsTab(),
    SettingsScreen(), // Use the new SettingsScreen widget
  ];

  final List<String> _backgroundImages = [
    'assets/images_png/backgrounds/bg_mercedes_forest.png',
    'assets/images_png/backgrounds/bg_bmw_smoke_01.png',
    'assets/images_png/backgrounds/bg_joker_smoke.png',
    'assets/images_png/backgrounds/bg_cards_dice.png',
    'assets/images_png/backgrounds/bg_audi_autumn.png',
    'assets/images_png/backgrounds/bg_mustang_autumn.png',
    'assets/images_png/backgrounds/bg_gtr_night.png',
    'assets/images_png/backgrounds/bg_bmw_smoke_02.png',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    final transaction = Sentry.startTransaction(
      'requestPermissions',
      'permission_request',
      description: 'Requesting necessary permissions',
    );
    Logger.info("Requesting necessary permissions...");
    try {
      final notificationSpan = transaction.startChild(
        'requestNotificationPermission',
        description: 'Requesting notification permission',
      );
      PermissionStatus notificationStatus = await Permission.notification.request();
      notificationSpan.finish(status: SpanStatus.ok());

      if (notificationStatus.isGranted) {
        Logger.info("Notification permission granted.");
      } else if (notificationStatus.isDenied) {
        Logger.warning("Notification permission denied.");
      } else if (notificationStatus.isPermanentlyDenied) {
        Logger.error("Notification permission permanently denied.");
        _showSettingsDialog("Notificações");
      }

      final storageSpan = transaction.startChild(
        'requestStoragePermission',
        description: 'Requesting storage permission',
      );
      PermissionStatus storageStatus = await Permission.storage.request();
      storageSpan.finish(status: SpanStatus.ok());

      if (storageStatus.isGranted) {
        Logger.info("Storage permission granted.");
      } else if (storageStatus.isDenied) {
        Logger.warning("Storage permission denied.");
      } else if (storageStatus.isPermanentlyDenied) {
        Logger.error("Storage permission permanently denied.");
        _showSettingsDialog("Armazenamento");
      }

      final microphoneSpan = transaction.startChild(
        'requestMicrophonePermission',
        description: 'Requesting microphone permission',
      );
      PermissionStatus microphoneStatus = await Permission.microphone.request();
      microphoneSpan.finish(status: SpanStatus.ok());

      if (microphoneStatus.isGranted) {
        Logger.info("Microphone permission granted.");
      } else if (microphoneStatus.isDenied) {
        Logger.warning("Microphone permission denied.");
      } else if (microphoneStatus.isPermanentlyDenied) {
        Logger.error("Microphone permission permanently denied.");
        _showSettingsDialog("Microfone");
      }
      transaction.finish(status: SpanStatus.ok());
    } catch (e, stackTrace) {
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(e, stackTrace: stackTrace);
      Logger.error("Error requesting permissions", error: e, stackTrace: stackTrace);
    }
  }

  void _showSettingsDialog(String permissionName) {
     if (!mounted) return;
     showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Permissão Necessária"),
          content: Text("A permissão de $permissionName foi negada permanentemente. Por favor, habilite-a nas configurações do aplicativo para usar todas as funcionalidades."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Abrir Configurações"),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
  }

  Future<void> _initializeAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAsset('assets/audio/intro_music.mp3');
      _audioPlayer.play();
      Logger.info("Intro music started playing.");
    } catch (e, stackTrace) {
      Logger.error("Error loading or playing intro music", error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Logger.info("Switched to tab index: $index");
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final textTheme = Theme.of(context).textTheme;

    if (authProvider.authStatus == AuthStatus.unknown || authProvider.authService.isLoading) {
       return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
             valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    if (currentUser == null) {
       Logger.warning("HomeScreen build: User is null after authentication check. This shouldn't happen.");
       return Scaffold(
         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
         body: Center(child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text("Erro crítico ao carregar dados do usuário. Por favor, tente reiniciar o aplicativo.", textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
         )),
       );
    }

    // Determinar o ícone e o texto de exibição com base no papel do usuário
    IconData displayIcon = Icons.person; // Ícone padrão
    String displayText = currentUser.username ?? 'Usuário'; // Texto padrão, adicionado null-check

    if (currentUser.role == Role.admMaster) {
      displayIcon = Icons.admin_panel_settings; // Ícone para ADM MASTER
      displayText = "ADM MASTER: ${currentUser.username ?? 'N/A'}"; // Adicionado null-check
    } else if (currentUser.clanName != null && currentUser.clanTag != null) {
      // Se o usuário pertence a um clã, exibe a bandeira do clã, nome do usuário e tag da federação
      // Assumindo que a bandeira do clã é um ícone ou imagem, aqui usaremos um ícone placeholder
      displayIcon = Icons.flag; // Ícone para clã
      displayText = "${currentUser.clanName} [${currentUser.clanTag}] ${currentUser.username ?? 'N/A'}"; // Adicionado null-check
      if (currentUser.federationTag != null) {
        displayText += " (${currentUser.federationTag})";
      }
    } else if (currentUser.federationName != null && currentUser.federationTag != null) {
      // Se o usuário pertence a uma federação mas não a um clã
      displayIcon = Icons.account_tree; // Ícone para federação
      displayText = "${currentUser.federationName} (${currentUser.federationTag}) ${currentUser.username ?? 'N/A'}"; // Adicionado null-check
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.purple, // Placeholder color
                shape: BoxShape.circle,
              ),
              child: Icon(
                displayIcon, // Ícone dinâmico
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayText, // Texto dinâmico
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (currentUser.role == Role.admMaster || currentUser.role == Role.leader) // ADM MASTER e Líderes podem gerenciar federações
            IconButton(
              icon: const Icon(Icons.account_tree),
              tooltip: 'Federações',
              onPressed: () {
                Logger.info("Federations button pressed.");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FederationListScreen(),
                  ),
                );
              },
            ),
          // Check if user can join voice rooms in general (using 'global' as a placeholder entity ID)
          // You might need a more specific permission check based on the context of the voice room list
          if (PermissionService.canJoinVoiceRoom(currentUser, 'global')) // Pass a dummy ID for general check
            IconButton(
              icon: const Icon(Icons.record_voice_over),
              tooltip: 'Salas de Voz',
              onPressed: () {
                Logger.info("Voice rooms button pressed.");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VoiceRoomsScreen(),
                  ),
                );
              },
            ),
          // Check if the user has the permission to view invites.
          // The hasAction method checks if the user's role has a specific permission defined in PermissionService.
          // For demonstration, let's assume ADM and regular users can view their invites
           // Or add a specific permission check if needed
           IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notificações',
            onPressed: () {
              Logger.info("Notifications button pressed.");
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InviteListScreen(),
                ),
            );
          },
        ),
        ],
        leading: IconButton(
          icon: StreamBuilder<PlayerState>(
            stream: _audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;
              if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering || !(_audioPlayer.playing)) {
                return const Icon(Icons.play_arrow);
              } else if (playing != true) {
                return const Icon(Icons.play_arrow);
              } else {
                return const Icon(Icons.pause);
              }
            },
          ),
          onPressed: () {
            if (_audioPlayer.playing) {
              _audioPlayer.pause();
              Logger.info("Intro music paused.");
            } else {
              _audioPlayer.play();
              Logger.info("Intro music resumed.");
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImages[_selectedIndex % _backgroundImages.length]),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: IndexedStack(
           index: _selectedIndex,
           children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Voz',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: 'Global',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Missões',
          ),
           BottomNavigationBarItem( // Placeholder for Settings tab
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).primaryColor,
        type: BottomNavigationBarType.fixed, // Ensure consistent item spacing
      ),
    );
  }
}


