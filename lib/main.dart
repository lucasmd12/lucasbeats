import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/call_page.dart';

// Import Providers and Utils
import 'providers/user_provider.dart';
import 'providers/connectivity_provider.dart';
import 'utils/logger.dart'; // Assuming Logger exists and works

import 'widgets/app_lifecycle_reactor.dart';
import 'services/notification_service.dart';

// Import Firebase options
import 'firebase_options.dart';

// Global Future for Firebase Initialization to ensure it runs only once
Future<FirebaseApp>? _initialization;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.info('App Initialization Started.');

  // Ensure Firebase is initialized only once using the global Future
  _initialization ??= Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    // Await the single initialization future
    await _initialization;
    Logger.info('Firebase Initialized Successfully.');

    // Force portrait orientation
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      Logger.info('Screen orientation set to portrait.');
    } catch (e, stackTrace) {
      Logger.error('Failed to set screen orientation', error: e, stackTrace: stackTrace);
    }

    // Initialize NotificationService after Firebase
    final notificationService = NotificationService();
    // Don't await here to avoid blocking startup
    notificationService.initialize().catchError((e, s) {
      Logger.error("Error initializing NotificationService", error: e, stackTrace: s);
    });

    Logger.info("Running FEDERACAOMAD App.");
    runApp(const FEDERACAOMADApp());

  } catch (e, stackTrace) {
    // Handle Firebase initialization error more gracefully
    Logger.error('Firebase Initialization Failed during await', error: e, stackTrace: stackTrace);
    runApp(FirebaseErrorApp(error: e.toString())); // Show error screen
  }
}

// Simple App to display Firebase initialization errors
class FirebaseErrorApp extends StatelessWidget {
  final String error;
  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Erro Crítico na Inicialização\nFalha ao conectar aos serviços. Verifique sua conexão e tente novamente.\nDetalhes: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}


class FEDERACAOMADApp extends StatelessWidget {
  const FEDERACAOMADApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.debug("Building FEDERACAOMADApp Widget.");

    // The error handling is now done before runApp in main
    // if (_firebaseInitializationFailed) { ... } // This block is removed

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        // ChangeNotifierProvider(create: (context) => CallProvider()), // Keep commented if not ready
      ],
      child: AppLifecycleReactor(
        child: MaterialApp(
          title: 'FEDERACAOMAD',
          debugShowCheckedModeBanner: false,
          theme: _buildThemeData(),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen(showIndicator: true);
              }
              if (snapshot.hasData && snapshot.data != null) {
                return const HomeScreen();
              }
              return const LoginScreen();
            },
          ),
          routes: {
            "/splash": (context) => const SplashScreen(),
            "/login": (context) => const LoginScreen(),
            "/register": (context) => const RegisterScreen(),
            "/home": (context) => const HomeScreen(),
            "/call": (context) => const CallPage(),
          },
        ),
      ),
    );
  }

  ThemeData _buildThemeData() {
    // Theme data remains the same...
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E2C), // Dark background
      primaryColor: const Color(0xFF9147FF), // Purple accent
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF9147FF), // Purple
        secondary: const Color(0xFF7289DA), // Discord-like blue/purple
        background: const Color(0xFF2C2F33), // Dark grey background elements
        surface: const Color(0xFF23272A), // Slightly lighter grey for surfaces
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.white70,
        onSurface: Colors.white,
        onError: Colors.redAccent,
      ),
      cardColor: const Color(0xFF2C2F33), // Card background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF23272A), // App bar background
        elevation: 0,
        foregroundColor: Colors.white, // Title/icon color
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Gothic', // Ensure Gothic font is available
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF23272A), // Input field background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF4F545C)), // Subtle border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF9147FF), width: 2), // Purple focus border
        ),
        labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Gothic'),
        hintStyle: TextStyle(color: Colors.white54, fontFamily: 'Gothic'),
        prefixIconColor: Colors.white70,
        errorStyle: TextStyle(color: Colors.redAccent, fontFamily: 'Gothic'),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'Gothic', fontSize: 14),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Gothic'),
        labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Gothic', fontSize: 16), // Button text
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Gothic'),
        titleMedium: TextStyle(color: Colors.white70, fontFamily: 'Gothic'),
        displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Gothic'), // For Splash/Login Title
        displayMedium: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Gothic'), // For Splash/Login Subtitle
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9147FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Gothic'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF7289DA), // Secondary color for text buttons
          textStyle: const TextStyle(fontFamily: 'Gothic'),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF23272A),
        selectedItemColor: Color(0xFF9147FF),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed, // Ensure labels are always visible
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Gothic'),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontFamily: 'Gothic'),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF9147FF), // Use primary color for indicators
      ),
    );
  }
}

