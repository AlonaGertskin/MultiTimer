import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'max_value_formatter.dart';
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
    NotificationService.instance.schedule(
      id: timer.id,
      title: timer.title,
      when: timer.endTime!,
    );
    _saveTimers();
  }

  void pauseTimer(TimerModel timer) {
    setState(() {
      timer.stop();
    });
    NotificationService.instance.cancel(timer.id);
    _saveTimers();
  }

  void resetTimer(TimerModel timer) {
    setState(() {
      timer.reset();
    });
    NotificationService.instance.cancel(timer.id);
    _saveTimers();
  }

  void deleteTimer(TimerModel timer) {
    setState(() {
      timer.stop();
      timers.remove(timer);
    });
    NotificationService.instance.cancel(timer.id);
    _saveTimers();
  }

  void _clearDialogFields() {
    _titleController.clear();
    _hoursController.clear();
    _minutesController.clear();
    _secondsController.clear();
  }

  Widget _timeField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    int? max,
    bool isLast = false,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
          if (max != null) MaxValueFormatter(max),
        ],
        onChanged: (value) {
          final isFull = value.length >= 2 ||
              (max != null && value.isNotEmpty && int.parse(value) * 10 > max);
          if (!isFull) return;
          if (isLast) {
            FocusScope.of(context).unfocus();
          } else {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }

  String _digits(int value) => value == 0 ? '' : value.toString();

  void _applyEdit(TimerModel timer, String title, int totalSeconds) {
    final durationChanged = totalSeconds != timer.initialSeconds;
    setState(() {
      timer.title = title;
      if (durationChanged) timer.updateDuration(totalSeconds);
    });
    if (durationChanged) {
      NotificationService.instance.cancel(timer.id);
    } else if (timer.isRunning) {
      NotificationService.instance.schedule(
        id: timer.id,
        title: timer.title,
        when: timer.endTime!,
      );
    }
    _saveTimers();
  }

  void _showTimerDialog({TimerModel? editing}) {
    String? error;
    if (editing != null) {
      _titleController.text = editing.title;
      _hoursController.text = _digits(editing.initialSeconds ~/ 3600);
      _minutesController.text = _digits(editing.initialSeconds % 3600 ~/ 60);
      _secondsController.text = _digits(editing.initialSeconds % 60);
    } else {
      _clearDialogFields();
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editing == null ? 'Add New Timer' : 'Edit Timer'),
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
                  _timeField(context, _hoursController, 'HH'),
                  const Text(' : '),
                  _timeField(context, _minutesController, 'MM', max: 59),
                  const Text(' : '),
                  _timeField(context, _secondsController, 'SS',
                      max: 59, isLast: true),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  _clearDialogFields();
                  Navigator.pop(context);
                },
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                int h = int.tryParse(_hoursController.text) ?? 0;
                int m = int.tryParse(_minutesController.text) ?? 0;
                int s = int.tryParse(_secondsController.text) ?? 0;

                int totalSeconds = (h * 3600) + (m * 60) + s;

                if (_titleController.text.trim().isEmpty) {
                  setDialogState(() => error = 'Please enter a title.');
                } else if (totalSeconds <= 0) {
                  setDialogState(() => error = 'Please enter a time above zero.');
                } else {
                  final title = _titleController.text.trim();
                  if (editing == null) {
                    setState(() {
                      timers.add(TimerModel(
                        title: title,
                        remainingSeconds: totalSeconds,
                      ));
                    });
                    _saveTimers();
                  } else {
                    _applyEdit(editing, title, totalSeconds);
                  }
                  _clearDialogFields();
                  Navigator.pop(context);
                }
              },
              child: Text(editing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
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
            onEdit: () => _showTimerDialog(editing: currentTimer),
            onDelete: () => deleteTimer(currentTimer),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTimerDialog,
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
