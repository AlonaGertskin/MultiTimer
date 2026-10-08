import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'card_parts.dart';
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

    final initial = timer.initialSeconds;
    final progress = initial > 0
        ? (initial - timer.remainingSeconds.clamp(0, initial)) / initial
        : 1.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: finished
          ? finishedCardColor(colors)
          : timer.isRunning
          ? runningCardColor(colors)
          : readyCardColor(colors),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Row(
                children: [
                  Icon(
                    finished
                        ? Icons.check_circle_outline
                        : Icons.timer_outlined,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timer.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    formatTime(timer.remainingSeconds),
                    style: cardTimeStyle(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                color: colors.primary,
                backgroundColor: progressTrackColor(colors),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!finished)
                  IconButton(
                    icon: Icon(
                      timer.isRunning ? Icons.pause : Icons.play_arrow,
                    ),
                    tooltip: timer.isRunning ? 'Pause' : 'Start',
                    onPressed: timer.isRunning ? onPause : onStart,
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset',
                  onPressed: onReset,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
