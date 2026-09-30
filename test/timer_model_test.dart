import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/timer_model.dart';

void main() {
  group('TimerModel', () {
    testWidgets('counts down once per second while running', (tester) async {
      final timer = TimerModel(title: 'Tea', remainingSeconds: 10);
      int ticks = 0;

      timer.start(() => ticks++);
      await tester.pump(const Duration(seconds: 3));

      expect(timer.remainingSeconds, 7);
      expect(ticks, 3);
      expect(timer.isRunning, true);
      timer.stop();
    });

    testWidgets('keeps counting into negative time after zero',
        (tester) async {
      final timer = TimerModel(title: 'Tea', remainingSeconds: 2);

      timer.start(() {});
      await tester.pump(const Duration(seconds: 5));

      expect(timer.remainingSeconds, -3);
      expect(timer.isRunning, true);
      timer.stop();
    });

    testWidgets('stop pauses the countdown', (tester) async {
      final timer = TimerModel(title: 'Tea', remainingSeconds: 10);

      timer.start(() {});
      await tester.pump(const Duration(seconds: 2));
      timer.stop();
      await tester.pump(const Duration(seconds: 5));

      expect(timer.remainingSeconds, 8);
      expect(timer.isRunning, false);
      expect(timer.internalTimer, isNull);
    });

    testWidgets('calling start twice does not double the speed',
        (tester) async {
      final timer = TimerModel(title: 'Tea', remainingSeconds: 10);

      timer.start(() {});
      timer.start(() {});
      await tester.pump(const Duration(seconds: 3));

      expect(timer.remainingSeconds, 7);
      timer.stop();
    });

    testWidgets('reset stops the timer and restores the starting time',
        (tester) async {
      final timer = TimerModel(title: 'Tea', remainingSeconds: 10);

      timer.start(() {});
      await tester.pump(const Duration(seconds: 4));
      timer.reset();

      expect(timer.remainingSeconds, 10);
      expect(timer.isRunning, false);
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
