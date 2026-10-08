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

  // Pasta starts Sauce by itself, Sauce waits for Continue before Bread.
  ChainModel newDinner({
    List<String> steps = const ['Pasta', 'Sauce', 'Bread'],
    int currentIndex = 0,
    bool isRunning = false,
    DateTime? endTime,
  }) => ChainModel(
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

  Future<List<Map<String, dynamic>>> savedItems() async {
    final prefs = await SharedPreferences.getInstance();
    return (jsonDecode(prefs.getString('saved_timers')!) as List)
        .cast<Map<String, dynamic>>();
  }

  Future<void> undo(WidgetTester tester) async {
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
  }

  Future<void> swipeToTrash(WidgetTester tester, Finder card) async {
    await tester.drag(card, const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
  }

  Future<void> stopTicking(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('a chain card has no button to delete a single step', (
    tester,
  ) async {
    await openWith(tester, [newDinner()]);

    expect(find.byTooltip('Delete step'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  group('Swiping a chain card', () {
    final chainCard = find.textContaining('Dinner ·');

    testWidgets('asks before deleting the whole chain', (tester) async {
      await openWith(tester, [newDinner()]);

      await swipeToTrash(tester, chainCard);

      expect(find.text('Delete Dinner?'), findsOneWidget);
      expect(
        find.text('This removes the whole chain (3 steps).'),
        findsOneWidget,
      );
    });

    testWidgets('Cancel keeps the chain', (tester) async {
      await openWith(tester, [newDinner()]);
      await swipeToTrash(tester, chainCard);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Dinner?'), findsNothing);
      expect(chainCard, findsOneWidget);
      expect(find.text('Undo'), findsNothing);
      expect(await savedItems(), hasLength(1));
    });

    testWidgets('Delete removes it, with Undo', (tester) async {
      await openWith(tester, [
        newDinner(isRunning: true, endTime: fromNow(300)),
      ]);
      await swipeToTrash(tester, chainCard);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(chainCard, findsNothing);
      expect(find.text('Dinner deleted'), findsOneWidget);
      expect(fake.scheduled, isEmpty);

      await undo(tester);

      expect(chainCard, findsOneWidget);
      await stopTicking(tester);
    });

    testWidgets('a plain timer is still deleted without a question', (
      tester,
    ) async {
      await openWith(tester, [TimerModel(title: 'Tea', remainingSeconds: 60)]);

      await swipeToTrash(tester, find.text('Tea'));

      expect(find.text('Delete Tea?'), findsNothing);
      expect(find.text('Tea deleted'), findsOneWidget);
    });
  });
}
