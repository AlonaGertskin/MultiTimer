import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'timer_card.dart';
import 'timer_model.dart';

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key});

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> with WidgetsBindingObserver {
  List<TimerModel> timers = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTimers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    setState(() {
      for (var timer in timers) {
        if (timer.isRunning) timer.syncWithClock();
      }
    });
  }

  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timersJson = prefs.getString('saved_timers');
    if (timersJson == null || !mounted) return;

    setState(() {
      timers = TimerModel.listFromJson(timersJson);
    });

    for (var timer in timers) {
      if (timer.isRunning) startTimer(timer);
    }
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(timers.map((t) => t.toMap()).toList());
    await prefs.setString('saved_timers', encoded);
  }

  void startTimer(TimerModel timer) {
    timer.start(() {
      if (mounted) setState(() {});
    });
    _saveTimers();
  }

  void pauseTimer(TimerModel timer) {
    setState(() {
      timer.stop();
    });
    _saveTimers();
  }

  void resetTimer(TimerModel timer) {
    setState(() {
      timer.reset();
    });
    _saveTimers();
  }

  void deleteTimer(TimerModel timer) {
    setState(() {
      timer.stop();
      timers.remove(timer);
    });
    _saveTimers();
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
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    decoration: const InputDecoration(labelText: 'HH'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Text(' : '),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    decoration: const InputDecoration(labelText: 'MM'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Text(' : '),
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
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
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
                _saveTimers();

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
      appBar: AppBar(
        title: const Text('Multi-Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: NotificationService.instance.showTest,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: timers.length,
        itemBuilder: (context, index) {
          final currentTimer = timers[index];
          return TimerCard(
            timer: currentTimer,
            onStart: () => startTimer(currentTimer),
            onPause: () => pauseTimer(currentTimer),
            onReset: () => resetTimer(currentTimer),
            onDelete: () => deleteTimer(currentTimer),
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
    WidgetsBinding.instance.removeObserver(this);
    for (var timer in timers) {
      timer.internalTimer?.cancel();
    }
    _titleController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }
}
