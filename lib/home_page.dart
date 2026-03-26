import 'package:flutter/material.dart';
import 'timer_card.dart';
import 'timer_model.dart';

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key});

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> {
  List<TimerModel> timers = [
    TimerModel(title: 'Pasta', remainingSeconds: 600),
    TimerModel(title: 'Egg', remainingSeconds: 300),
  ];
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-Timer')),
      body: ListView.builder(
        itemCount: timers.length,
        itemBuilder: (context, index) {
          // This function runs for every item in our 'timers' list
          final currentTimer = timers[index];
          return TimerCard(timer: currentTimer);
        },
      ),
    );
  }
  }