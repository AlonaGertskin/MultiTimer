import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/chain_model.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/notification_service.dart';
import 'package:multitimer/timer_model.dart';
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

  // Pasta starts Sauce by itself, Sauce waits for Continue before Bread.
  late ChainModel dinner;

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

  int stepId(int index) => dinner.steps[index].id;

  DateTime fromNow(int seconds) =>
      DateTime.now().add(Duration(seconds: seconds));

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

  Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  Future<void> stopTicking(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('starting a chain schedules its alerts up to the manual link', (
    tester,
  ) async {
    await openWith(tester, [newDinner()]);

    await tapTooltip(tester, 'Start');

    expect(fake.scheduled, {
      stepId(0): 'Pasta finished | Dinner: Sauce started',
      stepId(1): 'Sauce finished | Dinner: tap Continue to start Bread',
    });
    await stopTicking(tester);
  });

  testWidgets('pausing cancels them all', (tester) async {
    await openWith(tester, [newDinner()]);
    await tapTooltip(tester, 'Start');

    await tapTooltip(tester, 'Pause');

    expect(fake.scheduled, isEmpty);
  });

  testWidgets('reset step cancels them all', (tester) async {
    await openWith(tester, [newDinner(isRunning: true, endTime: fromNow(300))]);

    await tapTooltip(tester, 'Reset step');

    expect(fake.scheduled, isEmpty);
  });

  testWidgets('skip after an automatic link schedules from the next step', (
    tester,
  ) async {
    await openWith(tester, [newDinner(isRunning: true, endTime: fromNow(300))]);

    await tapTooltip(tester, 'Skip step');

    expect(fake.scheduled, {
      stepId(1): 'Sauce finished | Dinner: tap Continue to start Bread',
    });
    await stopTicking(tester);
  });

  testWidgets('Continue schedules the alert for the step it starts', (
    tester,
  ) async {
    await openWith(tester, [
      newDinner(currentIndex: 1, isRunning: true, endTime: fromNow(-5)),
    ]);
    expect(fake.scheduled, isEmpty);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(fake.scheduled, {stepId(2): 'Dinner complete | Bread finished'});
    await stopTicking(tester);
  });

  testWidgets('Restart chain cancels them all', (tester) async {
    await openWith(tester, [
      newDinner(currentIndex: 2, isRunning: true, endTime: fromNow(-5)),
    ]);

    await tester.tap(find.text('Restart chain'));
    await tester.pumpAndSettle();

    expect(fake.scheduled, isEmpty);
  });

  testWidgets('a running chain gets its alerts again when the app opens', (
    tester,
  ) async {
    await openWith(tester, [newDinner(isRunning: true, endTime: fromNow(300))]);

    expect(fake.scheduled.keys, [stepId(0), stepId(1)]);
    await stopTicking(tester);
  });

  testWidgets('deleting a chain cancels its alerts and Undo brings them back', (
    tester,
  ) async {
    await openWith(tester, [newDinner(isRunning: true, endTime: fromNow(300))]);

    await tester.drag(find.textContaining('Dinner ·'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(fake.scheduled, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(fake.scheduled.keys, [stepId(0), stepId(1)]);
    await stopTicking(tester);
  });

  testWidgets('a plain timer alert still says Time is up', (tester) async {
    final tea = TimerModel(title: 'Tea', remainingSeconds: 60);
    await openWith(tester, [tea]);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(fake.scheduled, {tea.id: 'Tea | Time is up'});
    await stopTicking(tester);
  });
}
