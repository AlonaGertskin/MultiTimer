import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/chain_model.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/list_item.dart';
import 'package:multitimer/notification_service.dart';
import 'package:multitimer/timer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotificationService extends NotificationService {
  final Map<int, DateTime> scheduled = {};

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
    String body = 'Time is up',
  }) async {
    scheduled[id] = when;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
  }
}

void main() {
  setUp(() => NotificationService.instance = FakeNotificationService());

  tearDown(() => NotificationService.instance = NotificationService());

  TimerModel timer(String title, int seconds) =>
      TimerModel(title: title, remainingSeconds: seconds);

  ChainModel chain(
    String name, {
    List<String> steps = const ['Pasta', 'Sauce'],
  }) => ChainModel(
    name: name,
    steps: [for (final step in steps) ChainStep(title: step, seconds: 60)],
  );

  void saveItems(List<Map<String, dynamic>> maps) {
    SharedPreferences.setMockInitialValues({'saved_timers': jsonEncode(maps)});
  }

  Future<List<String>> savedNames() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('saved_timers')!) as List;
    return [
      for (final map in saved.cast<Map<String, dynamic>>())
        (map['name'] ?? map['title']) as String,
    ];
  }

  Future<void> openMain(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
    await tester.pumpAndSettle();
  }

  List<String> shownOrder(WidgetTester tester, List<String> names) {
    final found = names
        .where((n) => find.textContaining(n).evaluate().isNotEmpty)
        .toList();
    found.sort(
      (a, b) => tester
          .getTopLeft(find.textContaining(a))
          .dy
          .compareTo(tester.getTopLeft(find.textContaining(b)).dy),
    );
    return found;
  }

  group('Reading a saved list', () {
    test('timers and chains load in their saved order', () {
      final json = jsonEncode([
        timer('Tea', 60).toMap(),
        chain('Dinner').toMap(),
        timer('Eggs', 300).toMap(),
      ]);

      final items = ListItem.listFromJson(json);

      expect(items.map((i) => i.runtimeType), [
        TimerModel,
        ChainModel,
        TimerModel,
      ]);
    });

    test('an old timer without a type still loads as a timer', () {
      final map = timer('Tea', 60).toMap()..remove('type');

      final items = ListItem.listFromJson(jsonEncode([map]));

      expect((items.single as TimerModel).title, 'Tea');
    });

    test('a bad chain is skipped and the rest are kept', () {
      final bad = chain('Broken').toMap()..['steps'] = [];
      final json = jsonEncode([
        timer('Tea', 60).toMap(),
        bad,
        chain('Dinner').toMap(),
      ]);

      final items = ListItem.listFromJson(json);

      expect(items.length, 2);
      expect((items.last as ChainModel).name, 'Dinner');
    });

    test('unreadable data gives an empty list', () {
      expect(ListItem.listFromJson('not json'), isEmpty);
    });
  });

  group('A chain on the main screen', () {
    testWidgets('shows its name, its current step and where it is', (
      tester,
    ) async {
      saveItems([chain('Dinner').toMap()]);
      await openMain(tester);

      expect(find.text('Dinner · step 1 of 2'), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('00:01:00'), findsOneWidget);
    });

    testWidgets('timers and chains show in their saved order', (tester) async {
      saveItems([
        timer('Tea', 60).toMap(),
        chain('Dinner').toMap(),
        timer('Eggs', 300).toMap(),
      ]);
      await openMain(tester);

      expect(shownOrder(tester, ['Tea', 'Dinner', 'Eggs']), [
        'Tea',
        'Dinner',
        'Eggs',
      ]);
    });

    testWidgets('a running chain catches up on the time it spent closed', (
      tester,
    ) async {
      final dinner = ChainModel(
        name: 'Dinner',
        steps: [
          ChainStep(title: 'Pasta', seconds: 60, startsNext: true),
          ChainStep(title: 'Sauce', seconds: 600),
        ],
        isRunning: true,
        endTime: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      saveItems([dinner.toMap()]);
      await openMain(tester);

      expect(find.text('Dinner · step 2 of 2'), findsOneWidget);
      expect(find.text('Sauce'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('adding a timer keeps the chain in the saved list', (
      tester,
    ) async {
      saveItems([chain('Dinner').toMap()]);
      await openMain(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Timer Title'),
        'Tea',
      );
      await tester.enterText(find.widgetWithText(TextField, 'MM'), '05');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(await savedNames(), ['Dinner', 'Tea']);
      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString('saved_timers')!) as List;
      expect(saved.first['type'], 'chain');
    });
  });

  group('Chains in edit mode', () {
    testWidgets('a chain gets a checkbox and a handle too', (tester) async {
      saveItems([timer('Tea', 60).toMap(), chain('Dinner').toMap()]);
      await openMain(tester);

      await tester.tap(find.byTooltip('Edit list'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
    });

    testWidgets('a chain can be dragged to a new place', (tester) async {
      saveItems([
        chain('Dinner').toMap(),
        timer('Tea', 60).toMap(),
        timer('Eggs', 300).toMap(),
      ]);
      await openMain(tester);
      await tester.tap(find.byTooltip('Edit list'));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_handle).first),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 16));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(shownOrder(tester, ['Dinner', 'Tea', 'Eggs']), [
        'Tea',
        'Dinner',
        'Eggs',
      ]);
      expect(await savedNames(), ['Tea', 'Dinner', 'Eggs']);
    });

    testWidgets('select all and delete removes chains and timers, undo '
        'brings them back', (tester) async {
      saveItems([
        timer('Tea', 60).toMap(),
        chain('Dinner').toMap(),
        timer('Eggs', 300).toMap(),
      ]);
      await openMain(tester);
      await tester.tap(find.byTooltip('Edit list'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pump();

      await tester.tap(find.byTooltip('Delete selected'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dinner ·'), findsNothing);
      expect(await savedNames(), ['Tea']);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(shownOrder(tester, ['Tea', 'Dinner', 'Eggs']), [
        'Tea',
        'Dinner',
        'Eggs',
      ]);
      expect(await savedNames(), ['Tea', 'Dinner', 'Eggs']);
    });
  });

  group('Swiping a chain away', () {
    testWidgets('deletes it with an Undo that puts it back', (tester) async {
      saveItems([timer('Tea', 60).toMap(), chain('Dinner').toMap()]);
      await openMain(tester);

      await tester.drag(find.textContaining('Dinner'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dinner ·'), findsNothing);
      expect(find.text('Dinner deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(shownOrder(tester, ['Tea', 'Dinner']), ['Tea', 'Dinner']);
    });

    testWidgets('a running chain comes back running with the same end', (
      tester,
    ) async {
      final end = DateTime.now().add(const Duration(seconds: 50));
      final dinner = ChainModel(
        name: 'Dinner',
        steps: [
          ChainStep(title: 'Pasta', seconds: 60),
          ChainStep(title: 'Sauce', seconds: 60),
        ],
        isRunning: true,
        endTime: end,
      );
      saveItems([dinner.toMap()]);
      await openMain(tester);

      await tester.drag(find.textContaining('Dinner'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final saved =
          (jsonDecode(prefs.getString('saved_timers')!) as List).single
              as Map<String, dynamic>;
      expect(saved['isRunning'], true);
      expect(DateTime.parse(saved['endTime'] as String), end);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
