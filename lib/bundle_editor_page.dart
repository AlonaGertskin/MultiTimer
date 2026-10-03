import 'package:flutter/material.dart';
import 'bundle_model.dart';
import 'time_fields.dart';

class _ItemRow {
  final TextEditingController title = TextEditingController();
  final TimeFieldsController time = TimeFieldsController();

  void dispose() {
    title.dispose();
    time.dispose();
  }
}

class BundleEditorPage extends StatefulWidget {
  const BundleEditorPage({super.key});

  @override
  State<BundleEditorPage> createState() => _BundleEditorPageState();
}

class _BundleEditorPageState extends State<BundleEditorPage> {
  final TextEditingController _nameController = TextEditingController();
  final List<_ItemRow> _rows = [_ItemRow()];
  String? _error;

  void _addRow() {
    setState(() => _rows.add(_ItemRow()));
  }

  void _removeRow(_ItemRow row) {
    setState(() => _rows.remove(row));
    row.dispose();
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
        name: name,
        items: [
          for (final row in _rows)
            BundleItem(
              title: row.title.text.trim(),
              seconds: row.time.totalSeconds,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bundle'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        buildDefaultDragHandles: false,
        onReorderStart: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        onReorder: _reorderRows,
        header: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Bundle name'),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
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
                            decoration:
                                const InputDecoration(labelText: 'Timer name'),
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
