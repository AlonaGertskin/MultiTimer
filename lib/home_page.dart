import 'package:flutter/material.dart';
import 'timer_card.dart';

class MyMainPage extends StatelessWidget {
  const MyMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Multi-Timer')),
        body: ListView(
            children: [
              TimerCard(),
              TimerCard(),
              TimerCard(),
            ]
        )
    );
  }
}