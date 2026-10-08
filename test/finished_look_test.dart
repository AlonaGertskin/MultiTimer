import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/chain_card.dart';
import 'package:multitimer/chain_model.dart';
import 'package:multitimer/timer_card.dart';
import 'package:multitimer/timer_model.dart';

void main() {
  Future<ColorScheme> pump(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));
    return Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
  }

  Widget timerCard(TimerModel timer) => TimerCard(
    timer: timer,
    onStart: () {},
    onPause: () {},
    onReset: () {},
    onEdit: () {},
  );

  Widget chainCard(ChainModel chain) => ChainCard(
    chain: chain,
    onStart: () {},
    onPause: () {},
    onResetStep: () {},
    onSkip: () {},
    onContinue: () {},
    onRestart: () {},
    onDetails: () {},
  );

  Color? cardColor(WidgetTester tester) =>
      tester.widget<Card>(find.byType(Card)).color;

  Color? timeColor(WidgetTester tester, String time) =>
      tester.widget<Text>(find.text(time)).style?.color;

  group('A plain timer', () {
    test('is finished once its time reaches zero', () {
      expect(TimerModel(title: 'Tea', remainingSeconds: 1).isFinished, false);
      expect(TimerModel(title: 'Tea', remainingSeconds: 0).isFinished, true);
      expect(TimerModel(title: 'Tea', remainingSeconds: -5).isFinished, true);
    });

    testWidgets('before zero looks normal', (tester) async {
      final colors = await pump(
        tester,
        timerCard(
          TimerModel(title: 'Tea', remainingSeconds: 300)..isRunning = true,
        ),
      );

      expect(cardColor(tester), isNot(colors.secondaryContainer));
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(timeColor(tester, '00:05:00'), isNot(colors.error));
    });

    testWidgets('at zero is tinted with a check mark', (tester) async {
      final colors = await pump(
        tester,
        timerCard(
          TimerModel(title: 'Tea', remainingSeconds: 0)..isRunning = true,
        ),
      );

      expect(cardColor(tester), colors.secondaryContainer);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
      expect(timeColor(tester, '00:00:00'), isNot(colors.error));
    });

    testWidgets('late is tinted and its time is not red', (tester) async {
      final colors = await pump(
        tester,
        timerCard(
          TimerModel(title: 'Tea', remainingSeconds: -72)..isRunning = true,
        ),
      );

      expect(cardColor(tester), colors.secondaryContainer);
      expect(timeColor(tester, '-00:01:12'), isNot(colors.error));
    });

    testWidgets('paused after finishing keeps the finished look', (
      tester,
    ) async {
      final colors = await pump(
        tester,
        timerCard(TimerModel(title: 'Tea', remainingSeconds: -12)),
      );

      expect(cardColor(tester), colors.secondaryContainer);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(timeColor(tester, '-00:00:12'), isNot(colors.error));
    });
  });

  group('A chain', () {
    ChainModel dinner({int currentIndex = 0, required int remaining}) =>
        ChainModel(
          name: 'Dinner',
          steps: [
            ChainStep(title: 'Pasta', seconds: 600),
            ChainStep(title: 'Sauce', seconds: 900),
          ],
          currentIndex: currentIndex,
          remainingSeconds: remaining,
          isRunning: true,
        );

    testWidgets('running before zero shows its time normally', (tester) async {
      final colors = await pump(tester, chainCard(dinner(remaining: 300)));

      expect(timeColor(tester, '00:05:00'), isNot(colors.error));
    });

    testWidgets('waiting for Continue does not show its late time in red', (
      tester,
    ) async {
      final colors = await pump(tester, chainCard(dinner(remaining: -40)));

      expect(find.text('Pasta finished'), findsOneWidget);
      expect(timeColor(tester, '-00:00:40'), isNot(colors.error));
    });

    testWidgets('complete does not show its late time in red', (tester) async {
      final colors = await pump(
        tester,
        chainCard(dinner(currentIndex: 1, remaining: -30)),
      );

      expect(find.text('Dinner complete'), findsOneWidget);
      expect(timeColor(tester, '-00:00:30'), isNot(colors.error));
    });
  });
}
