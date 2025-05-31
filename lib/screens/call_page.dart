import 'package:flutter/material.dart';

class CallPage extends StatelessWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement Call UI using CallProvider
    // - Show contact name/avatar
    // - Show call status (calling, connected, etc.)
    // - Buttons: Mute, Speaker, End Call
    return Scaffold(
      appBar: AppBar(title: const Text('Chamada em Andamento')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images_png/voice_channel_placeholder.jpg',
              height: 200, // Adjust size as needed
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.mic_off, // Fallback icon
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Implementar UI da chamada aqui'),
            // TODO: Add call controls (Mute, Speaker, End Call)
          ],
        ),
      ),
    );
  }
}

