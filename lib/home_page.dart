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
    timer.internalTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      // 'State' update. this is what makes the screen change.
      setState(() {
        if (timer.remainingSeconds > 0) {
          timer.remainingSeconds--; // Subtract 1 second
        } else {
          timer.internalTimer?.cancel(); // Stop the clock when it hits zero
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
                  // Only start the timer if it isn't ALREADY running
                  if (!currentTimer.isRunning) {
                    startTimer(currentTimer);
                  }
                },
                child: TimerCard(timer: currentTimer),
              );
            }
        )
    );
  }
  @override
  void dispose() {
    // We loop through our data list
    for (var timer in timers) {
      // If a timer has a "motor" running, we kill it
      timer.internalTimer?.cancel();
    }
    print("Main Page Disposed - All motors killed.");
    super.dispose(); // Always call the "base class" destructor last
  }
}

