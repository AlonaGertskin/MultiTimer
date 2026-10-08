import 'package:flutter/material.dart';
import 'time_format.dart';
import 'timer_model.dart';

class TimerCard extends StatelessWidget {
  final TimerModel timer;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onEdit;

  const TimerCard({
    super.key,
    required this.timer,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onEdit,
  });

  String formatTime(int totalSeconds) => formatClock(totalSeconds);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final finished = timer.isFinished;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: finished ? colors.secondaryContainer : null,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              finished ? Icons.check_circle_outline : Icons.timer_outlined,
            ),
            title: Text(timer.title),
            trailing: Text(
              formatTime(timer.remainingSeconds),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
                  onPressed: timer.isRunning ? onPause : onStart,
                ),
                IconButton(icon: const Icon(Icons.refresh), onPressed: onReset),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
