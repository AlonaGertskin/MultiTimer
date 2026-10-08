import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/chain_model.dart';
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

  late ChainModel dinner;

  // Pasta starts Sauce by itself, Sauce waits for Continue before Bread.
  ChainModel newDinner({
    int currentIndex = 0,
    bool isRunning = false,
    DateTime? endTime,
  }) => dinner = ChainModel(
    name: 'Dinner',
    steps: [
      ChainStep(title: 'Pasta', seconds: 600, startsNext: true),
      ChainStep(title: 'Sauce', seconds: 900),
      ChainStep(title: 'Bread', seconds: 1200),
    ],
    currentIndex: currentIndex,
    isRunning: isRunning,
    endTime: endTime,
  );

  DateTime fromNow(int seconds) =>
      DateTime.now().add(Duration(seconds: seconds));

  final chainCard = find.textContaining('Dinner ·');
  final restartButton = find.byIcon(Icons.restart_alt);

  Future<void> openWith(WidgetTester tester, List<Object> items) async {
    SharedPreferences.setMockInitialValues({
      'saved_timers': jsonEncode([
        for (final item in items)
          item is ChainModel ? item.toMap() : (item as TimerModel).toMap(),
      ]),
    });
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> savedChain() async {
    final prefs = await SharedPreferences.getInstance();
    return (jsonDecode(prefs.getString('saved_timers')!) as List).single
        as Map<String, dynamic>;
  }

  Future<void> swipeRight(WidgetTester tester, Finder card) async {
    await tester.drag(card, const Offset(300, 0));
    await tester.pumpAndSettle();
  }

  Future<void> swipeAndRestart(WidgetTester tester) async {
    await swipeRight(tester, chainCard);
    await tester.tap(restartButton);
    await tester.pumpAndSettle();
  }

  Future<void> stopTicking(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('swiping a chain card right reveals a restart button', (
    tester,
  ) async {
    await openWith(tester, [newDinner(currentIndex: 1)]);
    expect(restartButton, findsNothing);

    await swipeRight(tester, chainCard);

    expect(restartButton, findsOneWidget);
  });

  testWidgets('the restart button puts the chain back to a ready first step', (
    tester,
  ) async {
    await openWith(tester, [
      newDinner(currentIndex: 1, isRunning: true, endTime: fromNow(300)),
    ]);
    expect(fake.scheduled, isNotEmpty);

    await swipeAndRestart(tester);

    expect(find.text('Dinner · step 1 of 3'), findsOneWidget);
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('00:10:00'), findsOneWidget);
    expect(find.byTooltip('Start'), findsOneWidget);
    expect(fake.scheduled, isEmpty);
    expect(find.text('Dinner restarted'), findsOneWidget);
    final saved = await savedChain();
    expect(saved['currentIndex'], 0);
    expect(saved['isRunning'], false);
  });

  testWidgets('undo brings back the step, its time, running and alerts', (
    tester,
  ) async {
    final end = fromNow(300);
    await openWith(tester, [
      newDinner(currentIndex: 1, isRunning: true, endTime: end),
    ]);
    await swipeAndRestart(tester);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Dinner · step 2 of 3'), findsOneWidget);
    expect(find.text('Sauce'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(fake.scheduled.keys, [dinner.steps[1].id]);
    final saved = await savedChain();
    expect(saved['currentIndex'], 1);
    expect(saved['isRunning'], true);
    expect(DateTime.parse(saved['endTime'] as String), end);
    await stopTicking(tester);
  });

  testWidgets('a complete chain can be restarted by swiping too', (
    tester,
  ) async {
    await openWith(tester, [
      newDinner(currentIndex: 2, isRunning: true, endTime: fromNow(-5)),
    ]);

    await swipeRight(tester, find.text('Dinner complete'));
    await tester.tap(restartButton);
    await tester.pumpAndSettle();

    expect(find.text('Dinner · step 1 of 3'), findsOneWidget);
  });

  testWidgets('swiping a plain timer right reveals nothing', (tester) async {
    await openWith(tester, [TimerModel(title: 'Tea', remainingSeconds: 60)]);
    final before = tester.getTopLeft(find.text('Tea'));

    await swipeRight(tester, find.text('Tea'));

    expect(restartButton, findsNothing);
    expect(tester.getTopLeft(find.text('Tea')), before);
  });

  testWidgets('swiping right does nothing in edit mode', (tester) async {
    await openWith(tester, [newDinner()]);
    await tester.tap(find.byTooltip('Edit list'));
    await tester.pumpAndSettle();

    await swipeRight(tester, chainCard);

    expect(restartButton, findsNothing);
  });

  testWidgets('swiping left still offers the trash', (tester) async {
    await openWith(tester, [newDinner()]);

    await tester.drag(chainCard, const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(restartButton, findsNothing);
  });
}
