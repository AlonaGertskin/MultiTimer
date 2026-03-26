import 'package:flutter/material.dart';
import 'timer_card.dart';
import 'timer_model.dart';
import 'dart:async'; //contains the Timer class

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

  void startTimer(TimerModel timer) {
    // For now, we just print to the console to make sure the "link" works
    print('Starting timer for: ${timer.title}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Multi-Timer')),
        body: ListView.builder(
            itemCount: timers.length,
            itemBuilder: (context, index) {
              // This function runs for every item in our 'timers' list
              final currentTimer = timers[index];
              return InkWell(
                onTap: () {
                  // Small step: Just call our print function
                  startTimer(currentTimer);
                },
                child: TimerCard(timer: currentTimer),
              );
            }
        )
    );
  }
}