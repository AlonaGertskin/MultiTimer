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
    // Mark the timer as 'Running'
    timer.isRunning = true;
    // Create the periodic timer
    Timer.periodic(const Duration(seconds: 1), (t) {
      // 'State' update. this is what makes the screen change.
      setState(() {
        if (timer.remainingSeconds > 0) {
          timer.remainingSeconds--; // Subtract 1 second
        } else {
          t.cancel(); // Stop the clock when it hits zero
          timer.isRunning = false;
        }
      });
    });
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