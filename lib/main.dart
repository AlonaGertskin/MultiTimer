import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: MyMainPage()));
}

// We moved the UI into its own Class to keep things organized
class MyMainPage extends StatelessWidget {
  const MyMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-Timer')),
      body: const Center(child: Text('This is my clean slate.')),
    );
  }
}