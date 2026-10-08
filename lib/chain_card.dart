import 'package:flutter/material.dart';
import 'chain_model.dart';
import 'time_format.dart';

class ChainCard extends StatelessWidget {
  final ChainModel chain;

  const ChainCard({super.key, required this.chain});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.link),
        title: Text(chain.name),
        subtitle: Text(
          '${chain.currentStep.title} · step ${chain.currentIndex + 1} '
          'of ${chain.steps.length}',
        ),
        trailing: Text(
          formatClock(chain.remainingSeconds),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
