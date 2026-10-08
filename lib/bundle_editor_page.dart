import 'package:flutter/material.dart';
import 'bundle_model.dart';
import 'confirm_discard.dart';
import 'time_fields.dart';

class _ItemRow {
  final TextEditingController title = TextEditingController();
  final TimeFieldsController time = TimeFieldsController();
  bool startsNext;

  _ItemRow({String title = '', int seconds = 0, this.startsNext = false}) {
    this.title.text = title;
    if (seconds > 0) time.totalSeconds = seconds;
  }

  void dispose() {
    title.dispose();
    time.dispose();
  }
}

class BundleEditorPage extends StatefulWidget {
  final Bundle? editing;

  const BundleEditorPage({super.key, this.editing});

  @override
  State<BundleEditorPage> createState() => _BundleEditorPageState();
}

class _BundleEditorPageState extends State<BundleEditorPage> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.editing?.name,
  );
  late final List<_ItemRow> _rows = widget.editing == null
      ? [_ItemRow()]
      : [
          for (final item in widget.editing!.items)
            _ItemRow(
              title: item.title,
              seconds: item.seconds,
              startsNext: item.startsNext,
            ),
        ];
  String? _error;

  void _addRow() {
    setState(() => _rows.add(_ItemRow()));
  }

  void _removeRow(_ItemRow row) {
    setState(() => _rows.remove(row));
    row.dispose();
  }

  bool get _hasChanges {
    final original = widget.editing;
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

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a bundle name.');
      return;
    }
    if (_rows.isEmpty) {
      setState(() => _error = 'Add at least one timer.');
      return;
    }
    if (_rows.any((row) => row.title.text.trim().isEmpty)) {
      setState(() => _error = 'Every timer needs a name.');
      return;
    }
    if (_rows.any((row) => row.time.totalSeconds <= 0)) {
      setState(() => _error = 'Every timer needs a time above zero.');
      return;
    }

    Navigator.pop(
      context,
      Bundle(
        id: widget.editing?.id,
        name: name,
        items: [
          for (final row in _rows)
            BundleItem(
              title: row.title.text.trim(),
              seconds: row.time.totalSeconds,
              startsNext: row.startsNext,
            ),
        ],
      ),
    );
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
        title: Text(widget.editing == null ? 'New Bundle' : 'Edit Bundle'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
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
                decoration: const InputDecoration(labelText: 'Bundle name'),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
              ),
              if (_rows.length > 1)
                ExcludeFocus(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
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
          return ReorderableDelayedDragStartListener(
            key: ObjectKey(row),
            index: index,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 16),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(12, 16, 12, 16),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: row.title,
                            decoration: const InputDecoration(
                              labelText: 'Timer name',
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 8),
                          TimeFields(
                            controller: row.time,
                            lastAction: row == _rows.last
                                ? TextInputAction.done
                                : TextInputAction.next,
                          ),
                          if (row != _rows.last)
                            ExcludeFocus(
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('Start next automatically'),
                                value: row.startsNext,
                                onChanged: (value) =>
                                    setState(() => row.startsNext = value),
                              ),
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
          );
        },
      ),
    );
  }
}
