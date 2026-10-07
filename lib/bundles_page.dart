import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'bundle_editor_page.dart';
import 'bundle_model.dart';
import 'bundle_store.dart';
import 'swipe_to_delete.dart';
import 'time_format.dart';

class BundlesPage extends StatefulWidget {
  const BundlesPage({super.key});

  @override
  State<BundlesPage> createState() => _BundlesPageState();
}

class _BundlesPageState extends State<BundlesPage> {
  final BundleStore _store = BundleStore();
  List<Bundle> _bundles = [];
  bool _editMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundles = await _store.load();
    if (!mounted) return;
    setState(() => _bundles = bundles);
  }

  Future<void> _createBundle() async {
    final bundle = await Navigator.push<Bundle>(
      context,
      MaterialPageRoute(builder: (context) => const BundleEditorPage()),
    );
    if (bundle == null) return;
    setState(() => _bundles.add(bundle));
    await _store.save(_bundles);
  }

  Future<void> _editBundle(Bundle bundle) async {
    final edited = await Navigator.push<Bundle>(
      context,
      MaterialPageRoute(
        builder: (context) => BundleEditorPage(editing: bundle),
      ),
    );
    if (edited == null) return;
    setState(() {
      final index = _bundles.indexOf(bundle);
      if (index >= 0) _bundles[index] = edited;
    });
    await _store.save(_bundles);
  }

  Future<void> _deleteWithUndo(List<Bundle> toDelete) async {
    if (toDelete.isEmpty) return;
    final removed = [
      for (final bundle in toDelete) (_bundles.indexOf(bundle), bundle),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    setState(() {
      _bundles.removeWhere(toDelete.contains);
      _selectedIds.removeAll(toDelete.map((bundle) => bundle.id));
    });
    await _store.save(_bundles);
    if (!mounted) return;
    final message = toDelete.length == 1
        ? '${toDelete.first.name} deleted'
        : '${toDelete.length} bundles deleted';
    showUndoSnackBar(context, message, () async {
      setState(() {
        for (final (index, bundle) in removed) {
          _bundles.insert(index.clamp(0, _bundles.length), bundle);
        }
      });
      await _store.save(_bundles);
    });
  }

  void _setEditMode(bool on) {
    setState(() {
      _editMode = on;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(Bundle bundle) {
    setState(() {
      if (!_selectedIds.remove(bundle.id)) _selectedIds.add(bundle.id);
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _bundles.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_bundles.map((bundle) => bundle.id));
      }
    });
  }

  void _deleteSelected() {
    _deleteWithUndo(
      _bundles.where((bundle) => _selectedIds.contains(bundle.id)).toList(),
    );
  }

  Future<void> _reorderBundles(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _bundles.insert(newIndex, _bundles.removeAt(oldIndex));
    });
    await _store.save(_bundles);
  }

  String _summary(Bundle bundle) {
    final count = bundle.items.length;
    final total = bundle.items.fold<int>(0, (sum, item) => sum + item.seconds);
    return '$count ${count == 1 ? 'timer' : 'timers'} · ${formatSeconds(total)} total';
  }

  PreferredSizeWidget _buildAppBar() {
    if (!_editMode) {
      return AppBar(
        title: const Text('Bundles'),
        actions: [
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
            ? 'Select bundles'
            : '${_selectedIds.length} selected',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select all',
          onPressed: _bundles.isEmpty ? null : _toggleSelectAll,
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

  Widget _buildRow(Bundle bundle, int index) {
    return ReorderableDelayedDragStartListener(
      key: ValueKey(bundle.id),
      index: index,
      child: Slidable(
        key: ValueKey('swipe-${bundle.id}'),
        groupTag: 'bundles',
        enabled: !_editMode,
        endActionPane: deleteActionPane(
          onDelete: () => _deleteWithUndo([bundle]),
          margin: EdgeInsets.zero,
        ),
        child: ListTile(
          leading: _editMode
              ? Checkbox(
                  value: _selectedIds.contains(bundle.id),
                  onChanged: (_) => _toggleSelected(bundle),
                )
              : null,
          title: Text(bundle.name),
          subtitle: Text(_summary(bundle)),
          trailing: _editMode
              ? ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit bundle',
                      onPressed: () => _editBundle(bundle),
                    ),
                    const Icon(Icons.playlist_add),
                  ],
                ),
          onTap: _editMode
              ? () => _toggleSelected(bundle)
              : () => Navigator.pop(context, bundle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _bundles.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No bundles yet.\nTap New bundle to create one.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SlidableAutoCloseBehavior(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: _bundles.length,
                onReorder: _reorderBundles,
                itemBuilder: (context, index) =>
                    _buildRow(_bundles[index], index),
              ),
            ),
      floatingActionButton: _editMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _createBundle,
              icon: const Icon(Icons.add),
              label: const Text('New bundle'),
            ),
    );
  }
}
