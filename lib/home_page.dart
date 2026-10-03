import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bundles_page.dart';
import 'notification_service.dart';
import 'time_fields.dart';
import 'timer_card.dart';
import 'timer_model.dart';

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key});

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> with WidgetsBindingObserver {
  List<TimerModel> timers = [];
  bool _reorderMode = false;
  final TextEditingController _titleController = TextEditingController();
  final TimeFieldsController _timeController = TimeFieldsController();

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
    _timeController.clear();
  }

  void _reorderTimers(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      timers.insert(newIndex, timers.removeAt(oldIndex));
    });
    _saveTimers();
  }

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
      _timeController.totalSeconds = editing.initialSeconds;
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
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TimeFields(controller: _timeController),
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
                final totalSeconds = _timeController.totalSeconds;

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
      appBar: AppBar(
        title: const Text('Multi-Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Bundles',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BundlesPage()),
            ),
          ),
          IconButton(
            icon: Icon(_reorderMode ? Icons.check : Icons.swap_vert),
            tooltip: _reorderMode ? 'Done reordering' : 'Reorder timers',
            onPressed: () => setState(() => _reorderMode = !_reorderMode),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: timers.length,
        onReorder: _reorderTimers,
        itemBuilder: (context, index) {
          final currentTimer = timers[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey(currentTimer.id),
            index: index,
            child: Row(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.centerLeft,
                  child: _reorderMode
                      ? ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 0, 16),
                            child: Icon(Icons.drag_handle),
                          ),
                        )
                      : const SizedBox(width: 0),
                ),
                Expanded(
                  child: TimerCard(
                    timer: currentTimer,
                    onStart: () => startTimer(currentTimer),
                    onPause: () => pauseTimer(currentTimer),
                    onReset: () => resetTimer(currentTimer),
                    onEdit: () => _showTimerDialog(editing: currentTimer),
                    onDelete: () => deleteTimer(currentTimer),
                  ),
                ),
              ],
            ),
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
    _timeController.dispose();
    super.dispose();
  }
}
