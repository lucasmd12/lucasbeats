import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';
import '../utils/logger.dart';

// Import Tab Widgets from the correct location
import '../screens/tabs/home_tab.dart';
import '../screens/tabs/members_tab.dart';
import '../screens/tabs/missions_tab.dart';
import '../screens/tabs/settings_tab.dart';
import '../screens/tabs/chat_list_tab.dart'; // Added for Chat

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Default to Home tab

  // Define the screens/tabs for the BottomNavigationBar using the correct imports
  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    MembersTab(),
    ChatListTab(),
    MissionsTab(),
    SettingsTab(),
  ];

  // Background images for different sections (optional)
  final List<String> _backgroundImages = [
    'assets/images_png/background_image_01.png',
    'assets/images_png/background_image_02.png',
    'assets/images_png/background_image_03.png',
    'assets/images_png/background_image_04.png',
    'assets/images_png/background_image_05.png',
  ];

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

    // Show loading indicator if user data is still loading
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

    // If user data failed to load or user is null after load, redirect to login
    if (userProvider.user == null) {
       Logger.warn("HomeScreen build: User is null after loading. Redirecting to login.");
       // This scenario should ideally be handled by the StreamBuilder in main.dart,
       // but as a fallback, we can navigate here.
       // WidgetsBinding.instance.addPostFrameCallback((_) {
       //   Navigator.pushReplacementNamed(context, '/login');
       // });
       // Or show an error screen
       return Scaffold(
         body: Center(child: Text("Erro ao carregar dados do usuário.", style: textTheme.bodyMedium)),
       );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('LAMAFIA - ${userProvider.user?.displayName ?? 'Usuário'}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none), // Use a real icon
            tooltip: 'Notificações',
            onPressed: () {
              Logger.info("Notifications button pressed.");
              // TODO: Implement navigation to notifications screen or show overlay
            },
          ),
          // Optional: Add other actions like search or profile
        ],
      ),
      body: Container(
        // Apply background based on selected tab
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImages[_selectedIndex % _backgroundImages.length]),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6), // Darken background slightly
              BlendMode.darken,
            ),
          ),
        ),
        // Display the selected tab's content
        child: IndexedStack( // Use IndexedStack to keep tab state
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
        // Use theme colors from BottomNavigationBarTheme for consistency
        // backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        // selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        // unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        // type: Theme.of(context).bottomNavigationBarTheme.type,
        // selectedLabelStyle: Theme.of(context).bottomNavigationBarTheme.selectedLabelStyle,
        // unselectedLabelStyle: Theme.of(context).bottomNavigationBarTheme.unselectedLabelStyle,
      ),
      // Remove or assign a real function to the FAB
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Logger.info("Floating Action Button pressed.");
      //     // TODO: Implement action (e.g., start new chat, create mission)
      //   },
      //   backgroundColor: Theme.of(context).primaryColor,
      //   child: const Icon(Icons.add, color: Colors.white),
      //   tooltip: 'Nova Ação',
      // ),
    );
  }
}
