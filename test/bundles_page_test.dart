import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_store.dart';
import 'package:multitimer/bundles_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openBundles(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester) async {
    await openBundles(tester);
    await tester.tap(find.text('New bundle'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> fillRow(
    WidgetTester tester,
    int index,
    String name, {
    String hours = '',
    String minutes = '',
    String seconds = '',
  }) async {
    await tester.enterText(field('Timer name').at(index), name);
    if (hours.isNotEmpty) await tester.enterText(field('HH').at(index), hours);
    if (minutes.isNotEmpty) {
      await tester.enterText(field('MM').at(index), minutes);
    }
    if (seconds.isNotEmpty) {
      await tester.enterText(field('SS').at(index), seconds);
    }
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  group('Bundles screen', () {
    testWidgets('shows a message when there are no bundles', (tester) async {
      await openBundles(tester);

      expect(find.textContaining('No bundles yet'), findsOneWidget);
    });

    testWidgets('lists a saved bundle with a summary', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await fillRow(tester, 0, 'Pasta', minutes: '10');
      await tester.tap(find.text('Add timer'));
      await tester.pump();
      await fillRow(tester, 1, 'Sauce', minutes: '15');
      await save(tester);

      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('2 timers · 25:00 total'), findsOneWidget);
      expect(find.textContaining('No bundles yet'), findsNothing);
    });

    testWidgets('a created bundle is saved on the phone', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Workout');
      await fillRow(tester, 0, 'Warm-up', minutes: '5');
      await save(tester);

      final saved = await BundleStore().load();

      expect(saved.map((b) => b.name), ['Workout']);
      expect(saved.first.items.first.title, 'Warm-up');
      expect(saved.first.items.first.seconds, 300);
    });

    testWidgets('a one-timer bundle says "1 timer"', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Tea');
      await fillRow(tester, 0, 'Steep', minutes: '3');
      await save(tester);

      expect(find.text('1 timer · 3:00 total'), findsOneWidget);
    });
  });

  group('Bundle editor reordering', () {
    Future<void> prepareThreeTimers(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await fillRow(tester, 0, 'First', minutes: '1');
      for (final entry in {1: ['Second', '2'], 2: ['Third', '3']}.entries) {
        await tester.tap(find.text('Add timer'));
        await tester.pump();
        await fillRow(tester, entry.key, entry.value[0], minutes: entry.value[1]);
      }
    }

    List<String> shownOrder(WidgetTester tester) {
      final names = ['First', 'Second', 'Third'];
      names.sort((a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy));
      return names;
    }

    Future<void> dragCard(WidgetTester tester, int index, double distance) async {
      final start =
          tester.getTopLeft(find.byType(Card).at(index)) + const Offset(12, 8);
      final gesture = await tester.startGesture(start);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, distance / 10));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('holding a timer and dragging it down moves it',
        (tester) async {
      await prepareThreeTimers(tester);

      await dragCard(tester, 0, 200);

      expect(shownOrder(tester), ['Second', 'First', 'Third']);
    });

    testWidgets('holding a timer and dragging it up moves it', (tester) async {
      await prepareThreeTimers(tester);

      await dragCard(tester, 2, -200);

      expect(shownOrder(tester), ['First', 'Third', 'Second']);
    });

    testWidgets('every timer has a drag handle', (tester) async {
      await prepareThreeTimers(tester);

      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
    });

    testWidgets('a handle drags right away, without holding', (tester) async {
      await prepareThreeTimers(tester);

      final gesture = await tester
          .startGesture(tester.getCenter(find.byIcon(Icons.drag_handle).first));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(shownOrder(tester), ['Second', 'First', 'Third']);
    });

    testWidgets('the saved bundle follows the new order, with each time',
        (tester) async {
      await prepareThreeTimers(tester);
      await dragCard(tester, 0, 200);

      await save(tester);
      final saved = (await BundleStore().load()).first.items;

      expect(saved.map((i) => i.title), ['Second', 'First', 'Third']);
      expect(saved.map((i) => i.seconds), [120, 60, 180]);
    });
  });

  group('Bundle editor text fields', () {
    testWidgets('names start with a capital letter automatically',
        (tester) async {
      await openEditor(tester);

      expect(tester.widget<TextField>(field('Bundle name')).textCapitalization,
          TextCapitalization.sentences);
      expect(
          tester.widget<TextField>(field('Timer name')).textCapitalization,
          TextCapitalization.sentences);
    });

    testWidgets('the next key goes from the bundle name to the first timer',
        (tester) async {
      await openEditor(tester);

      await tester.enterText(field('Bundle name'), 'Dinner');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      tester.testTextInput.enterText('Pasta');
      await tester.pump();

      expect(tester.widget<TextField>(field('Timer name')).controller!.text,
          'Pasta');
    });

    testWidgets('the next key on a timer name moves to its hours',
        (tester) async {
      await openEditor(tester);

      await tester.enterText(field('Timer name'), 'Pasta');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      tester.testTextInput.enterText('02');
      await tester.pump();

      expect(tester.widget<TextField>(field('HH')).controller!.text, '02');
      expect(tester.widget<TextField>(field('Timer name')).controller!.text,
          'Pasta');
    });

    testWidgets('the next key on seconds moves to the next timer name',
        (tester) async {
      await openEditor(tester);
      await tester.tap(find.text('Add timer'));
      await tester.pump();

      await tester.enterText(field('SS').first, '1');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      tester.testTextInput.enterText('Sauce');
      await tester.pump();

      expect(
          tester.widget<TextField>(field('Timer name').last).controller!.text,
          'Sauce');
    });

    testWidgets('seconds show next, except in the last timer which shows done',
        (tester) async {
      await openEditor(tester);
      await tester.tap(find.text('Add timer'));
      await tester.pump();

      expect(tester.widget<TextField>(field('SS').first).textInputAction,
          TextInputAction.next);
      expect(tester.widget<TextField>(field('SS').last).textInputAction,
          TextInputAction.done);
    });
  });

  group('Bundle editor', () {
    testWidgets('asks for a bundle name', (tester) async {
      await openEditor(tester);
      await fillRow(tester, 0, 'Pasta', minutes: '10');
      await save(tester);

      expect(find.text('Please enter a bundle name.'), findsOneWidget);
    });

    testWidgets('asks for a name on every timer', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await fillRow(tester, 0, '', minutes: '10');
      await save(tester);

      expect(find.text('Every timer needs a name.'), findsOneWidget);
    });

    testWidgets('asks for a time above zero on every timer', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await fillRow(tester, 0, 'Pasta');
      await save(tester);

      expect(find.text('Every timer needs a time above zero.'), findsOneWidget);
    });

    testWidgets('asks for at least one timer', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await tester.tap(find.byTooltip('Remove timer'));
      await tester.pump();
      await save(tester);

      expect(find.text('Add at least one timer.'), findsOneWidget);
    });

    testWidgets('timers can be added and removed', (tester) async {
      await openEditor(tester);
      expect(field('Timer name'), findsOneWidget);

      await tester.tap(find.text('Add timer'));
      await tester.pump();
      await tester.tap(find.text('Add timer'));
      await tester.pump();
      expect(field('Timer name'), findsNWidgets(3));

      await tester.tap(find.byTooltip('Remove timer').first);
      await tester.pump();
      expect(field('Timer name'), findsNWidgets(2));
    });

    testWidgets('removing a timer keeps what was typed in the others',
        (tester) async {
      await openEditor(tester);
      await fillRow(tester, 0, 'First', minutes: '1');
      await tester.tap(find.text('Add timer'));
      await tester.pump();
      await fillRow(tester, 1, 'Second', minutes: '2');

      await tester.tap(find.byTooltip('Remove timer').first);
      await tester.pump();

      expect(find.text('Second'), findsOneWidget);
      expect(find.text('First'), findsNothing);
    });

    testWidgets('time fields keep their limits', (tester) async {
      await openEditor(tester);

      await tester.enterText(field('MM'), '75');
      await tester.pump();

      expect(tester.widget<TextField>(field('MM')).controller!.text, '59');
    });
  });
}
