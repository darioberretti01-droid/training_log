import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Log')),
      body: const Center(
        child: Text(
          'Environment ready. Next step: implement Milestone 1.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
