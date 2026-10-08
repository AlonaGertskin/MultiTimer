import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_store.dart';
import 'package:multitimer/chain_model.dart';
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

  // Pasta starts Sauce by itself, Sauce waits for Continue before Bread.
  ChainModel dinner({bool allAutomatic = false}) => ChainModel(
    name: 'Dinner',
    steps: [
      ChainStep(title: 'Pasta', seconds: 600, startsNext: true),
      ChainStep(title: 'Sauce', seconds: 900, startsNext: allAutomatic),
      ChainStep(title: 'Bread', seconds: 1200, startsNext: allAutomatic),
    ],
  );

  TimerModel tea() =>
      TimerModel(title: 'Tea', remainingSeconds: 180)..remainingSeconds = 100;

  TimerModel eggs() => TimerModel(title: 'Eggs', remainingSeconds: 300);

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> openWith(WidgetTester tester, List<Object> items) async {
    SharedPreferences.setMockInitialValues({
      'saved_timers': jsonEncode([
        for (final item in items)
          item is ChainModel ? item.toMap() : (item as TimerModel).toMap(),
      ]),
    });
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
    await tester.pumpAndSettle();
  }

  Future<void> enterEditMode(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Edit list'));
    await tester.pumpAndSettle();
  }

  Future<void> check(WidgetTester tester, int index) async {
    await tester.tap(find.byType(Checkbox).at(index));
    await tester.pump();
  }

  Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, String tooltip) =>
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip(tooltip),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed !=
      null;

  List<String> rowNames(WidgetTester tester) => tester
      .widgetList<TextField>(field('Timer name'))
      .map((f) => f.controller!.text)
      .toList();

  List<String> rowMinutes(WidgetTester tester) => tester
      .widgetList<TextField>(field('MM'))
      .map((f) => f.controller!.text)
      .toList();

  List<bool> switchValues(WidgetTester tester) => tester
      .widgetList<Switch>(find.byType(Switch))
      .map((s) => s.value)
      .toList();

  Future<int> savedItemCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (jsonDecode(prefs.getString('saved_timers')!) as List).length;
  }

  group('Make a bundle from the selection', () {
    testWidgets('the button works only with something selected', (
      tester,
    ) async {
      await openWith(tester, [tea(), dinner()]);
      await enterEditMode(tester);

      expect(isEnabled(tester, 'Make a bundle'), false);

      await check(tester, 0);

      expect(isEnabled(tester, 'Make a bundle'), true);
    });

    testWidgets('opens a new bundle filled in screen order with full times', (
      tester,
    ) async {
      await openWith(tester, [tea(), dinner(), eggs()]);
      await enterEditMode(tester);
      await check(tester, 1);
      await check(tester, 0);

      await tapTooltip(tester, 'Make a bundle');

      expect(find.text('New Bundle'), findsOneWidget);
      expect(
        tester.widget<TextField>(field('Bundle name')).controller!.text,
        '',
      );
      expect(rowNames(tester), ['Tea', 'Pasta', 'Sauce', 'Bread']);
      expect(rowMinutes(tester), ['03', '10', '15', '20']);
      expect(switchValues(tester), [false, true, false]);
    });

    testWidgets('the link between two selected items starts as manual', (
      tester,
    ) async {
      await openWith(tester, [dinner(allAutomatic: true), tea()]);
      await enterEditMode(tester);
      await tapTooltip(tester, 'Select all');

      await tapTooltip(tester, 'Make a bundle');

      expect(rowNames(tester), ['Pasta', 'Sauce', 'Bread', 'Tea']);
      expect(switchValues(tester), [true, true, false]);
    });

    testWidgets('saving adds the bundle and closes edit mode', (tester) async {
      await openWith(tester, [tea(), dinner(), eggs()]);
      await enterEditMode(tester);
      await check(tester, 0);
      await check(tester, 1);
      await tapTooltip(tester, 'Make a bundle');

      await tester.enterText(field('Bundle name'), 'Breakfast');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = (await BundleStore().load()).single;
      expect(saved.name, 'Breakfast');
      expect(saved.items.map((i) => i.title), [
        'Tea',
        'Pasta',
        'Sauce',
        'Bread',
      ]);
      expect(saved.items.map((i) => i.seconds), [180, 600, 900, 1200]);
      expect(saved.items.map((i) => i.startsNext), [false, true, false, false]);
      expect(find.text('Bundle Breakfast saved'), findsOneWidget);
      expect(find.text('Multi-Timer'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(await savedItemCount(), 3);
    });

    testWidgets('a name is still required', (tester) async {
      await openWith(tester, [tea()]);
      await enterEditMode(tester);
      await check(tester, 0);
      await tapTooltip(tester, 'Make a bundle');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a bundle name.'), findsOneWidget);
    });

    testWidgets('going back keeps edit mode and the selection', (tester) async {
      await openWith(tester, [tea(), dinner()]);
      await enterEditMode(tester);
      await check(tester, 0);
      await check(tester, 1);
      await tapTooltip(tester, 'Make a bundle');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('2 selected'), findsOneWidget);
      expect(await BundleStore().load(), isEmpty);
    });

    testWidgets('going back after typing a name asks first', (tester) async {
      await openWith(tester, [tea()]);
      await enterEditMode(tester);
      await check(tester, 0);
      await tapTooltip(tester, 'Make a bundle');
      await tester.enterText(field('Bundle name'), 'Breakfast');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  group('Save as bundle from a chain', () {
    Future<void> openDetails(WidgetTester tester) async {
      await openWith(tester, [dinner()]);
      await tapTooltip(tester, 'Chain details');
    }

    testWidgets('the chain screen has the button, a bundle editor does not', (
      tester,
    ) async {
      await openDetails(tester);
      expect(find.text('Save as bundle'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapTooltip(tester, 'Bundles');
      await tester.tap(find.text('New bundle'));
      await tester.pumpAndSettle();

      expect(find.text('Save as bundle'), findsNothing);
    });

    testWidgets('saves the chain as a bundle and stays on the screen', (
      tester,
    ) async {
      await openDetails(tester);

      await tester.tap(find.text('Save as bundle'));
      await tester.pumpAndSettle();

      final saved = (await BundleStore().load()).single;
      expect(saved.name, 'Dinner');
      expect(saved.items.map((i) => i.title), ['Pasta', 'Sauce', 'Bread']);
      expect(saved.items.map((i) => i.seconds), [600, 900, 1200]);
      expect(saved.items.map((i) => i.startsNext), [true, false, false]);
      expect(find.text('Bundle Dinner saved'), findsOneWidget);
      expect(find.text('Edit Chain'), findsOneWidget);
    });

    testWidgets('unsaved edits go into the bundle but not into the chain', (
      tester,
    ) async {
      await openDetails(tester);
      await tester.enterText(field('Chain name'), 'Supper');
      await tester.enterText(field('Timer name').first, 'Rice');

      await tester.tap(find.text('Save as bundle'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      final saved = (await BundleStore().load()).single;
      expect(saved.name, 'Supper');
      expect(saved.items.first.title, 'Rice');
      expect(find.text('Dinner · step 1 of 3'), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
    });

    testWidgets('the usual checks apply and nothing is saved', (tester) async {
      await openDetails(tester);
      await tester.enterText(field('Chain name'), '');

      await tester.tap(find.text('Save as bundle'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a chain name.'), findsOneWidget);
      expect(await BundleStore().load(), isEmpty);
    });
  });
}
