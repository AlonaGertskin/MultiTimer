import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'app_colors.dart';
import 'bundle_editor_page.dart';
import 'bundle_model.dart';
import 'bundle_store.dart';
import 'chain_card.dart';
import 'chain_model.dart';
import 'empty_list_message.dart';
import 'swipe_to_delete.dart';
import 'time_format.dart';

const _newBundleButtonSpace = 88.0;

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

  ChainModel _preview(Bundle bundle) => ChainModel(
    name: bundle.name,
    steps: [
      for (final item in bundle.items)
        ChainStep(
          title: item.title,
          seconds: item.seconds,
          startsNext: item.startsNext,
        ),
    ],
  );

  Widget _buildRow(Bundle bundle, int index) {
    final theme = Theme.of(context);
    final soft = theme.colorScheme.onSurfaceVariant;
    final isChain = bundle.items.length > 1;

    return ReorderableDelayedDragStartListener(
      key: ValueKey(bundle.id),
      index: index,
      child: Slidable(
        key: ValueKey('swipe-${bundle.id}'),
        groupTag: 'bundles',
        enabled: !_editMode,
        endActionPane: deleteActionPane(
          onDelete: () => _deleteWithUndo([bundle]),
        ),
        child: Row(
          children: [
            if (_editMode)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Checkbox(
                  value: _selectedIds.contains(bundle.id),
                  onChanged: (_) => _toggleSelected(bundle),
                ),
              ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: readyCardColor(theme.colorScheme),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _editMode ? () => _toggleSelected(bundle) : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isChain ? Icons.link : Icons.timer_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bundle.name,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            if (_editMode)
                              const SizedBox(height: 48)
                            else
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit bundle',
                                onPressed: () => _editBundle(bundle),
                              ),
                          ],
                        ),
                        if (isChain)
                          Text(
                            bundle.items.map((item) => item.title).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: soft,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, right: 8),
                          child: ChainProgressStrip(chain: _preview(bundle)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _summary(bundle),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: soft,
                                  ),
                                ),
                              ),
                              if (_editMode)
                                const SizedBox(height: 40)
                              else
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add'),
                                  onPressed: () =>
                                      Navigator.pop(context, bundle),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_editMode)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 16, 12, 16),
                  child: Icon(Icons.drag_handle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _bundles.isEmpty
          ? const EmptyListMessage(
              icon: Icons.inventory_2_outlined,
              title: 'No bundles yet',
              hint: TextSpan(
                text: 'Save a group of timers you use often, like Dinner.',
              ),
            )
          : SlidableAutoCloseBehavior(
              child: ReorderableListView.builder(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.paddingOf(context).bottom +
                      (_editMode ? 0 : _newBundleButtonSpace),
                ),
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
