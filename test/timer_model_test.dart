import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/timer_model.dart';

void main() {
  late DateTime fakeNow;

  setUp(() => fakeNow = DateTime(2026, 1, 1));

  TimerModel newTimer(int seconds) =>
      TimerModel(title: 'Tea', remainingSeconds: seconds, now: () => fakeNow);

  Future<void> pass(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      fakeNow = fakeNow.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
  }

  group('TimerModel', () {
    testWidgets('counts down once per second while running', (tester) async {
      final timer = newTimer(10);
      int ticks = 0;

      timer.start(() => ticks++);
      await pass(tester, 3);

      expect(timer.remainingSeconds, 7);
      expect(ticks, 3);
      expect(timer.isRunning, true);
      timer.stop();
    });

    testWidgets('keeps counting into negative time after zero',
        (tester) async {
      final timer = newTimer(2);

      timer.start(() {});
      await pass(tester, 5);

      expect(timer.remainingSeconds, -3);
      expect(timer.isRunning, true);
      timer.stop();
    });

    testWidgets('stop pauses the countdown', (tester) async {
      final timer = newTimer(10);

      timer.start(() {});
      await pass(tester, 2);
      timer.stop();
      await pass(tester, 5);

      expect(timer.remainingSeconds, 8);
      expect(timer.isRunning, false);
      expect(timer.internalTimer, isNull);
    });

    testWidgets('calling start twice does not double the speed',
        (tester) async {
      final timer = newTimer(10);

      timer.start(() {});
      timer.start(() {});
      await pass(tester, 3);

      expect(timer.remainingSeconds, 7);
      timer.stop();
    });

    testWidgets('reset stops the timer and restores the starting time',
        (tester) async {
      final timer = newTimer(10);

      timer.start(() {});
      await pass(tester, 4);
      timer.reset();

      expect(timer.remainingSeconds, 10);
      expect(timer.isRunning, false);
    });
  });

  group('TimerModel clock accuracy', () {
    testWidgets('a late tick shows the real time left, not one second less',
        (tester) async {
      final timer = newTimer(60);

      timer.start(() {});
      fakeNow = fakeNow.add(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 1));

      expect(timer.remainingSeconds, 30);
      timer.stop();
    });

    testWidgets('syncWithClock updates the time without waiting for a tick',
        (tester) async {
      final timer = newTimer(60);

      timer.start(() {});
      fakeNow = fakeNow.add(const Duration(seconds: 20));
      timer.syncWithClock();

      expect(timer.remainingSeconds, 40);
      timer.stop();
    });

    testWidgets('syncWithClock does nothing on a paused timer', (tester) async {
      final timer = newTimer(60);

      fakeNow = fakeNow.add(const Duration(seconds: 20));
      timer.syncWithClock();

      expect(timer.remainingSeconds, 60);
    });

    testWidgets('time spent paused is not counted when resuming',
        (tester) async {
      final timer = newTimer(10);

      timer.start(() {});
      await pass(tester, 4);
      timer.stop();
      fakeNow = fakeNow.add(const Duration(seconds: 100));
      timer.start(() {});
      await pass(tester, 3);

      expect(timer.remainingSeconds, 3);
      timer.stop();
    });
  });

  group('TimerModel.listFromJson', () {
    test('loads a saved list of timers', () {
      final json = jsonEncode([
        TimerModel(title: 'Tea', remainingSeconds: 60).toMap(),
        TimerModel(title: 'Eggs', remainingSeconds: 300).toMap(),
      ]);

      final timers = TimerModel.listFromJson(json);

      expect(timers.map((t) => t.title), ['Tea', 'Eggs']);
    });

    test('skips a bad entry and keeps the good ones', () {
      final json = jsonEncode([
        TimerModel(title: 'Tea', remainingSeconds: 60).toMap(),
        {'initialSeconds': 60},
        'not a timer',
        TimerModel(title: 'Eggs', remainingSeconds: 300).toMap(),
      ]);

      final timers = TimerModel.listFromJson(json);

      expect(timers.map((t) => t.title), ['Tea', 'Eggs']);
    });

    test('returns an empty list for unreadable data', () {
      expect(TimerModel.listFromJson('{{ not json'), isEmpty);
      expect(TimerModel.listFromJson('{"a": 1}'), isEmpty);
    });
  });

  group('TimerModel saving and loading', () {
    test('a paused timer survives a round trip', () {
      final original = TimerModel(title: 'Tea', remainingSeconds: 90)
        ..remainingSeconds = 45;

      final loaded = TimerModel.fromMap(original.toMap());

      expect(loaded.title, 'Tea');
      expect(loaded.remainingSeconds, 45);
      expect(loaded.initialSeconds, 90);
      expect(loaded.isRunning, false);
    });

    test('a running timer catches up on time spent closed', () {
      final endTime = DateTime.now().add(const Duration(seconds: 30));
      final loaded = TimerModel.fromMap({
        'title': 'Tea',
        'initialSeconds': 60,
        'remainingSeconds': 50,
        'isRunning': true,
        'endTime': endTime.toIso8601String(),
      });

      expect(loaded.isRunning, true);
      expect(loaded.remainingSeconds, inInclusiveRange(28, 30));
      expect(loaded.initialSeconds, 60);
    });

    test('a running timer past its end time loads as negative', () {
      final endTime = DateTime.now().subtract(const Duration(seconds: 20));
      final loaded = TimerModel.fromMap({
        'title': 'Tea',
        'initialSeconds': 60,
        'remainingSeconds': 5,
        'isRunning': true,
        'endTime': endTime.toIso8601String(),
      });

      expect(loaded.remainingSeconds, lessThan(0));
    });
  });
}
