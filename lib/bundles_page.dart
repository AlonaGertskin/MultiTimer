import 'package:flutter/material.dart';
import 'bundle_editor_page.dart';
import 'bundle_model.dart';
import 'bundle_store.dart';
import 'time_format.dart';

class BundlesPage extends StatefulWidget {
  const BundlesPage({super.key});

  @override
  State<BundlesPage> createState() => _BundlesPageState();
}

class _BundlesPageState extends State<BundlesPage> {
  final BundleStore _store = BundleStore();
  List<Bundle> _bundles = [];

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

  String _summary(Bundle bundle) {
    final count = bundle.items.length;
    final total = bundle.items.fold<int>(0, (sum, item) => sum + item.seconds);
    return '$count ${count == 1 ? 'timer' : 'timers'} · ${formatSeconds(total)} total';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bundles')),
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
          : ListView.builder(
              itemCount: _bundles.length,
              itemBuilder: (context, index) {
                final bundle = _bundles[index];
                return ListTile(
                  title: Text(bundle.name),
                  subtitle: Text(_summary(bundle)),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBundle,
        icon: const Icon(Icons.add),
        label: const Text('New bundle'),
      ),
    );
  }
}
