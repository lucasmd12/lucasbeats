import 'package:flutter/material.dart';
import 'package:lamarfiadobem/utils/logger.dart'; // Assuming logger path

class SplashScreen extends StatefulWidget {
  final bool showIndicator; // Control indicator visibility
  const SplashScreen({super.key, this.showIndicator = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigation is now handled by StreamBuilder in main.dart
    // Only navigate if explicitly told (e.g., after a fixed delay if not checking auth)
    // Future.delayed(const Duration(seconds: 3), () {
    //   if (mounted && !widget.showIndicator) { // Avoid navigation if just showing indicator
    //     Navigator.pushReplacementNamed(context, '/login');
    //   }
    // });
    Logger.info("SplashScreen initialized. Indicator: ${widget.showIndicator}");
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use actual logo asset
            Image.asset(
              'assets/images_png/1000216621.png', // Use the specified icon/logo
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                Logger.error("Failed to load splash logo", error: error, stackTrace: stackTrace);
                return Icon(
                  Icons.shield_moon, // Fallback icon
                  size: 100,
                  color: Theme.of(context).primaryColor,
                );
              },
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'LAMAFIA',
              style: textTheme.displayLarge?.copyWith(fontSize: 36),
            ),
            const SizedBox(height: 16),
            // Subtitle or slogan
            Text(
              'Comunicação e organização para o clã',
              style: textTheme.displayMedium,
            ),
            const SizedBox(height: 48),
            // Loading Indicator (conditionally shown)
            if (widget.showIndicator)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              )
            else // Show a subtle animation or nothing if not waiting for auth
              const SizedBox(height: 48), // Maintain spacing
          ],
        ),
      ),
    );
  }
}

