import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/home_page.dart';
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
  late FakeNotificationService fake;

  setUp(() {
    fake = FakeNotificationService();
    NotificationService.instance = fake;
  });

  tearDown(() => NotificationService.instance = NotificationService());

  TimerModel plain(String title, int seconds) =>
      TimerModel(title: title, remainingSeconds: seconds);

  TimerModel running(String title, int seconds) => TimerModel(
    title: title,
    remainingSeconds: seconds,
    isRunning: true,
    endTime: DateTime.now().add(Duration(seconds: seconds)),
  );

  void saveTimers(List<TimerModel> timers) {
    SharedPreferences.setMockInitialValues({
      'saved_timers': jsonEncode(timers.map((t) => t.toMap()).toList()),
    });
  }

  Future<void> openMain(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
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

  bool isDisabled(WidgetTester tester, String tooltip) =>
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, _icon(tooltip)))
          .onPressed ==
      null;

  Future<List<String>> savedTitles() async {
    final prefs = await SharedPreferences.getInstance();
    return TimerModel.listFromJson(
      prefs.getString('saved_timers')!,
    ).map((t) => t.title).toList();
  }

  List<String> shownOrder(WidgetTester tester, List<String> titles) {
    final found = titles
        .where((t) => find.text(t).evaluate().isNotEmpty)
        .toList();
    found.sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );
    return found;
  }

  group('Edit mode', () {
    testWidgets('the button shows handles and checkboxes on every card', (
      tester,
    ) async {
      saveTimers([plain('A', 60), plain('B', 120), plain('C', 180)]);
      await openMain(tester);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing);

      await enterEditMode(tester);

      expect(find.byType(Checkbox), findsNWidgets(3));
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
    });

    testWidgets('Done hides them again', (tester) async {
      saveTimers([plain('A', 60)]);
      await openMain(tester);
      await enterEditMode(tester);

      await tapTooltip(tester, 'Done');

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
      expect(find.text('Multi-Timer'), findsOneWidget);
    });

    testWidgets('the add button is hidden in edit mode', (tester) async {
      saveTimers([plain('A', 60)]);
      await openMain(tester);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await enterEditMode(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('the top bar counts what is selected', (tester) async {
      saveTimers([plain('A', 60), plain('B', 120), plain('C', 180)]);
      await openMain(tester);

      await enterEditMode(tester);
      expect(find.text('Select timers'), findsOneWidget);

      await check(tester, 0);
      expect(find.text('1 selected'), findsOneWidget);

      await check(tester, 2);
      expect(find.text('2 selected'), findsOneWidget);

      await check(tester, 0);
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('select all selects everything, and again clears it', (
      tester,
    ) async {
      saveTimers([plain('A', 60), plain('B', 120), plain('C', 180)]);
      await openMain(tester);
      await enterEditMode(tester);

      await tapTooltip(tester, 'Select all');
      expect(find.text('3 selected'), findsOneWidget);

      await tapTooltip(tester, 'Select all');
      expect(find.text('Select timers'), findsOneWidget);
    });

    testWidgets('select all finishes a partial selection', (tester) async {
      saveTimers([plain('A', 60), plain('B', 120)]);
      await openMain(tester);
      await enterEditMode(tester);
      await check(tester, 0);

      await tapTooltip(tester, 'Select all');

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('leaving edit mode forgets the selection', (tester) async {
      saveTimers([plain('A', 60), plain('B', 120)]);
      await openMain(tester);
      await enterEditMode(tester);
      await check(tester, 0);

      await tapTooltip(tester, 'Done');
      await enterEditMode(tester);

      expect(find.text('Select timers'), findsOneWidget);
      expect(
        tester.widgetList<Checkbox>(find.byType(Checkbox)).map((c) => c.value),
        [false, false],
      );
    });

    testWidgets('swiping does nothing in edit mode', (tester) async {
      saveTimers([plain('A', 60)]);
      await openMain(tester);
      await enterEditMode(tester);
      final before = tester.getTopLeft(find.text('A'));

      await tester.drag(find.text('A'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('A')), before);
    });
  });

  group('Delete selected', () {
    testWidgets('is disabled while nothing is selected', (tester) async {
      saveTimers([plain('A', 60)]);
      await openMain(tester);
      await enterEditMode(tester);

      expect(isDisabled(tester, 'Delete selected'), true);

      await check(tester, 0);

      expect(isDisabled(tester, 'Delete selected'), false);
    });

    testWidgets('deletes every selected timer and shows one Undo message', (
      tester,
    ) async {
      saveTimers([plain('A', 60), plain('B', 120), plain('C', 180)]);
      await openMain(tester);
      await enterEditMode(tester);
      await check(tester, 0);
      await check(tester, 2);

      await tapTooltip(tester, 'Delete selected');

      expect(find.text('A'), findsNothing);
      expect(find.text('C'), findsNothing);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('2 timers deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(await savedTitles(), ['B']);
    });

    testWidgets('one selected timer says its name', (tester) async {
      saveTimers([plain('A', 60), plain('B', 120)]);
      await openMain(tester);
      await enterEditMode(tester);
      await check(tester, 1);

      await tapTooltip(tester, 'Delete selected');

      expect(find.text('B deleted'), findsOneWidget);
    });

    testWidgets('stays in edit mode with nothing selected afterwards', (
      tester,
    ) async {
      saveTimers([plain('A', 60), plain('B', 120)]);
      await openMain(tester);
      await enterEditMode(tester);
      await check(tester, 0);

      await tapTooltip(tester, 'Delete selected');

      expect(find.text('Select timers'), findsOneWidget);
      expect(isDisabled(tester, 'Delete selected'), true);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('undo brings them all back in their places', (tester) async {
      saveTimers([
        plain('A', 60),
        plain('B', 120),
        plain('C', 180),
        plain('D', 240),
      ]);
      await openMain(tester);
      await enterEditMode(tester);
      await check(tester, 0);
      await check(tester, 2);
      await tapTooltip(tester, 'Delete selected');
      expect(shownOrder(tester, ['A', 'B', 'C', 'D']), ['B', 'D']);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(shownOrder(tester, ['A', 'B', 'C', 'D']), ['A', 'B', 'C', 'D']);
      expect(await savedTitles(), ['A', 'B', 'C', 'D']);
    });

    testWidgets('deleting everything and undoing brings everything back', (
      tester,
    ) async {
      saveTimers([plain('A', 60), plain('B', 120)]);
      await openMain(tester);
      await enterEditMode(tester);
      await tapTooltip(tester, 'Select all');
      await tapTooltip(tester, 'Delete selected');
      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(shownOrder(tester, ['A', 'B']), ['A', 'B']);
    });

    testWidgets('running timers lose their alerts and get them back on undo', (
      tester,
    ) async {
      final pasta = running('Pasta', 600);
      final tea = plain('Tea', 60);
      saveTimers([pasta, tea]);
      await openMain(tester);
      expect(fake.scheduled.containsKey(pasta.id), true);
      await enterEditMode(tester);
      await tapTooltip(tester, 'Select all');

      await tapTooltip(tester, 'Delete selected');
      expect(fake.scheduled.containsKey(pasta.id), false);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(fake.scheduled.containsKey(pasta.id), true);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Reordering in edit mode', () {
    testWidgets('a handle drags a timer to a new place', (tester) async {
      saveTimers([plain('A', 60), plain('B', 120), plain('C', 180)]);
      await openMain(tester);
      await enterEditMode(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_handle).first),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 16));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(shownOrder(tester, ['A', 'B', 'C']), ['B', 'A', 'C']);
      expect(await savedTitles(), ['B', 'A', 'C']);
    });

    testWidgets('the selection follows the timer that was moved', (
      tester,
    ) async {
      saveTimers([plain('A', 60), plain('B', 120), plain('C', 180)]);
      await openMain(tester);
      await enterEditMode(tester);
      await check(tester, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_handle).first),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 16));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(
        tester.widgetList<Checkbox>(find.byType(Checkbox)).map((c) => c.value),
        [false, true, false],
      );
    });
  });
}

IconData _icon(String tooltip) => switch (tooltip) {
  'Delete selected' => Icons.delete_outline,
  'Select all' => Icons.select_all,
  'Done' => Icons.check,
  _ => throw ArgumentError(tooltip),
};
