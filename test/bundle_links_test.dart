import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/bundle_store.dart';
import 'package:multitimer/bundles_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder field(String label) => find.widgetWithText(TextField, label);
  final switches = find.byType(Switch);
  final askDialog = find.text('Discard changes?');

  List<bool> switchValues(WidgetTester tester) =>
      tester.widgetList<Switch>(switches).map((s) => s.value).toList();

  Future<void> setUpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> openNewBundle(WidgetTester tester, List<String> names) async {
    await setUpScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New bundle'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Bundle name'), 'Workout');
    for (var i = 0; i < names.length; i++) {
      if (i > 0) {
        await tester.tap(find.text('Add timer'));
        await tester.pump();
      }
      await tester.enterText(field('Timer name').at(i), names[i]);
      await tester.enterText(field('MM').at(i), '0${i + 1}');
    }
    await tester.pump();
  }

  Future<void> openSavedBundle(WidgetTester tester, List<bool> links) async {
    await setUpScreen(tester);
    await BundleStore().save([
      Bundle(
        name: 'Workout',
        items: [
          for (var i = 0; i < links.length; i++)
            BundleItem(title: 'Step $i', seconds: 60, startsNext: links[i]),
        ],
      ),
    ]);
    await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit bundle'));
    await tester.pumpAndSettle();
  }

  Future<List<bool>> saveAndRead(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = await BundleStore().load();
    return saved.single.items.map((i) => i.startsNext).toList();
  }

  Future<List<String>> savedTitles() async =>
      (await BundleStore().load()).single.items.map((i) => i.title).toList();

  Future<void> dragHandle(
    WidgetTester tester,
    int index,
    double distance,
  ) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_handle).at(index)),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, distance / 10));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('The start-next switch', () {
    testWidgets('a single timer has no switch and no All steps buttons', (
      tester,
    ) async {
      await openNewBundle(tester, ['Plank']);

      expect(switches, findsNothing);
      expect(find.text('Automatic'), findsNothing);
      expect(find.text('Manual'), findsNothing);
    });

    testWidgets('every timer except the last has a switch, off at first', (
      tester,
    ) async {
      await openNewBundle(tester, ['Warm-up', 'Set', 'Cool-down']);

      expect(switches, findsNWidgets(2));
      expect(find.text('Start next automatically'), findsNWidgets(2));
      expect(switchValues(tester), [false, false]);
    });

    testWidgets('turning a switch on is saved', (tester) async {
      await openNewBundle(tester, ['Warm-up', 'Set', 'Cool-down']);

      await tester.tap(switches.first);
      await tester.pump();

      expect(await saveAndRead(tester), [true, false, false]);
    });

    testWidgets('the switch moves with its timer when reordering', (
      tester,
    ) async {
      await openNewBundle(tester, ['First', 'Second', 'Third']);
      await tester.tap(switches.at(1));
      await tester.pump();

      await dragHandle(tester, 0, 170);

      expect(switchValues(tester), [true, false]);
      expect(await saveAndRead(tester), [true, false, false]);
      expect(await savedTitles(), ['Second', 'First', 'Third']);
    });

    testWidgets('a timer moved to the end hides its switch but keeps it', (
      tester,
    ) async {
      await openNewBundle(tester, ['First', 'Second']);
      await tester.tap(switches.first);
      await tester.pump();

      await dragHandle(tester, 0, 260);

      expect(switchValues(tester), [false]);
      expect(await saveAndRead(tester), [false, true]);
      expect(await savedTitles(), ['Second', 'First']);
    });

    testWidgets('a new timer added at the end gives the old last one a '
        'switch', (tester) async {
      await openNewBundle(tester, ['First']);
      expect(switches, findsNothing);

      await tester.tap(find.text('Add timer'));
      await tester.pump();

      expect(switches, findsOneWidget);
    });
  });

  group('All steps buttons', () {
    testWidgets('fit on a narrow phone', (tester) async {
      await openNewBundle(tester, ['Warm-up', 'Set']);

      tester.view.physicalSize = const Size(360, 2400);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Automatic'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
    });

    testWidgets('Automatic turns every switch on', (tester) async {
      await openNewBundle(tester, ['Warm-up', 'Set', 'Cool-down']);

      await tester.tap(find.text('Automatic'));
      await tester.pump();

      expect(switchValues(tester), [true, true]);
      expect(await saveAndRead(tester), [true, true, true]);
    });

    testWidgets('Manual turns every switch off', (tester) async {
      await openNewBundle(tester, ['Warm-up', 'Set', 'Cool-down']);
      await tester.tap(find.text('Automatic'));
      await tester.pump();

      await tester.tap(find.text('Manual'));
      await tester.pump();

      expect(switchValues(tester), [false, false]);
      expect(await saveAndRead(tester), [false, false, false]);
    });

    testWidgets('single switches can still be changed afterwards', (
      tester,
    ) async {
      await openNewBundle(tester, ['Warm-up', 'Set', 'Cool-down']);
      await tester.tap(find.text('Automatic'));
      await tester.pump();

      await tester.tap(switches.at(1));
      await tester.pump();

      expect(await saveAndRead(tester), [true, false, true]);
    });
  });

  group('Editing a saved bundle', () {
    testWidgets('the switches show the saved settings', (tester) async {
      await openSavedBundle(tester, [true, false, false]);

      expect(switchValues(tester), [true, false]);
    });

    testWidgets('flipping a switch asks before leaving', (tester) async {
      await openSavedBundle(tester, [true, false, false]);

      await tester.tap(switches.at(1));
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(askDialog, findsOneWidget);
    });

    testWidgets('flipping a switch back does not ask', (tester) async {
      await openSavedBundle(tester, [true, false, false]);

      await tester.tap(switches.first);
      await tester.pump();
      await tester.tap(switches.first);
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(askDialog, findsNothing);
      expect(find.text('Edit Bundle'), findsNothing);
    });

    testWidgets('saving keeps the new settings', (tester) async {
      await openSavedBundle(tester, [true, false, false]);

      await tester.tap(switches.at(1));
      await tester.pump();

      expect(await saveAndRead(tester), [true, true, false]);
    });
  });
}
