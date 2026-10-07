import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/bundle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts with no bundles', () async {
    expect(await BundleStore().load(), isEmpty);
  });

  test('saved bundles load back the same', () async {
    final bundle = Bundle(name: 'Dinner', items: const [
      BundleItem(title: 'Pasta', seconds: 600, startsNext: true),
      BundleItem(title: 'Sauce', seconds: 900),
    ]);

    await BundleStore().save([bundle]);
    final loaded = await BundleStore().load();

    expect(loaded.length, 1);
    expect(loaded.first.id, bundle.id);
    expect(loaded.first.name, 'Dinner');
    expect(loaded.first.items.map((i) => i.title), ['Pasta', 'Sauce']);
    expect(loaded.first.items.first.startsNext, true);
  });

  test('saving again replaces what was saved before', () async {
    final store = BundleStore();
    final item = const BundleItem(title: 'x', seconds: 5);

    await store.save([
      Bundle(name: 'One', items: [item]),
      Bundle(name: 'Two', items: [item]),
    ]);
    await store.save([Bundle(name: 'Three', items: [item])]);

    expect((await store.load()).map((b) => b.name), ['Three']);
  });

  test('unreadable saved data loads as no bundles', () async {
    SharedPreferences.setMockInitialValues({'saved_bundles': 'garbage'});

    expect(await BundleStore().load(), isEmpty);
  });
}
