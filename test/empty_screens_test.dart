import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundles_page.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/notification_service.dart';
import 'package:multitimer/timer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotificationService extends NotificationService {
  @override
  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
    String body = 'Time is up',
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}

void main() {
  setUp(() => NotificationService.instance = FakeNotificationService());

  tearDown(() => NotificationService.instance = NotificationService());

  Finder hint(String text) => find.textContaining(text, findRichText: true);

  group('Main screen', () {
    Future<void> openWith(WidgetTester tester, List<TimerModel> timers) async {
      SharedPreferences.setMockInitialValues({
        if (timers.isNotEmpty)
          'saved_timers': jsonEncode(timers.map((t) => t.toMap()).toList()),
      });
      await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('with no timers shows a message, a hint and an icon', (
      tester,
    ) async {
      await openWith(tester, []);

      expect(find.text('No timers yet'), findsOneWidget);
      expect(hint('Tap + to add a timer'), findsOneWidget);
      expect(hint('to use a saved bundle'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('with timers shows no message', (tester) async {
      await openWith(tester, [TimerModel(title: 'Tea', remainingSeconds: 60)]);

      expect(find.text('Tea'), findsOneWidget);
      expect(find.text('No timers yet'), findsNothing);
    });

    testWidgets('deleting the last timer brings the message back, '
        'and Undo hides it again', (tester) async {
      await openWith(tester, [TimerModel(title: 'Tea', remainingSeconds: 60)]);

      await tester.drag(find.text('Tea'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('No timers yet'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Tea'), findsOneWidget);
      expect(find.text('No timers yet'), findsNothing);
    });
  });

  group('Bundles screen', () {
    testWidgets('with no bundles shows a message, a hint and an icon', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
      await tester.pumpAndSettle();

      expect(find.text('No bundles yet'), findsOneWidget);
      expect(
        hint('Save a group of timers you use often, like Dinner.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });
}
