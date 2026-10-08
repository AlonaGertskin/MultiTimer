import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'bundle_model.dart';
import 'bundle_store.dart';
import 'chain_model.dart';
import 'confirm_discard.dart';
import 'time_fields.dart';

class _ItemRow {
  final TextEditingController title = TextEditingController();
  final TimeFieldsController time = TimeFieldsController();
  bool startsNext;
  final int? stepId;

  _ItemRow({
    String title = '',
    int seconds = 0,
    this.startsNext = false,
    this.stepId,
  }) {
    this.title.text = title;
    if (seconds > 0) time.totalSeconds = seconds;
  }

  void dispose() {
    title.dispose();
    time.dispose();
  }
}

class ChainEdit {
  final String name;
  final List<ChainStep> steps;

  const ChainEdit(this.name, this.steps);
}

class BundleEditorPage extends StatefulWidget {
  final Bundle? editing;
  final ChainModel? chain;
  final List<BundleItem>? startWith;

  const BundleEditorPage({super.key, this.editing, this.chain, this.startWith});

  @override
  State<BundleEditorPage> createState() => _BundleEditorPageState();
}

class _BundleEditorPageState extends State<BundleEditorPage> {
  late final bool _isChain = widget.chain != null;
  late final List<int> _stepIdsAtOpen = [
    for (final step in widget.chain?.steps ?? <ChainStep>[]) step.id,
  ];
  late final int _currentIndexAtOpen = widget.chain?.currentIndex ?? 0;
  late final Bundle? _original = widget.chain == null
      ? widget.editing ??
            (widget.startWith == null
                ? null
                : Bundle(name: '', items: widget.startWith!))
      : Bundle(
          name: widget.chain!.name,
          items: [
            for (final step in widget.chain!.steps)
              BundleItem(
                title: step.title,
                seconds: step.seconds,
                startsNext: step.startsNext,
              ),
          ],
        );
  late final TextEditingController _nameController = TextEditingController(
    text: _original?.name,
  );
  late final List<_ItemRow> _rows = _original == null
      ? [_ItemRow()]
      : [
          for (var i = 0; i < _original.items.length; i++)
            _ItemRow(
              title: _original.items[i].title,
              seconds: _original.items[i].seconds,
              startsNext: _original.items[i].startsNext,
              stepId: _isChain ? _stepIdsAtOpen[i] : null,
            ),
        ];
  String? _error;

  int? _positionAtOpen(_ItemRow row) {
    final stepId = row.stepId;
    if (stepId == null) return null;
    final position = _stepIdsAtOpen.indexOf(stepId);
    return position < 0 ? null : position;
  }

  void _addRow() {
    setState(() => _rows.add(_ItemRow()));
  }

  void _removeRow(_ItemRow row) {
    setState(() => _rows.remove(row));
    row.dispose();
  }

  bool get _hasChanges {
    final original = _original;
    if (original == null) return _hasContent;
    if (_nameController.text.trim() != original.name) return true;
    if (_rows.length != original.items.length) return true;
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final item = original.items[i];
      if (row.title.text.trim() != item.title ||
          row.time.totalSeconds != item.seconds ||
          row.startsNext != item.startsNext) {
        return true;
      }
    }
    return false;
  }

  bool get _hasContent =>
      _nameController.text.trim().isNotEmpty ||
      _rows.length != 1 ||
      _rows.any(
        (row) => row.title.text.trim().isNotEmpty || row.time.totalSeconds > 0,
      );

  Future<void> _leave() async {
    if (_hasChanges && !await confirmDiscard(context)) return;
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _setAllLinks(bool startsNext) {
    setState(() {
      for (final row in _rows) {
        row.startsNext = startsNext;
      }
    });
  }

  void _reorderRows(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _rows.insert(newIndex, _rows.removeAt(oldIndex));
    });
  }

  bool _checkForm() {
    String? problem;
    if (_nameController.text.trim().isEmpty) {
      problem = _isChain
          ? 'Please enter a chain name.'
          : 'Please enter a bundle name.';
    } else if (_rows.isEmpty) {
      problem = 'Add at least one timer.';
    } else if (_rows.any((row) => row.title.text.trim().isEmpty)) {
      problem = 'Every timer needs a name.';
    } else if (_rows.any((row) => row.time.totalSeconds <= 0)) {
      problem = 'Every timer needs a time above zero.';
    }
    setState(() => _error = problem);
    return problem == null;
  }

  Bundle _bundleFromForm({int? id}) {
    return Bundle(
      id: id,
      name: _nameController.text.trim(),
      items: [
        for (final row in _rows)
          BundleItem(
            title: row.title.text.trim(),
            seconds: row.time.totalSeconds,
            startsNext: row.startsNext,
          ),
      ],
    );
  }

  Future<void> _saveAsBundle() async {
    if (!_checkForm()) return;
    final bundle = _bundleFromForm();
    final store = BundleStore();
    await store.save([...await store.load(), bundle]);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Bundle ${bundle.name} saved')));
  }

  void _save() {
    if (!_checkForm()) return;
    final name = _nameController.text.trim();

    if (_isChain) {
      Navigator.pop(
        context,
        ChainEdit(name, [
          for (final row in _rows)
            ChainStep(
              id: row.stepId,
              title: row.title.text.trim(),
              seconds: row.time.totalSeconds,
              startsNext: row.startsNext,
            ),
        ]),
      );
      return;
    }

    Navigator.pop(context, _bundleFromForm(id: widget.editing?.id));
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isChain
              ? 'Edit Chain'
              : widget.editing == null
              ? 'New Bundle'
              : 'Edit Bundle',
        ),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        buildDefaultDragHandles: false,
        onReorderStart: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        onReorder: _reorderRows,
        header: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _isChain ? 'Chain name' : 'Bundle name',
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
              ),
              if (_rows.length > 1)
                ExcludeFocus(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('All steps:'),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _setAllLinks(true),
                          child: const Text('Automatic'),
                        ),
                        TextButton(
                          onPressed: () => _setAllLinks(false),
                          child: const Text('Manual'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add timer'),
              onPressed: _addRow,
            ),
            if (_isChain)
              TextButton.icon(
                icon: const Icon(Icons.library_add_outlined),
                label: const Text('Save as bundle'),
                onPressed: _saveAsBundle,
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final row = _rows[index];
          final position = _positionAtOpen(row);
          final isCurrent = position == _currentIndexAtOpen;
          final isDone = position != null && position < _currentIndexAtOpen;
          final colors = Theme.of(context).colorScheme;
          return ReorderableDelayedDragStartListener(
            key: ObjectKey(row),
            index: index,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  color: isCurrent ? runningCardColor(colors) : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(12, 16, 8, 16),
                            child: Icon(Icons.drag_handle),
                          ),
                        ),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colors.onPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCurrent || isDone)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCurrent
                                            ? Icons.play_arrow
                                            : Icons.check,
                                        size: 16,
                                        color: isDone
                                            ? colors.onSurfaceVariant
                                            : null,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isCurrent ? 'Now' : 'Done',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: isDone
                                                  ? colors.onSurfaceVariant
                                                  : null,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              TextField(
                                controller: row.title,
                                decoration: const InputDecoration(
                                  labelText: 'Timer name',
                                  isDense: true,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 4),
                              TimeFields(
                                controller: row.time,
                                compact: true,
                                lastAction: row == _rows.last
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                              ),
                            ],
                          ),
                        ),
                        ExcludeFocus(
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove timer',
                            onPressed: () => _removeRow(row),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (row != _rows.last)
                  ExcludeFocus(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 4, 0),
                      child: Row(
                        children: [
                          Icon(
                            row.startsNext ? Icons.arrow_downward : Icons.pause,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Start next automatically'),
                          ),
                          Switch(
                            value: row.startsNext,
                            onChanged: (value) =>
                                setState(() => row.startsNext = value),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
