import 'package:flutter/material.dart';
import 'timer_model.dart';

class TimerCard extends StatelessWidget {
  final TimerModel timer;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  // functions for controls, have to be passed down from home page

  const TimerCard({
    super.key,
    required this.timer,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    // require having instructions for the controls
  });

  String formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;           // 3600 seconds in an hour
    int minutes = (totalSeconds % 3600) ~/ 60;  // Remainder of hours, divided by 60
    int seconds = totalSeconds % 60;            // The leftover seconds

    String h = hours.toString();
    String m = minutes.toString().padLeft(2, '0');
    String s = seconds.toString().padLeft(2, '0');

    // If we have hours, show H:MM:SS
    if (hours > 0) {
      return '$h:$m:$s';
    } else {
      // Otherwise, just show MM:SS (or M:SS)
      return '$minutes:$s';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(timer.title),
            trailing: Text(
              formatTime(timer.remainingSeconds),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
                onPressed: timer.isRunning ? onPause : onStart,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}