import 'dart:math';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'chain_model.dart';
import 'time_format.dart';

class ChainCard extends StatelessWidget {
  final ChainModel chain;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResetStep;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final VoidCallback onDetails;

  const ChainCard({
    super.key,
    required this.chain,
    required this.onStart,
    required this.onPause,
    required this.onResetStep,
    required this.onSkip,
    required this.onContinue,
    required this.onRestart,
    required this.onDetails,
  });

  static const _timeStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsYou = chain.isWaitingForContinue || chain.isComplete;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: needsYou
          ? finishedCardColor(theme.colorScheme)
          : chain.isRunning
          ? runningCardColor(theme.colorScheme)
          : readyCardColor(theme.colorScheme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chain.isComplete
              ? _buildComplete(context)
              : chain.isWaitingForContinue
              ? _buildWaiting(context)
              : _buildRunning(context),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.link, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${chain.name} · step ${chain.currentIndex + 1} of ${chain.steps.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _detailsButton(),
      ],
    );
  }

  Widget _detailsButton() {
    return IconButton(
      icon: const Icon(Icons.more_horiz),
      tooltip: 'Chain details',
      visualDensity: VisualDensity.compact,
      onPressed: onDetails,
    );
  }

  Widget _titleRow(BuildContext context, String title, {bool done = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Row(
        children: [
          if (done) ...[
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(formatClock(chain.remainingSeconds), style: _timeStyle),
        ],
      ),
    );
  }

  Widget _strip() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, right: 8),
      child: ChainProgressStrip(chain: chain),
    );
  }

  Widget? _skipButton() {
    if (chain.isLastStep) return null;
    return IconButton(
      icon: const Icon(Icons.skip_next),
      tooltip: 'Skip step',
      onPressed: onSkip,
    );
  }

  List<Widget> _buildRunning(BuildContext context) {
    final skip = _skipButton();
    return [
      _header(context),
      _titleRow(context, chain.currentStep.title),
      _strip(),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(chain.isRunning ? Icons.pause : Icons.play_arrow),
            tooltip: chain.isRunning ? 'Pause' : 'Start',
            onPressed: chain.isRunning ? onPause : onStart,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset step',
            onPressed: onResetStep,
          ),
          ?skip,
        ],
      ),
    ];
  }

  List<Widget> _buildWaiting(BuildContext context) {
    final next = chain.steps[chain.currentIndex + 1];
    final skip = _skipButton();
    return [
      _header(context),
      _titleRow(context, '${chain.currentStep.title} finished', done: true),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('Next: ${next.title} · ${formatClock(next.seconds)}'),
      ),
      _strip(),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ),
            ?skip,
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildComplete(BuildContext context) {
    return [
      _titleRow(context, '${chain.name} complete', done: true),
      _strip(),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: onRestart,
              child: const Text('Restart chain'),
            ),
            const Spacer(),
            _detailsButton(),
          ],
        ),
      ),
    ];
  }
}

class ChainProgressStrip extends StatelessWidget {
  final ChainModel chain;

  const ChainProgressStrip({super.key, required this.chain});

  double _fill(int index) {
    if (index < chain.currentIndex) return 1;
    if (index > chain.currentIndex) return 0;
    final seconds = chain.currentStep.seconds;
    final remaining = chain.remainingSeconds.clamp(0, seconds);
    return (seconds - remaining) / seconds;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final total = chain.steps.fold<int>(0, (sum, step) => sum + step.seconds);
    final smallest = max(1, total ~/ 20);

    return SizedBox(
      height: 6,
      child: Row(
        children: [
          for (var i = 0; i < chain.steps.length; i++) ...[
            Expanded(
              flex: max(chain.steps[i].seconds, smallest),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  color: colors.surfaceContainerHighest,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _fill(i),
                    heightFactor: 1,
                    child: Container(color: colors.primary),
                  ),
                ),
              ),
            ),
            if (i < chain.steps.length - 1 && !chain.steps[i].startsNext)
              SizedBox(key: ValueKey('manual-gap-$i'), width: 6),
          ],
        ],
      ),
    );
  }
}
