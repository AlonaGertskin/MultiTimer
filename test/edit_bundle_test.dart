import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/bundle_store.dart';
import 'package:multitimer/bundles_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<Bundle> seeded;

  Finder field(String label) => find.widgetWithText(TextField, label);

  String textIn(WidgetTester tester, Finder finder) =>
      tester.widget<TextField>(finder).controller!.text;

  Future<void> openBundles(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    seeded = [
      Bundle(
        name: 'Dinner',
        items: [
          BundleItem(title: 'Pasta', seconds: 600, startsNext: true),
          BundleItem(title: 'Sauce', seconds: 3725),
        ],
      ),
      Bundle(name: 'Workout', items: [BundleItem(title: 'Plank', seconds: 60)]),
    ];
    await BundleStore().save(seeded);
    await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester, int index) async {
    await openBundles(tester);
    await tester.tap(find.byTooltip('Edit bundle').at(index));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  final askDialog = find.text('Discard changes?');

  group('Edit button', () {
    testWidgets('every bundle has a pencil button', (tester) async {
      await openBundles(tester);

      expect(find.byTooltip('Edit bundle'), findsNWidgets(2));
    });

    testWidgets('the pencil opens the editor and adds nothing', (tester) async {
      await openEditor(tester, 0);

      expect(find.text('Edit Bundle'), findsOneWidget);
      expect(find.text('New Bundle'), findsNothing);
    });

    testWidgets('the pencil is hidden in edit mode', (tester) async {
      await openBundles(tester);

      await tester.tap(find.byTooltip('Edit list'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Edit bundle'), findsNothing);
    });

    testWidgets('a new bundle still opens the New Bundle editor', (
      tester,
    ) async {
      await openBundles(tester);

      await tester.tap(find.text('New bundle'));
      await tester.pumpAndSettle();

      expect(find.text('New Bundle'), findsOneWidget);
      expect(textIn(tester, field('Bundle name')), '');
    });
  });

  group('The edit form', () {
    testWidgets('is filled with the name, timers and times', (tester) async {
      await openEditor(tester, 0);

      expect(textIn(tester, field('Bundle name')), 'Dinner');
      expect(
        tester
            .widgetList<TextField>(field('Timer name'))
            .map((f) => f.controller!.text),
        ['Pasta', 'Sauce'],
      );
      expect(textIn(tester, field('HH').at(0)), '');
      expect(textIn(tester, field('MM').at(0)), '10');
      expect(textIn(tester, field('SS').at(0)), '');
      expect(textIn(tester, field('HH').at(1)), '01');
      expect(textIn(tester, field('MM').at(1)), '02');
      expect(textIn(tester, field('SS').at(1)), '05');
    });
  });

  group('Saving an edit', () {
    testWidgets('renaming keeps the place, the id and the timers', (
      tester,
    ) async {
      await openEditor(tester, 0);

      await tester.enterText(field('Bundle name'), 'Supper');
      await save(tester);

      expect(find.text('Supper'), findsOneWidget);
      expect(find.text('Dinner'), findsNothing);
      final saved = await BundleStore().load();
      expect(saved.map((b) => b.name), ['Supper', 'Workout']);
      expect(saved.first.id, seeded.first.id);
      expect(saved.first.items.map((i) => i.title), ['Pasta', 'Sauce']);
      expect(saved.first.items.map((i) => i.seconds), [600, 3725]);
    });

    testWidgets('changing a time and adding a timer are saved', (tester) async {
      await openEditor(tester, 1);

      await tester.enterText(field('MM').first, '02');
      await tester.tap(find.text('Add timer'));
      await tester.pump();
      await tester.enterText(field('Timer name').last, 'Rest');
      await tester.enterText(field('SS').last, '30');
      await save(tester);

      final saved = (await BundleStore().load())[1];
      expect(saved.id, seeded[1].id);
      expect(saved.items.map((i) => i.title), ['Plank', 'Rest']);
      expect(saved.items.map((i) => i.seconds), [120, 30]);
      expect(find.text('2 timers · 2:30 total'), findsOneWidget);
    });

    testWidgets('the start-next setting of each step is kept', (tester) async {
      await openEditor(tester, 0);

      await tester.enterText(field('Bundle name'), 'Supper');
      await save(tester);

      final saved = (await BundleStore().load()).first;
      expect(saved.items.map((i) => i.startsNext), [true, false]);
    });

    testWidgets('a removed timer takes only itself away', (tester) async {
      await openEditor(tester, 0);

      await tester.tap(find.byTooltip('Remove timer').first);
      await tester.pump();
      await save(tester);

      final saved = (await BundleStore().load()).first;
      expect(saved.items.map((i) => i.title), ['Sauce']);
      expect(saved.items.map((i) => i.startsNext), [false]);
    });

    testWidgets('the checks still apply', (tester) async {
      await openEditor(tester, 0);

      await tester.enterText(field('Bundle name'), '');
      await save(tester);

      expect(find.text('Please enter a bundle name.'), findsOneWidget);
      expect(find.text('Edit Bundle'), findsOneWidget);
    });

    testWidgets('the bundle can still be added after editing', (tester) async {
      await openEditor(tester, 0);
      await tester.enterText(field('Bundle name'), 'Supper');
      await save(tester);

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Supper'),
            matching: find.byType(Card),
          ),
          matching: find.text('Add'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BundlesPage), findsNothing);
    });
  });

  group('Leaving the edit form', () {
    testWidgets('does not ask when nothing was changed', (tester) async {
      await openEditor(tester, 0);

      await pressBack(tester);

      expect(askDialog, findsNothing);
      expect(find.text('Edit Bundle'), findsNothing);
    });

    testWidgets('asks when the name was changed', (tester) async {
      await openEditor(tester, 0);
      await tester.enterText(field('Bundle name'), 'Supper');

      await pressBack(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('asks when a time was changed', (tester) async {
      await openEditor(tester, 0);
      await tester.enterText(field('MM').first, '11');

      await pressBack(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('asks when the steps were reordered', (tester) async {
      await openEditor(tester, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_handle).first),
      );
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      await pressBack(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('does not ask if the change was put back', (tester) async {
      await openEditor(tester, 0);
      await tester.enterText(field('Bundle name'), 'Supper');
      await tester.enterText(field('Bundle name'), 'Dinner');

      await pressBack(tester);

      expect(askDialog, findsNothing);
    });

    testWidgets('discard leaves the bundle as it was', (tester) async {
      await openEditor(tester, 0);
      await tester.enterText(field('Bundle name'), 'Supper');
      await pressBack(tester);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Supper'), findsNothing);
      expect((await BundleStore().load()).first.name, 'Dinner');
    });
  });
}
