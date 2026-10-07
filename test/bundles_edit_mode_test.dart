import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/bundle_store.dart';
import 'package:multitimer/bundles_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Bundle bundle(String name) =>
      Bundle(name: name, items: [BundleItem(title: 'Step', seconds: 60)]);

  Future<void> openBundles(WidgetTester tester, List<String> names) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await BundleStore().save(names.map(bundle).toList());
    await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
    await tester.pumpAndSettle();
  }

  Future<void> enterEditMode(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Edit list'));
    await tester.pumpAndSettle();
  }

  Future<void> check(WidgetTester tester, int index) async {
    await tester.tap(find.byType(Checkbox).at(index));
    await tester.pump();
  }

  Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  bool isDisabled(WidgetTester tester, IconData icon) =>
      tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon)).onPressed ==
      null;

  Future<List<String>> savedNames() async =>
      (await BundleStore().load()).map((b) => b.name).toList();

  List<String> shownOrder(WidgetTester tester, List<String> names) {
    final found =
        names.where((n) => find.text(n).evaluate().isNotEmpty).toList();
    found.sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );
    return found;
  }

  Future<void> dragBy(
    WidgetTester tester,
    Offset start,
    double distance, {
    bool hold = false,
  }) async {
    final gesture = await tester.startGesture(start);
    if (hold) {
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, distance / 10));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('Edit mode', () {
    testWidgets('the button shows handles and checkboxes on every bundle', (
      tester,
    ) async {
      await openBundles(tester, ['A', 'B', 'C']);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing);

      await enterEditMode(tester);

      expect(find.byType(Checkbox), findsNWidgets(3));
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
    });

    testWidgets('Done hides them again', (tester) async {
      await openBundles(tester, ['A']);
      await enterEditMode(tester);

      await tapTooltip(tester, 'Done');

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
      expect(find.text('Bundles'), findsOneWidget);
    });

    testWidgets('the New bundle button is hidden in edit mode', (tester) async {
      await openBundles(tester, ['A']);
      expect(find.text('New bundle'), findsOneWidget);

      await enterEditMode(tester);

      expect(find.text('New bundle'), findsNothing);
    });

    testWidgets('the top bar counts what is selected', (tester) async {
      await openBundles(tester, ['A', 'B', 'C']);

      await enterEditMode(tester);
      expect(find.text('Select bundles'), findsOneWidget);

      await check(tester, 0);
      expect(find.text('1 selected'), findsOneWidget);

      await check(tester, 2);
      expect(find.text('2 selected'), findsOneWidget);

      await check(tester, 0);
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('tapping a bundle in edit mode selects it and adds nothing', (
      tester,
    ) async {
      await openBundles(tester, ['A', 'B']);
      await enterEditMode(tester);

      await tester.tap(find.text('B'));
      await tester.pump();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byType(BundlesPage), findsOneWidget);
    });

    testWidgets('select all selects everything, and again clears it', (
      tester,
    ) async {
      await openBundles(tester, ['A', 'B', 'C']);
      await enterEditMode(tester);

      await tapTooltip(tester, 'Select all');
      expect(find.text('3 selected'), findsOneWidget);

      await tapTooltip(tester, 'Select all');
      expect(find.text('Select bundles'), findsOneWidget);
    });

    testWidgets('leaving edit mode forgets the selection', (tester) async {
      await openBundles(tester, ['A', 'B']);
      await enterEditMode(tester);
      await check(tester, 0);

      await tapTooltip(tester, 'Done');
      await enterEditMode(tester);

      expect(find.text('Select bundles'), findsOneWidget);
      expect(
        tester.widgetList<Checkbox>(find.byType(Checkbox)).map((c) => c.value),
        [false, false],
      );
    });

    testWidgets('swiping does nothing in edit mode', (tester) async {
      await openBundles(tester, ['A']);
      await enterEditMode(tester);
      final before = tester.getTopLeft(find.text('A'));

      await tester.drag(find.text('A'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('A')), before);
    });

    testWidgets('outside edit mode, tapping a bundle still adds it', (
      tester,
    ) async {
      await openBundles(tester, ['A']);

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(find.byType(BundlesPage), findsNothing);
    });
  });

  group('Delete selected', () {
    testWidgets('is disabled while nothing is selected', (tester) async {
      await openBundles(tester, ['A']);
      await enterEditMode(tester);

      expect(isDisabled(tester, Icons.delete_outline), true);

      await check(tester, 0);

      expect(isDisabled(tester, Icons.delete_outline), false);
    });

    testWidgets('deletes every selected bundle and shows one Undo message', (
      tester,
    ) async {
      await openBundles(tester, ['A', 'B', 'C']);
      await enterEditMode(tester);
      await check(tester, 0);
      await check(tester, 2);

      await tapTooltip(tester, 'Delete selected');

      expect(find.text('A'), findsNothing);
      expect(find.text('C'), findsNothing);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('2 bundles deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(await savedNames(), ['B']);
    });

    testWidgets('one selected bundle says its name', (tester) async {
      await openBundles(tester, ['A', 'B']);
      await enterEditMode(tester);
      await check(tester, 1);

      await tapTooltip(tester, 'Delete selected');

      expect(find.text('B deleted'), findsOneWidget);
    });

    testWidgets('stays in edit mode with nothing selected afterwards', (
      tester,
    ) async {
      await openBundles(tester, ['A', 'B']);
      await enterEditMode(tester);
      await check(tester, 0);

      await tapTooltip(tester, 'Delete selected');

      expect(find.text('Select bundles'), findsOneWidget);
      expect(isDisabled(tester, Icons.delete_outline), true);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('undo brings them all back in their places', (tester) async {
      await openBundles(tester, ['A', 'B', 'C', 'D']);
      await enterEditMode(tester);
      await check(tester, 0);
      await check(tester, 2);
      await tapTooltip(tester, 'Delete selected');
      expect(shownOrder(tester, ['A', 'B', 'C', 'D']), ['B', 'D']);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(shownOrder(tester, ['A', 'B', 'C', 'D']), ['A', 'B', 'C', 'D']);
      expect(await savedNames(), ['A', 'B', 'C', 'D']);
    });

    testWidgets('deleting everything shows the empty message, undo restores', (
      tester,
    ) async {
      await openBundles(tester, ['A', 'B']);
      await enterEditMode(tester);
      await tapTooltip(tester, 'Select all');
      await tapTooltip(tester, 'Delete selected');
      expect(find.textContaining('No bundles yet'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(shownOrder(tester, ['A', 'B']), ['A', 'B']);
    });
  });

  group('Reordering in edit mode', () {
    testWidgets('a handle drags a bundle to a new place', (tester) async {
      await openBundles(tester, ['A', 'B', 'C']);
      await enterEditMode(tester);

      await dragBy(
        tester,
        tester.getCenter(find.byIcon(Icons.drag_handle).first),
        80,
      );

      expect(shownOrder(tester, ['A', 'B', 'C']), ['B', 'A', 'C']);
      expect(await savedNames(), ['B', 'A', 'C']);
    });

    testWidgets('holding a bundle and dragging it moves it', (tester) async {
      await openBundles(tester, ['A', 'B', 'C']);
      await enterEditMode(tester);

      await dragBy(
        tester,
        tester.getCenter(find.text('C')),
        -80,
        hold: true,
      );

      expect(shownOrder(tester, ['A', 'B', 'C']), ['A', 'C', 'B']);
      expect(await savedNames(), ['A', 'C', 'B']);
    });

    testWidgets('the selection follows the bundle that was moved', (
      tester,
    ) async {
      await openBundles(tester, ['A', 'B', 'C']);
      await enterEditMode(tester);
      await check(tester, 0);

      await dragBy(
        tester,
        tester.getCenter(find.byIcon(Icons.drag_handle).first),
        80,
      );

      expect(find.text('1 selected'), findsOneWidget);
      expect(
        tester.widgetList<Checkbox>(find.byType(Checkbox)).map((c) => c.value),
        [false, true, false],
      );
    });
  });
}
