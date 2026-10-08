import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/chain_card.dart';
import 'package:multitimer/chain_model.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotificationService extends NotificationService {
  @override
  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}

void main() {
  setUp(() => NotificationService.instance = FakeNotificationService());

  tearDown(() => NotificationService.instance = NotificationService());

  // Pasta waits for Continue, Sauce starts Bread by itself.
  ChainModel dinner({
    int currentIndex = 0,
    bool isRunning = false,
    DateTime? endTime,
  }) => ChainModel(
    name: 'Dinner',
    steps: [
      ChainStep(title: 'Pasta', seconds: 600),
      ChainStep(title: 'Sauce', seconds: 900, startsNext: true),
      ChainStep(title: 'Bread', seconds: 1200),
    ],
    currentIndex: currentIndex,
    isRunning: isRunning,
    endTime: endTime,
  );

  DateTime fromNow(int seconds) =>
      DateTime.now().add(Duration(seconds: seconds));

  Future<void> openWith(WidgetTester tester, ChainModel chain) async {
    SharedPreferences.setMockInitialValues({
      'saved_timers': jsonEncode([chain.toMap()]),
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

  Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  Future<void> stopTicking(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  group('Ready and running', () {
    testWidgets('a new chain shows its first step, ready to start', (
      tester,
    ) async {
      await openWith(tester, dinner());

      expect(find.text('Dinner · step 1 of 3'), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('00:10:00'), findsOneWidget);
      expect(find.byTooltip('Start'), findsOneWidget);
      expect(find.byTooltip('Reset step'), findsOneWidget);
      expect(find.byTooltip('Skip step'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      expect(find.text('Restart chain'), findsNothing);
    });

    testWidgets('start runs the step and is saved', (tester) async {
      await openWith(tester, dinner());

      await tapTooltip(tester, 'Start');

      expect(find.byTooltip('Pause'), findsOneWidget);
      expect((await savedChain())['isRunning'], true);
      await stopTicking(tester);
    });

    testWidgets('pause stops the step and is saved', (tester) async {
      await openWith(tester, dinner(isRunning: true, endTime: fromNow(300)));

      await tapTooltip(tester, 'Pause');

      expect(find.byTooltip('Start'), findsOneWidget);
      final saved = await savedChain();
      expect(saved['isRunning'], false);
      expect(saved['remainingSeconds'], closeTo(300, 1));
    });

    testWidgets('reset step puts the current step back to its full time', (
      tester,
    ) async {
      await openWith(
        tester,
        dinner(currentIndex: 1, isRunning: true, endTime: fromNow(300)),
      );

      await tapTooltip(tester, 'Reset step');

      expect(find.text('Sauce'), findsOneWidget);
      expect(find.text('00:15:00'), findsOneWidget);
      expect(find.byTooltip('Start'), findsOneWidget);
    });

    testWidgets('skip after a manual link shows the next step ready', (
      tester,
    ) async {
      await openWith(tester, dinner());

      await tapTooltip(tester, 'Skip step');

      expect(find.text('Dinner · step 2 of 3'), findsOneWidget);
      expect(find.text('Sauce'), findsOneWidget);
      expect(find.byTooltip('Start'), findsOneWidget);
      expect((await savedChain())['currentIndex'], 1);
    });

    testWidgets('skip after an automatic link starts the next step', (
      tester,
    ) async {
      await openWith(tester, dinner(currentIndex: 1));

      await tapTooltip(tester, 'Skip step');

      expect(find.text('Bread'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      await stopTicking(tester);
    });

    testWidgets('there is no skip on the last step', (tester) async {
      await openWith(tester, dinner(currentIndex: 2));

      expect(find.byTooltip('Skip step'), findsNothing);
    });
  });

  group('Waiting for Continue', () {
    ChainModel pastaDone() => dinner(isRunning: true, endTime: fromNow(-72));

    testWidgets('shows the finished step, its late time and what is next', (
      tester,
    ) async {
      await openWith(tester, pastaDone());

      expect(find.text('Pasta finished'), findsOneWidget);
      expect(find.text('-00:01:12'), findsOneWidget);
      expect(find.text('Next: Sauce · 00:15:00'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byTooltip('Skip step'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsNothing);
      expect(find.byTooltip('Start'), findsNothing);
      await stopTicking(tester);
    });

    testWidgets('Continue starts the next step', (tester) async {
      await openWith(tester, pastaDone());

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Dinner · step 2 of 3'), findsOneWidget);
      expect(find.text('Sauce'), findsOneWidget);
      expect(find.text('00:15:00'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      final saved = await savedChain();
      expect(saved['currentIndex'], 1);
      expect(saved['isRunning'], true);
      await stopTicking(tester);
    });

    testWidgets('skip moves on without starting the next step', (tester) async {
      await openWith(tester, pastaDone());

      await tapTooltip(tester, 'Skip step');

      expect(find.text('Sauce'), findsOneWidget);
      expect(find.byTooltip('Start'), findsOneWidget);
    });
  });

  group('Complete', () {
    ChainModel breadDone() =>
        dinner(currentIndex: 2, isRunning: true, endTime: fromNow(-30));

    testWidgets('says the chain is complete with a Restart chain button', (
      tester,
    ) async {
      await openWith(tester, breadDone());

      expect(find.text('Dinner complete'), findsOneWidget);
      expect(find.text('-00:00:30'), findsOneWidget);
      expect(find.text('Restart chain'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      expect(find.byTooltip('Skip step'), findsNothing);
      expect(find.byTooltip('Pause'), findsNothing);
      await stopTicking(tester);
    });

    testWidgets('Restart chain goes back to a ready first step', (
      tester,
    ) async {
      await openWith(tester, breadDone());

      await tester.tap(find.text('Restart chain'));
      await tester.pumpAndSettle();

      expect(find.text('Dinner · step 1 of 3'), findsOneWidget);
      expect(find.text('00:10:00'), findsOneWidget);
      expect(find.byTooltip('Start'), findsOneWidget);
      final saved = await savedChain();
      expect(saved['currentIndex'], 0);
      expect(saved['isRunning'], false);
    });
  });

  group('Progress strip', () {
    final strip = find.byType(ChainProgressStrip);

    List<double> fills(WidgetTester tester) => tester
        .widgetList<FractionallySizedBox>(
          find.descendant(
            of: strip,
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .map((box) => box.widthFactor!)
        .toList();

    int gaps() => find
        .descendant(
          of: strip,
          matching: find.byKey(const ValueKey('manual-gap')),
        )
        .evaluate()
        .length;

    testWidgets('has one piece per step, all empty before starting', (
      tester,
    ) async {
      await openWith(tester, dinner());

      expect(fills(tester), [0, 0, 0]);
    });

    testWidgets('done steps are full and the current step fills up', (
      tester,
    ) async {
      await openWith(
        tester,
        dinner(currentIndex: 1, isRunning: true, endTime: fromNow(450)),
      );

      final values = fills(tester);
      expect(values[0], 1);
      expect(values[1], closeTo(0.5, 0.01));
      expect(values[2], 0);
      await stopTicking(tester);
    });

    testWidgets('a complete chain is full', (tester) async {
      await openWith(
        tester,
        dinner(currentIndex: 2, isRunning: true, endTime: fromNow(-5)),
      );

      expect(fills(tester), [1, 1, 1]);
      await stopTicking(tester);
    });

    testWidgets('only manual links leave a gap', (tester) async {
      await openWith(tester, dinner());

      expect(gaps(), 1);
    });

    testWidgets('longer steps get longer pieces', (tester) async {
      await openWith(tester, dinner());

      final widths = tester
          .widgetList<Expanded>(
            find.descendant(of: strip, matching: find.byType(Expanded)),
          )
          .map((e) => e.flex)
          .toList();

      expect(widths, [600, 900, 1200]);
    });
  });
}
