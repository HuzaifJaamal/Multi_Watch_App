import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Chat')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Center(
        child:
        SizedBox(
          height: 140,
          child: Lottie.asset("assets/lottie/Chat.json", repeat: true),
        ),
      ),
    );
  }
}
