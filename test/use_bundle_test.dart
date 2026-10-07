import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/timer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final dinner = Bundle(
    name: 'Dinner',
    items: const [
      BundleItem(title: 'Pasta', seconds: 600),
      BundleItem(title: 'Sauce', seconds: 900, startsNext: true),
      BundleItem(title: 'Bread', seconds: 1200),
    ],
  );

  final tea = Bundle(
    name: 'Tea',
    items: const [BundleItem(title: 'Steep', seconds: 180)],
  );

  void saveBundles(List<Bundle> bundles, {List<TimerModel> timers = const []}) {
    SharedPreferences.setMockInitialValues({
      'saved_bundles': Bundle.listToJson(bundles),
      if (timers.isNotEmpty)
        'saved_timers': jsonEncode(timers.map((t) => t.toMap()).toList()),
    });
  }

  Future<void> openMain(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
    await tester.pumpAndSettle();
  }

  Future<void> useBundle(WidgetTester tester, String name) async {
    await tester.tap(find.byTooltip('Bundles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  List<String> shownOrder(WidgetTester tester, List<String> titles) {
    final found = titles
        .where((t) => find.text(t).evaluate().isNotEmpty)
        .toList();
    found.sort(
      (a, b) => tester
          .getTopLeft(find.text(a).first)
          .dy
          .compareTo(tester.getTopLeft(find.text(b).first).dy),
    );
    return found;
  }

  testWidgets('tapping a bundle adds its timers to the list', (tester) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('Sauce'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('00:10:00'), findsOneWidget);
    expect(find.text('00:15:00'), findsOneWidget);
    expect(find.text('00:20:00'), findsOneWidget);
  });

  testWidgets('it goes back to the main screen and says what was added', (
    tester,
  ) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    expect(find.text('Multi-Timer'), findsOneWidget);
    expect(find.text('Added 3 timers from Dinner'), findsOneWidget);
  });

  testWidgets('a one-timer bundle says "1 timer"', (tester) async {
    saveBundles([tea]);
    await openMain(tester);

    await useBundle(tester, 'Tea');

    expect(find.text('Added 1 timer from Tea'), findsOneWidget);
  });

  testWidgets('the timers are added in the bundle order', (tester) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    expect(shownOrder(tester, ['Pasta', 'Sauce', 'Bread']), [
      'Pasta',
      'Sauce',
      'Bread',
    ]);
  });

  testWidgets('they are added after the timers already there', (tester) async {
    saveBundles(
      [tea],
      timers: [TimerModel(title: 'Existing', remainingSeconds: 60)],
    );
    await openMain(tester);

    await useBundle(tester, 'Tea');

    expect(shownOrder(tester, ['Existing', 'Steep']), ['Existing', 'Steep']);
  });

  testWidgets('adding the same bundle twice gives duplicates', (tester) async {
    saveBundles([tea]);
    await openMain(tester);

    await useBundle(tester, 'Tea');
    await useBundle(tester, 'Tea');

    expect(find.text('Steep'), findsNWidgets(2));
  });

  testWidgets('the added timers are saved with their own ids', (tester) async {
    saveBundles([tea]);
    await openMain(tester);
    await useBundle(tester, 'Tea');
    await useBundle(tester, 'Tea');

    final prefs = await SharedPreferences.getInstance();
    final saved = TimerModel.listFromJson(prefs.getString('saved_timers')!);

    expect(saved.map((t) => t.title), ['Steep', 'Steep']);
    expect(saved.map((t) => t.initialSeconds), [180, 180]);
    expect(saved.map((t) => t.id).toSet().length, 2);
  });

  testWidgets('the added timers are not running', (tester) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    expect(find.byIcon(Icons.play_arrow), findsNWidgets(3));
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('going back from the bundles screen adds nothing', (
    tester,
  ) async {
    saveBundles([dinner]);
    await openMain(tester);

    await tester.tap(find.byTooltip('Bundles'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Pasta'), findsNothing);
    expect(find.textContaining('Added'), findsNothing);
  });
}
