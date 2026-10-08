import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bundle_editor_page.dart';
import 'bundle_model.dart';
import 'bundles_page.dart';
import 'chain_card.dart';
import 'chain_model.dart';
import 'confirm_discard.dart';
import 'list_item.dart';
import 'notification_service.dart';
import 'swipe_to_delete.dart';
import 'time_fields.dart';
import 'timer_card.dart';
import 'timer_model.dart';

class _RemovedItem {
  final ListItem item;
  final int index;
  final DateTime? end;

  const _RemovedItem(this.item, this.index, this.end);
}

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key});

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> with WidgetsBindingObserver {
  List<ListItem> items = [];
  bool _editMode = false;
  final Set<int> _selectedIds = {};
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
      for (final item in items) {
        if (item.isRunning) item.syncWithClock();
      }
    });
  }

  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timersJson = prefs.getString('saved_timers');
    if (timersJson == null || !mounted) return;

    setState(() {
      items = ListItem.listFromJson(timersJson);
    });

    for (final item in items) {
      if (!item.isRunning) continue;
      if (item is TimerModel) startTimer(item);
      if (item is ChainModel) {
        item.resume(item.endTime!, _refresh);
        _scheduleChainAlerts(item);
      }
    }
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      items.map((item) => item.toMap()).toList(),
    );
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

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _scheduleChainAlerts(
    ChainModel chain, {
    Iterable<int> alsoCancel = const [],
  }) {
    for (final id in {...alsoCancel, ...chain.steps.map((step) => step.id)}) {
      NotificationService.instance.cancel(id);
    }
    for (final alert in chain.upcomingAlerts()) {
      NotificationService.instance.schedule(
        id: alert.id,
        title: alert.title,
        body: alert.body,
        when: alert.when,
      );
    }
  }

  void _changeChain(ChainModel chain, VoidCallback change) {
    final stepIdsBefore = chain.steps.map((step) => step.id).toList();
    setState(change);
    _scheduleChainAlerts(chain, alsoCancel: stepIdsBefore);
    _saveTimers();
  }

  void _restartWithUndo(ChainModel chain) {
    final before = chain.toMap();
    _changeChain(chain, chain.restartChain);
    showUndoSnackBar(
      context,
      '${chain.name} restarted',
      () => _putChainBack(chain, before),
    );
  }

  void _putChainBack(ChainModel chain, Map<String, dynamic> before) {
    if (!mounted) return;
    final index = items.indexOf(chain);
    if (index < 0) return;
    final restored = ChainModel.fromMap(before);
    setState(() {
      chain.pause();
      items[index] = restored;
      final end = restored.endTime;
      if (restored.isRunning && end != null) restored.resume(end, _refresh);
    });
    _scheduleChainAlerts(restored, alsoCancel: chain.steps.map((s) => s.id));
    _saveTimers();
  }

  Future<void> _openChainDetails(ChainModel chain) async {
    final edit = await Navigator.push<ChainEdit>(
      context,
      MaterialPageRoute(builder: (context) => BundleEditorPage(chain: chain)),
    );
    if (edit == null || !mounted) return;
    final index = items.indexOf(chain);
    if (index < 0) return;
    final stepIdsBefore = chain.steps.map((step) => step.id).toList();

    setState(() => chain.applyEdit(edit.name, edit.steps));
    if (chain.steps.length > 1) {
      _scheduleChainAlerts(chain, alsoCancel: stepIdsBefore);
      _saveTimers();
      return;
    }

    for (final id in stepIdsBefore) {
      NotificationService.instance.cancel(id);
    }
    final timer = TimerModel(
      title: chain.currentStep.title,
      remainingSeconds: chain.remainingSeconds,
    )..initialSeconds = chain.currentStep.seconds;
    final end = chain.endTime;
    setState(() {
      chain.pause();
      items[index] = timer;
    });
    if (end != null) {
      timer.resume(end, _refresh);
      NotificationService.instance.schedule(
        id: timer.id,
        title: timer.title,
        when: end,
      );
    }
    _saveTimers();
  }

  Future<void> _confirmDeleteChain(ChainModel chain) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${chain.name}?'),
        content: Text(
          'This removes the whole chain (${chain.steps.length} steps).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete == true && mounted) _deleteWithUndo([chain]);
  }

  String _nameOf(ListItem item) => switch (item) {
    ChainModel chain => chain.name,
    TimerModel timer => timer.title,
    _ => '',
  };

  void _stopItem(ListItem item) {
    if (item is TimerModel) item.stop();
    if (item is ChainModel) item.pause();
  }

  void _deleteWithUndo(List<ListItem> toDelete) {
    if (toDelete.isEmpty) return;
    final removed = [
      for (final item in toDelete)
        _RemovedItem(
          item,
          items.indexOf(item),
          item.isRunning ? item.endTime : null,
        ),
    ]..sort((a, b) => a.index.compareTo(b.index));

    setState(() {
      for (final entry in removed) {
        _stopItem(entry.item);
        items.remove(entry.item);
        _selectedIds.remove(entry.item.id);
      }
    });
    for (final entry in removed) {
      final item = entry.item;
      if (item is TimerModel) NotificationService.instance.cancel(item.id);
      if (item is ChainModel) {
        for (final step in item.steps) {
          NotificationService.instance.cancel(step.id);
        }
      }
    }
    _saveTimers();

    showUndoSnackBar(
      context,
      removed.length == 1
          ? '${_nameOf(removed.first.item)} deleted'
          : '${removed.length} timers deleted',
      () => _restoreItems(removed),
    );
  }

  void _restoreItems(List<_RemovedItem> removed) {
    if (!mounted) return;
    setState(() {
      for (final entry in removed) {
        items.insert(entry.index.clamp(0, items.length), entry.item);
        final end = entry.end;
        final item = entry.item;
        if (end == null) continue;
        if (item is TimerModel) item.resume(end, _refresh);
        if (item is ChainModel) item.resume(end, _refresh);
      }
    });
    for (final entry in removed) {
      final end = entry.end;
      final item = entry.item;
      if (end != null && item is TimerModel) {
        NotificationService.instance.schedule(
          id: item.id,
          title: item.title,
          when: end,
        );
      }
      if (item is ChainModel) _scheduleChainAlerts(item);
    }
    _saveTimers();
  }

  void _setEditMode(bool on) {
    setState(() {
      _editMode = on;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(ListItem item) {
    setState(() {
      if (!_selectedIds.remove(item.id)) _selectedIds.add(item.id);
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(items.map((item) => item.id));
      }
    });
  }

  void _deleteSelected() {
    _deleteWithUndo(
      items.where((item) => _selectedIds.contains(item.id)).toList(),
    );
  }

  void _clearDialogFields() {
    _titleController.clear();
    _timeController.clear();
  }

  void _reorderTimers(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      items.insert(newIndex, items.removeAt(oldIndex));
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

  Future<void> _openBundles() async {
    final bundle = await Navigator.push<Bundle>(
      context,
      MaterialPageRoute(builder: (context) => const BundlesPage()),
    );
    if (bundle == null || !mounted) return;

    final isChain = bundle.items.length > 1;
    final ListItem added = isChain
        ? ChainModel(
            name: bundle.name,
            steps: [
              for (final item in bundle.items)
                ChainStep(
                  title: item.title,
                  seconds: item.seconds,
                  startsNext: item.startsNext,
                ),
            ],
          )
        : TimerModel(
            title: bundle.items.first.title,
            remainingSeconds: bundle.items.first.seconds,
          );
    setState(() => items.add(added));
    _saveTimers();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isChain
              ? 'Added ${bundle.name} (${bundle.items.length} steps)'
              : 'Added 1 timer from ${bundle.name}',
        ),
      ),
    );
  }

  bool _dialogHasChanges(TimerModel? editing) {
    if (editing == null) {
      return _titleController.text.trim().isNotEmpty ||
          _timeController.totalSeconds > 0;
    }
    return _titleController.text.trim() != editing.title ||
        _timeController.totalSeconds != editing.initialSeconds;
  }

  Future<void> _closeDialog(BuildContext context, TimerModel? editing) async {
    if (_dialogHasChanges(editing) && !await confirmDiscard(context)) return;
    if (!context.mounted) return;
    _clearDialogFields();
    Navigator.pop(context);
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
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _closeDialog(context, editing);
        },
        child: StatefulBuilder(
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final totalSeconds = _timeController.totalSeconds;

                  if (_titleController.text.trim().isEmpty) {
                    setDialogState(() => error = 'Please enter a title.');
                  } else if (totalSeconds <= 0) {
                    setDialogState(
                      () => error = 'Please enter a time above zero.',
                    );
                  } else {
                    final title = _titleController.text.trim();
                    if (editing == null) {
                      setState(() {
                        items.add(
                          TimerModel(
                            title: title,
                            remainingSeconds: totalSeconds,
                          ),
                        );
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (!_editMode) {
      return AppBar(
        title: const Text('Multi-Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Bundles',
            onPressed: _openBundles,
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Edit list',
            onPressed: () => _setEditMode(true),
          ),
        ],
      );
    }
    return AppBar(
      title: Text(
        _selectedIds.isEmpty
            ? 'Select timers'
            : '${_selectedIds.length} selected',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select all',
          onPressed: items.isEmpty ? null : _toggleSelectAll,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete selected',
          onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
        ),
        IconButton(
          icon: const Icon(Icons.check),
          tooltip: 'Done',
          onPressed: () => _setEditMode(false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SlidableAutoCloseBehavior(
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: items.length,
          onReorder: _reorderTimers,
          itemBuilder: (context, index) {
            final item = items[index];
            return ReorderableDelayedDragStartListener(
              key: ValueKey(item.id),
              index: index,
              child: Slidable(
                key: ValueKey('swipe-${item.id}'),
                groupTag: 'timers',
                enabled: !_editMode,
                startActionPane: item is ChainModel
                    ? restartActionPane(onRestart: () => _restartWithUndo(item))
                    : null,
                endActionPane: deleteActionPane(
                  onDelete: () => item is ChainModel
                      ? _confirmDeleteChain(item)
                      : _deleteWithUndo([item]),
                ),
                child: Row(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.centerLeft,
                      child: _editMode
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Checkbox(
                                value: _selectedIds.contains(item.id),
                                onChanged: (_) => _toggleSelected(item),
                              ),
                            )
                          : const SizedBox(width: 0),
                    ),
                    Expanded(
                      child: switch (item) {
                        TimerModel timer => TimerCard(
                          timer: timer,
                          onStart: () => startTimer(timer),
                          onPause: () => pauseTimer(timer),
                          onReset: () => resetTimer(timer),
                          onEdit: () => _showTimerDialog(editing: timer),
                        ),
                        ChainModel chain => ChainCard(
                          chain: chain,
                          onStart: () =>
                              _changeChain(chain, () => chain.start(_refresh)),
                          onPause: () => _changeChain(chain, chain.pause),
                          onResetStep: () =>
                              _changeChain(chain, chain.resetStep),
                          onSkip: () =>
                              _changeChain(chain, () => chain.skip(_refresh)),
                          onContinue: () => _changeChain(
                            chain,
                            () => chain.continueToNext(_refresh),
                          ),
                          onRestart: () =>
                              _changeChain(chain, chain.restartChain),
                          onDetails: () => _openChainDetails(chain),
                        ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.centerRight,
                      child: _editMode
                          ? ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(0, 16, 12, 16),
                                child: Icon(Icons.drag_handle),
                              ),
                            )
                          : const SizedBox(width: 0),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _editMode
          ? null
          : FloatingActionButton(
              onPressed: _showTimerDialog,
              child: const Icon(Icons.add),
            ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final item in items) {
      item.internalTimer?.cancel();
    }
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
