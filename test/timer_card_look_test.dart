import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/app_colors.dart';
import 'package:multitimer/chain_card.dart';
import 'package:multitimer/chain_model.dart';
import 'package:multitimer/timer_card.dart';
import 'package:multitimer/timer_model.dart';

void main() {
  late List<String> tapped;

  setUp(() => tapped = []);

  TimerModel tea({int remaining = 600, bool running = false}) =>
      TimerModel(title: 'Tea', remainingSeconds: 600)
        ..remainingSeconds = remaining
        ..isRunning = running;

  Future<void> pump(WidgetTester tester, TimerModel timer) {
    final card = TimerCard(
      timer: timer,
      onStart: () => tapped.add('start'),
      onPause: () => tapped.add('pause'),
      onReset: () => tapped.add('reset'),
      onEdit: () => tapped.add('edit'),
    );
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));
  }

  double? progress(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .value;

  group('The time', () {
    testWidgets('is 22 points', (tester) async {
      await pump(tester, tea());

      final style = tester.widget<Text>(find.text('00:10:00')).style!;
      expect(style.fontSize, 22);
    });

    testWidgets('is on the same line as the name', (tester) async {
      await pump(tester, tea());

      expect(
        tester.getCenter(find.text('00:10:00')).dy,
        closeTo(tester.getCenter(find.text('Tea')).dy, 4),
      );
    });

    testWidgets('uses equal-width digits so it does not wiggle', (
      tester,
    ) async {
      await pump(tester, tea());

      final style = tester.widget<Text>(find.text('00:10:00')).style!;
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });
  });

  group('The name and the edit button', () {
    testWidgets('the name has the same style as a chain step name', (
      tester,
    ) async {
      await pump(tester, tea());

      final theme = Theme.of(tester.element(find.text('Tea')));
      expect(
        tester.widget<Text>(find.text('Tea')).style,
        theme.textTheme.titleMedium,
      );
    });

    testWidgets('edit sits with the other buttons, below the bar', (
      tester,
    ) async {
      await pump(tester, tea());

      expect(
        tester.getCenter(find.byTooltip('Edit')).dy,
        greaterThan(tester.getCenter(find.byType(LinearProgressIndicator)).dy),
      );
      expect(
        tester.getCenter(find.byTooltip('Edit')).dy,
        closeTo(tester.getCenter(find.byTooltip('Reset')).dy, 1),
      );
      await tester.tap(find.byTooltip('Edit'));
      expect(tapped, ['edit']);
    });
  });

  group('The buttons', () {
    testWidgets('a ready timer shows Start and Reset', (tester) async {
      await pump(tester, tea());

      expect(find.byTooltip('Start'), findsOneWidget);
      expect(find.byTooltip('Reset'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsNothing);
      await tester.tap(find.byTooltip('Start'));
      expect(tapped, ['start']);
    });

    testWidgets('a running timer shows Pause and Reset', (tester) async {
      await pump(tester, tea(remaining: 300, running: true));

      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byTooltip('Reset'), findsOneWidget);
      expect(find.byTooltip('Start'), findsNothing);
      await tester.tap(find.byTooltip('Pause'));
      expect(tapped, ['pause']);
    });

    testWidgets('a finished timer shows Reset but no Start or Pause', (
      tester,
    ) async {
      await pump(tester, tea(remaining: -72, running: true));

      expect(find.byTooltip('Reset'), findsOneWidget);
      expect(find.byTooltip('Start'), findsNothing);
      expect(find.byTooltip('Pause'), findsNothing);
      await tester.tap(find.byTooltip('Reset'));
      expect(tapped, ['reset']);
    });

    testWidgets('a paused finished timer also shows Reset but no Start', (
      tester,
    ) async {
      await pump(tester, tea(remaining: -12));

      expect(find.byTooltip('Reset'), findsOneWidget);
      expect(find.byTooltip('Start'), findsNothing);
    });
  });

  group('The progress bar', () {
    testWidgets('uses the track colour for its empty part', (tester) async {
      await pump(tester, tea());

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final colors = Theme.of(tester.element(find.text('Tea'))).colorScheme;
      expect(bar.backgroundColor, progressTrackColor(colors));
    });

    testWidgets('is empty when ready', (tester) async {
      await pump(tester, tea());

      expect(progress(tester), 0);
    });

    testWidgets('fills with the time that has passed', (tester) async {
      await pump(tester, tea(remaining: 150, running: true));

      expect(progress(tester), 0.75);
    });

    testWidgets('keeps its place when paused', (tester) async {
      await pump(tester, tea(remaining: 450));

      expect(progress(tester), 0.25);
    });

    testWidgets('is full when finished, also in negative time', (tester) async {
      await pump(tester, tea(remaining: 0, running: true));
      expect(progress(tester), 1);

      await pump(tester, tea(remaining: -72, running: true));
      expect(progress(tester), 1);
    });
  });

  group('The time on a chain card', () {
    Future<TextStyle> chainTimeStyle(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainCard(
              chain: ChainModel(
                name: 'Dinner',
                steps: [
                  ChainStep(title: 'Pasta', seconds: 600),
                  ChainStep(title: 'Sauce', seconds: 900),
                ],
              ),
              onStart: () {},
              onPause: () {},
              onResetStep: () {},
              onSkip: () {},
              onContinue: () {},
              onRestart: () {},
              onDetails: () {},
            ),
          ),
        ),
      );
      return tester.widget<Text>(find.text('00:10:00')).style!;
    }

    testWidgets('is 22 points, like on a timer card', (tester) async {
      expect((await chainTimeStyle(tester)).fontSize, 22);
    });

    testWidgets('its strip uses the track colour for the empty parts', (
      tester,
    ) async {
      await chainTimeStyle(tester);

      final colors = Theme.of(
        tester.element(find.byType(ChainProgressStrip)),
      ).colorScheme;
      final pieces = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ChainProgressStrip),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.child is FractionallySizedBox,
          ),
        ),
      );
      expect(pieces, hasLength(2));
      for (final piece in pieces) {
        expect(piece.color, progressTrackColor(colors));
      }
    });

    testWidgets('uses equal-width digits', (tester) async {
      expect(
        (await chainTimeStyle(tester)).fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
