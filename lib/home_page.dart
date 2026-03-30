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
  ];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  void startTimer(TimerModel timer) {
    timer.start(() => setState(() {}));
  }

  void pauseTimer(TimerModel timer) {
    setState(() {
      timer.stop();
    });
  }

  void resetTimer(TimerModel timer) {
    setState(() {
      timer.reset();
    });
  }

  void _showAddTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Timer Title'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Hours Input
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    decoration: const InputDecoration(labelText: 'HH'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Text(' : '),
                // Minutes Input
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    decoration: const InputDecoration(labelText: 'MM'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Text(' : '),
                // Seconds Input
                Expanded(
                  child: TextField(
                    controller: _secondsController,
                    decoration: const InputDecoration(labelText: 'SS'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () {
              // Parse all inputs, defaulting to 0 if empty/invalid
              int h = int.tryParse(_hoursController.text) ?? 0;
              int m = int.tryParse(_minutesController.text) ?? 0;
              int s = int.tryParse(_secondsController.text) ?? 0;

              int totalSeconds = (h * 3600) + (m * 60) + s;

              if (_titleController.text.isNotEmpty && totalSeconds > 0) {
                setState(() {
                  timers.add(TimerModel(
                    title: _titleController.text,
                    remainingSeconds: totalSeconds,
                  ));
                });

                // Clear all controllers
                _titleController.clear();
                _hoursController.clear();
                _minutesController.clear();
                _secondsController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-Timer')),
      body: ListView.builder(
        itemCount: timers.length,
        itemBuilder: (context, index) {
          final currentTimer = timers[index];
          return TimerCard(
            timer: currentTimer,
            onStart: () => startTimer(currentTimer),
            onPause: () => pauseTimer(currentTimer),
            onReset: () => resetTimer(currentTimer),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
  @override
  void dispose() {
    // We loop through our data list
    for (var timer in timers) {
      // If a timer has a "motor" running, we kill it
      timer.internalTimer?.cancel();
    }
    super.dispose(); // Always call the "base class" destructor last
  }
}

