import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';
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

const navigationBar = 48.0;
const screenHeight = 800.0;

void main() {
  setUp(() => NotificationService.instance = FakeNotificationService());

  tearDown(() => NotificationService.instance = NotificationService());

  void usePhoneWithNavigationBar(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: navigationBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: navigationBar);
    addTearDown(tester.view.reset);
  }

  Future<void> scrollToEnd(WidgetTester tester) async {
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first);
    do {
      list.position.jumpTo(list.position.maxScrollExtent);
      await tester.pumpAndSettle();
    } while (list.position.pixels < list.position.maxScrollExtent);
  }

  double bottomOf(WidgetTester tester, Finder finder) =>
      tester.getRect(finder).bottom;

  double topOfAddButton(WidgetTester tester) =>
      tester.getRect(find.byType(FloatingActionButton)).top;

  Future<void> openMainWithTimers(WidgetTester tester, int count) async {
    SharedPreferences.setMockInitialValues({
      'saved_timers': jsonEncode([
        for (var i = 1; i <= count; i++)
          TimerModel(title: 'Timer $i', remainingSeconds: 60).toMap(),
      ]),
    });
    usePhoneWithNavigationBar(tester);
    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
    await tester.pumpAndSettle();
  }

  group('Main screen', () {
    testWidgets('the last timer can be scrolled clear of the add button', (
      tester,
    ) async {
      await openMainWithTimers(tester, 12);

      await scrollToEnd(tester);

      expect(
        bottomOf(tester, find.byIcon(Icons.edit_outlined).last),
        lessThanOrEqualTo(topOfAddButton(tester)),
      );
    });

    testWidgets('in edit mode the last timer stays above the navigation bar', (
      tester,
    ) async {
      await openMainWithTimers(tester, 12);
      await tester.tap(find.byTooltip('Edit list'));
      await tester.pumpAndSettle();

      await scrollToEnd(tester);

      expect(
        bottomOf(tester, find.byIcon(Icons.edit_outlined).last),
        lessThanOrEqualTo(screenHeight - navigationBar),
      );
    });
  });

  group('Bundles screen', () {
    testWidgets('the last bundle can be scrolled clear of the button', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'saved_bundles': Bundle.listToJson([
          for (var i = 1; i <= 15; i++)
            Bundle(
              name: 'Bundle $i',
              items: [BundleItem(title: 'Step', seconds: 60)],
            ),
        ]),
      });
      usePhoneWithNavigationBar(tester);
      await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
      await tester.pumpAndSettle();

      await scrollToEnd(tester);

      expect(
        bottomOf(tester, find.text('Bundle 15')),
        lessThanOrEqualTo(topOfAddButton(tester)),
      );
    });
  });

  group('Bundle editor', () {
    testWidgets('Add timer can be scrolled above the navigation bar', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      usePhoneWithNavigationBar(tester);
      await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New bundle'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await scrollToEnd(tester);
        await tester.tap(find.text('Add timer'));
        await tester.pumpAndSettle();
      }

      await scrollToEnd(tester);

      expect(
        bottomOf(tester, find.text('Add timer')),
        lessThanOrEqualTo(screenHeight - navigationBar),
      );
    });
  });
}
