import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';

void main() {
  Bundle workout() => Bundle(name: 'Workout', items: const [
        BundleItem(title: 'Warm-up', seconds: 300, startsNext: true),
        BundleItem(title: 'Set', seconds: 60),
        BundleItem(title: 'Cool-down', seconds: 180),
      ]);

  group('Bundle', () {
    test('every bundle gets its own id', () {
      final ids = List.generate(
          50, (_) => Bundle(name: 'A', items: const [BundleItem(title: 'x', seconds: 1)]).id);

      expect(ids.toSet().length, 50);
    });

    test('a bundle survives a round trip with its timers and links', () {
      final original = workout();

      final loaded = Bundle.fromMap(original.toMap());

      expect(loaded.id, original.id);
      expect(loaded.name, 'Workout');
      expect(loaded.items.map((i) => i.title), ['Warm-up', 'Set', 'Cool-down']);
      expect(loaded.items.map((i) => i.seconds), [300, 60, 180]);
      expect(loaded.items.map((i) => i.startsNext), [true, false, false]);
    });

    test('a timer saved without a link setting loads as manual', () {
      final item = BundleItem.fromMap({'title': 'Set', 'seconds': 60});

      expect(item.startsNext, false);
    });

    test('a bundle with no timers is rejected', () {
      expect(
        () => Bundle.fromMap({'name': 'Empty', 'items': []}),
        throwsFormatException,
      );
    });

    test('a timer with no time is rejected', () {
      expect(
        () => BundleItem.fromMap({'title': 'Set', 'seconds': 0}),
        throwsFormatException,
      );
    });
  });

  group('Bundle.listFromJson', () {
    test('loads a saved list of bundles in order', () {
      final json = Bundle.listToJson([
        workout(),
        Bundle(name: 'Dinner', items: const [
          BundleItem(title: 'Pasta', seconds: 600),
        ]),
      ]);

      final bundles = Bundle.listFromJson(json);

      expect(bundles.map((b) => b.name), ['Workout', 'Dinner']);
    });

    test('skips bad bundles and keeps the good ones', () {
      final json = jsonEncode([
        workout().toMap(),
        {'name': 'No timers'},
        {'name': 'Empty', 'items': []},
        {'name': 'Zero', 'items': [{'title': 'x', 'seconds': 0}]},
        'not a bundle',
        workout().toMap(),
      ]);

      expect(Bundle.listFromJson(json).length, 2);
    });

    test('returns an empty list for unreadable data', () {
      expect(Bundle.listFromJson('{{ not json'), isEmpty);
      expect(Bundle.listFromJson('{"a": 1}'), isEmpty);
    });
  });
}
