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
      body: const Center(
        child: Text('Tela de Chamada (Implementar UI)'),
      ),
    );
  }
}

