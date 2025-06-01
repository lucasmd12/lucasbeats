import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Import Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/call_page.dart';

// Import Providers and Utils
import 'providers/user_provider.dart'; // Assuming this will handle user state after login via backend
import 'providers/auth_provider.dart'; // New provider to manage auth state
import 'providers/connectivity_provider.dart';
import 'utils/logger.dart'; // Assuming Logger exists and works

import 'widgets/app_lifecycle_reactor.dart';
// import 'services/notification_service.dart'; // Removed Firebase dependent notification service

// Removed Firebase options import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.info('App Initialization Started.');

  // Removed Firebase initialization

  try {
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

    // Removed NotificationService initialization

    Logger.info("Running FEDERACAOMAD App.");
    runApp(const FEDERACAOMADApp());

  } catch (e, stackTrace) {
    // Generic error handling during startup
    Logger.error('App Initialization Failed', error: e, stackTrace: stackTrace);
    runApp(InitializationErrorApp(error: e.toString())); // Show generic error screen
  }
}

// Simple App to display initialization errors
class InitializationErrorApp extends StatelessWidget {
  final String error;
  const InitializationErrorApp({super.key, required this.error});

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
              'Erro Crítico na Inicialização\nFalha ao iniciar o aplicativo.\nDetalhes: $error',
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()), // Add AuthProvider
        ChangeNotifierProvider(create: (context) => UserProvider()),
        // ChangeNotifierProvider(create: (context) => CallProvider()), // Keep commented if not ready
      ],
      child: AppLifecycleReactor(
        child: MaterialApp(
          title: 'FEDERACAOMAD',
          debugShowCheckedModeBanner: false,
          theme: _buildThemeData(),
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Check authentication status from AuthProvider
              switch (authProvider.status) {
                case AuthStatus.uninitialized:
                case AuthStatus.authenticating:
                  return const SplashScreen(showIndicator: true);
                case AuthStatus.authenticated:
                  return const HomeScreen();
                case AuthStatus.unauthenticated:
                default:
                  return const LoginScreen();
              }
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

// Placeholder for AuthProvider - Needs implementation
enum AuthStatus { uninitialized, authenticating, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  AuthStatus get status => _status;

  AuthProvider() {
    // TODO: Check for stored token or session info on startup
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Simulate checking stored token
    await Future.delayed(const Duration(seconds: 1)); 
    // Replace with actual logic to check token validity with backend
    bool hasToken = false; // Example: await SecureStorage.hasToken();
    if (hasToken) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    // TODO: Call backend login endpoint
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    // Example: bool success = await ApiService.login(email, password);
    bool success = true; // Assume success for now
    if (success) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    // TODO: Clear stored token/session
    // TODO: Notify backend if necessary
    notifyListeners();
  }
}

