import 'package:flutter/material.dart';
import 'timer_model.dart';

class TimerCard extends StatelessWidget {
  final TimerModel timer;

  //  the constructor to REQUIRE a timer.
  const TimerCard({super.key, required this.timer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.timer_outlined),
        // Use the data from the 'timer' variable!
        title: Text(timer.title),
        trailing: Text(
          '${timer.remainingSeconds}s', // Temporary: shows raw seconds
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}