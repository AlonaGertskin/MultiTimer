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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Bundle name'),
          ),
          const SizedBox(height: 16),
          for (final row in _rows)
            Card(
              key: ObjectKey(row),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: row.title,
                            decoration:
                                const InputDecoration(labelText: 'Timer name'),
                          ),
                          const SizedBox(height: 8),
                          TimeFields(controller: row.time),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove timer',
                      onPressed: () => _removeRow(row),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add timer'),
              onPressed: _addRow,
            ),
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
    );
  }
}
