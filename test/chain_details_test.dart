import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/chain_card.dart';
import 'package:multitimer/chain_model.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/notification_service.dart';
import 'package:multitimer/timer_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotificationService extends NotificationService {
  final Map<int, String> scheduled = {};

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
    String body = 'Time is up',
  }) async {
    scheduled[id] = '$title | $body';
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

  late ChainModel dinner;

  // Pasta starts Sauce by itself, Sauce waits for Continue before Bread.
  ChainModel newDinner({
    List<String> steps = const ['Pasta', 'Sauce', 'Bread'],
    int currentIndex = 0,
    bool isRunning = false,
    DateTime? endTime,
  }) => dinner = ChainModel(
    name: 'Dinner',
    steps: [
      for (var i = 0; i < steps.length; i++)
        ChainStep(title: steps[i], seconds: 600 + 300 * i, startsNext: i == 0),
    ],
    currentIndex: currentIndex,
    isRunning: isRunning,
    endTime: endTime,
  );

  DateTime fromNow(int seconds) =>
      DateTime.now().add(Duration(seconds: seconds));

  Finder field(String label) => find.widgetWithText(TextField, label);

  String textIn(WidgetTester tester, Finder finder) =>
      tester.widget<TextField>(finder).controller!.text;

  Future<void> openWith(WidgetTester tester, ChainModel chain) async {
    SharedPreferences.setMockInitialValues({
      'saved_timers': jsonEncode([chain.toMap()]),
    });
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
    await tester.pumpAndSettle();
  }

  Future<void> openDetails(WidgetTester tester, ChainModel chain) async {
    await openWith(tester, chain);
    await tester.tap(find.byTooltip('Chain details'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> savedItem() async {
    final prefs = await SharedPreferences.getInstance();
    return (jsonDecode(prefs.getString('saved_timers')!) as List).single
        as Map<String, dynamic>;
  }

  List<String> savedSteps(Map<String, dynamic> chain) => [
    for (final step in (chain['steps'] as List).cast<Map<String, dynamic>>())
      step['title'] as String,
  ];

  Future<void> stopTicking(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  group('The details button', () {
    testWidgets('is on a ready chain card', (tester) async {
      await openWith(tester, newDinner());

      expect(find.byTooltip('Chain details'), findsOneWidget);
    });

    testWidgets('is on a waiting chain card', (tester) async {
      await openWith(
        tester,
        newDinner(currentIndex: 1, isRunning: true, endTime: fromNow(-5)),
      );

      expect(find.text('Sauce finished'), findsOneWidget);
      expect(find.byTooltip('Chain details'), findsOneWidget);
      await stopTicking(tester);
    });

    testWidgets('is on a complete chain card', (tester) async {
      await openWith(
        tester,
        newDinner(currentIndex: 2, isRunning: true, endTime: fromNow(-5)),
      );

      expect(find.text('Dinner complete'), findsOneWidget);
      expect(find.byTooltip('Chain details'), findsOneWidget);
      await stopTicking(tester);
    });

    testWidgets('opens the chain with its name, steps, times and links', (
      tester,
    ) async {
      await openDetails(tester, newDinner());

      expect(find.text('Edit Chain'), findsOneWidget);
      expect(textIn(tester, field('Chain name')), 'Dinner');
      expect(
        tester
            .widgetList<TextField>(field('Timer name'))
            .map((f) => f.controller!.text),
        ['Pasta', 'Sauce', 'Bread'],
      );
      expect(textIn(tester, field('MM').at(1)), '15');
      expect(
        tester.widgetList<Switch>(find.byType(Switch)).map((s) => s.value),
        [true, false],
      );
    });

    testWidgets('marks done steps and the current one', (tester) async {
      await openDetails(
        tester,
        newDinner(currentIndex: 1, isRunning: true, endTime: fromNow(300)),
      );

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Done')).dy,
        lessThan(tester.getTopLeft(find.text('Now')).dy),
      );
      await stopTicking(tester);
    });

    testWidgets('a bundle editor has no such marks', (tester) async {
      await openDetails(tester, newDinner());
      expect(find.text('Now'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bundles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New bundle'));
      await tester.pumpAndSettle();

      expect(find.text('New Bundle'), findsOneWidget);
      expect(find.text('Now'), findsNothing);
      expect(find.text('Done'), findsNothing);
    });
  });

  group('Leaving without saving', () {
    testWidgets('does not ask when nothing changed', (tester) async {
      await openDetails(tester, newDinner());

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit Chain'), findsNothing);
    });

    testWidgets('asks after a change, and Discard keeps the chain as it was', (
      tester,
    ) async {
      await openDetails(tester, newDinner());
      await tester.enterText(field('Chain name'), 'Supper');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Dinner · step 1 of 3'), findsOneWidget);
    });
  });

  group('Saving', () {
    testWidgets('a new name shows on the card and is saved', (tester) async {
      await openDetails(tester, newDinner());

      await tester.enterText(field('Chain name'), 'Supper');
      await save(tester);

      expect(find.text('Supper · step 1 of 3'), findsOneWidget);
      expect((await savedItem())['name'], 'Supper');
    });

    testWidgets('an empty name is refused', (tester) async {
      await openDetails(tester, newDinner());

      await tester.enterText(field('Chain name'), '');
      await save(tester);

      expect(find.text('Please enter a chain name.'), findsOneWidget);
      expect(find.text('Edit Chain'), findsOneWidget);
    });

    testWidgets('added and removed steps, times and links are saved', (
      tester,
    ) async {
      await openDetails(tester, newDinner());

      await tester.tap(find.byTooltip('Remove timer').at(2));
      await tester.pump();
      await tester.tap(find.text('Add timer'));
      await tester.pump();
      await tester.enterText(field('Timer name').last, 'Salad');
      await tester.enterText(field('MM').last, '05');
      await tester.enterText(field('MM').at(1), '20');
      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();
      await save(tester);

      expect(find.text('Dinner · step 1 of 3'), findsOneWidget);
      final saved = await savedItem();
      final steps = (saved['steps'] as List).cast<Map<String, dynamic>>();
      expect(steps.map((s) => s['title']), ['Pasta', 'Sauce', 'Salad']);
      expect(steps.map((s) => s['seconds']), [600, 1200, 300]);
      expect(steps.map((s) => s['startsNext']), [true, true, false]);
    });

    testWidgets('renaming the running step keeps it running, with new alert '
        'texts', (tester) async {
      await openDetails(
        tester,
        newDinner(currentIndex: 1, isRunning: true, endTime: fromNow(300)),
      );

      await tester.enterText(field('Timer name').at(1), 'Gravy');
      await save(tester);

      expect(find.text('Gravy'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(fake.scheduled, {
        dinner.steps[1].id:
            'Gravy finished | Dinner: tap Continue to start '
            'Bread',
      });
      await stopTicking(tester);
    });

    testWidgets('changing the running step time stops and resets it', (
      tester,
    ) async {
      await openDetails(
        tester,
        newDinner(currentIndex: 1, isRunning: true, endTime: fromNow(300)),
      );

      await tester.enterText(field('MM').at(1), '20');
      await save(tester);

      expect(find.text('Sauce'), findsOneWidget);
      expect(find.text('00:20:00'), findsOneWidget);
      expect(find.byTooltip('Start'), findsOneWidget);
      expect(fake.scheduled, isEmpty);
    });

    testWidgets('removing the running step makes the next one ready', (
      tester,
    ) async {
      await openDetails(
        tester,
        newDinner(currentIndex: 1, isRunning: true, endTime: fromNow(300)),
      );

      await tester.tap(find.byTooltip('Remove timer').at(1));
      await tester.pump();
      await save(tester);

      expect(find.text('Dinner · step 2 of 2'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.byTooltip('Start'), findsOneWidget);
      expect(fake.scheduled, isEmpty);
      expect(savedSteps(await savedItem()), ['Pasta', 'Bread']);
    });

    testWidgets('down to one step it becomes a plain timer card', (
      tester,
    ) async {
      await openDetails(tester, newDinner());

      await tester.tap(find.byTooltip('Remove timer').at(2));
      await tester.pump();
      await tester.tap(find.byTooltip('Remove timer').at(1));
      await tester.pump();
      await save(tester);

      expect(find.byType(ChainCard), findsNothing);
      expect(find.byType(TimerCard), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('00:10:00'), findsOneWidget);
      final saved = await savedItem();
      expect(saved['type'], isNot('chain'));
      expect(saved['title'], 'Pasta');
    });

    testWidgets('a running step left alone keeps running as a plain timer', (
      tester,
    ) async {
      await openDetails(
        tester,
        newDinner(currentIndex: 1, isRunning: true, endTime: fromNow(300)),
      );

      await tester.tap(find.byTooltip('Remove timer').at(2));
      await tester.pump();
      await tester.tap(find.byTooltip('Remove timer').at(0));
      await tester.pump();
      await save(tester);

      expect(find.byType(TimerCard), findsOneWidget);
      expect(find.text('Sauce'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      final saved = await savedItem();
      expect(saved['isRunning'], true);
      expect(saved['initialSeconds'], 900);
      expect(fake.scheduled, {saved['id']: 'Sauce | Time is up'});
      await stopTicking(tester);
    });
  });
}
