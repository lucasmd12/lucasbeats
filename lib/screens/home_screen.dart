import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import '../providers/user_provider.dart';
import '../utils/logger.dart';

// Import Tab Widgets
import '../screens/tabs/home_tab.dart';
import '../screens/tabs/members_tab.dart';
import '../screens/tabs/missions_tab.dart';
import '../screens/tabs/settings_tab.dart';
import '../screens/tabs/chat_list_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Default to Home tab

  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    MembersTab(),
    ChatListTab(),
    MissionsTab(),
    SettingsTab(),
  ];

  final List<String> _backgroundImages = [
    // Updated list with new background assets
    'assets/images_png/backgrounds/bg_mercedes_forest.png', // Tab 0: Início
    'assets/images_png/backgrounds/bg_bmw_smoke_01.png',    // Tab 1: Membros
    'assets/images_png/backgrounds/bg_joker_smoke.png',     // Tab 2: Chat
    'assets/images_png/backgrounds/bg_cards_dice.png',      // Tab 3: Missões
    'assets/images_png/backgrounds/bg_audi_autumn.png',     // Tab 4: Config
    // Add more if needed, or cycle through these
    'assets/images_png/backgrounds/bg_mustang_autumn.png',
    'assets/images_png/backgrounds/bg_gtr_night.png',
    'assets/images_png/backgrounds/bg_bmw_smoke_02.png',
  ];

  @override
  void initState() {
    super.initState();
    // Request permissions after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
      // Initialize CallProvider here if not done in main.dart's StreamBuilder
      // _initializeCallProviderIfNeeded();
    });
  }

  // *** NOVO: Função para solicitar permissões ***
  Future<void> _requestPermissions() async {
    Logger.info("Requesting necessary permissions...");
    // Request Notification permission
    PermissionStatus notificationStatus = await Permission.notification.request();
    if (notificationStatus.isGranted) {
      Logger.info("Notification permission granted.");
    } else if (notificationStatus.isDenied) {
      Logger.warning("Notification permission denied.");
      // Optionally show a dialog explaining why the permission is needed
    } else if (notificationStatus.isPermanentlyDenied) {
      Logger.error("Notification permission permanently denied.");
      // Optionally guide user to app settings
      _showSettingsDialog("Notificações");
    }

    // Request Storage permission (adjust based on Android version requirements)
    // For Android 13+, specific permissions like photos, videos, audio might be needed.
    // For simplicity, requesting general storage here.
    PermissionStatus storageStatus = await Permission.storage.request();
     if (storageStatus.isGranted) {
      Logger.info("Storage permission granted.");
    } else if (storageStatus.isDenied) {
      Logger.warning("Storage permission denied.");
    } else if (storageStatus.isPermanentlyDenied) {
      Logger.error("Storage permission permanently denied.");
      _showSettingsDialog("Armazenamento");
    }

    // Request Microphone permission (needed for VoIP)
    PermissionStatus microphoneStatus = await Permission.microphone.request();
     if (microphoneStatus.isGranted) {
      Logger.info("Microphone permission granted.");
    } else if (microphoneStatus.isDenied) {
      Logger.warning("Microphone permission denied.");
    } else if (microphoneStatus.isPermanentlyDenied) {
      Logger.error("Microphone permission permanently denied.");
       _showSettingsDialog("Microfone");
    }

     // Request Camera permission (if video calls are planned)
    // PermissionStatus cameraStatus = await Permission.camera.request();
    // if (cameraStatus.isGranted) {
    //   Logger.info("Camera permission granted.");
    // } else {
    //   Logger.warning("Camera permission denied.");
    // }
  }

  // *** NOVO: Função para mostrar diálogo de configurações ***
  void _showSettingsDialog(String permissionName) {
     if (!mounted) return; // Check if the widget is still in the tree
     showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Permissão Necessária"),
          content: Text("A permissão de $permissionName foi negada permanentemente. Por favor, habilite-a nas configurações do aplicativo para usar todas as funcionalidades."),
          actions: <Widget>[
            TextButton(
              child: Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Abrir Configurações"),
              onPressed: () {
                openAppSettings(); // Opens app settings
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Logger.info("Switched to tab index: $index");
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    if (userProvider.isLoading || !userProvider.isUserDataLoaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
             valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    if (userProvider.user == null) {
       Logger.warning("HomeScreen build: User is null after loading. Redirecting to login.");
       return Scaffold(
         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
         body: Center(child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text("Erro ao carregar dados do usuário. Por favor, tente fazer login novamente.", textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
         )),
       );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('FEDERACAO MADOUT - ${userProvider.user?.displayName ?? 'Usuário'}'), // Updated title
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notificações',
            onPressed: () {
              Logger.info("Notifications button pressed.");
              // TODO: Implement navigation or overlay
            },
          ),
        ],
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
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Membros',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Missões',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

