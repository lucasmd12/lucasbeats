import 'package:flutter/material.dart';
import 'package:federacaomad/utils/logger.dart'; // Assuming logger path
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class SplashScreen extends StatefulWidget {
  final bool showIndicator; // Control indicator visibility
  const SplashScreen({super.key, this.showIndicator = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer(); // Create an AudioPlayer instance

  @override
  void initState() {
    super.initState();
    Logger.info("SplashScreen initialized. Indicator: ${widget.showIndicator}");
    _playSplashSound(); // Play the sound on init
  }

  Future<void> _playSplashSound() async {
    try {
      // CORREÇÃO: Garantir que o caminho do asset está correto e existe
      await _audioPlayer.play(AssetSource('audio/splash_sound.mp3')); // Play the sound from assets
      Logger.info("Splash sound playback started.");
    } catch (e, stackTrace) {
      // CORREÇÃO: Adicionado parâmetro 'error' que estava faltando no log original
      Logger.error("Failed to play splash sound", error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Dispose the player when the screen is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // CORREÇÃO: Adicionado parêntese de fechamento para Scaffold
    return Scaffold(
      // Use the new background image
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images_png/loading_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use actual logo asset
              Image.asset(
                'assets/images_png/app_logo.png', // Use the new logo
                height: 120,
                // CORREÇÃO: Adicionada vírgula ausente após 'height'
                errorBuilder: (context, error, stackTrace) {
                  // CORREÇÃO: Adicionado parâmetro 'error' que estava faltando no log original
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
                'FEDERACAO MADOUT', // Updated App Name
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
      ), // Closes Container
    ); // Closes Scaffold
  }
}

