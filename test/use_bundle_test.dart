import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/chain_card.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/timer_card.dart';
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

  Future<List<Map<String, dynamic>>> savedItems() async {
    final prefs = await SharedPreferences.getInstance();
    return (jsonDecode(prefs.getString('saved_timers')!) as List)
        .cast<Map<String, dynamic>>();
  }

  testWidgets('a bundle with several timers adds one chain card', (
    tester,
  ) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    expect(find.byType(ChainCard), findsOneWidget);
    expect(find.byType(TimerCard), findsNothing);
    expect(find.text('Dinner · step 1 of 3'), findsOneWidget);
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('00:10:00'), findsOneWidget);
  });

  testWidgets('it goes back to the main screen and says what was added', (
    tester,
  ) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    expect(find.text('Multi-Timer'), findsOneWidget);
    expect(find.text('Added Dinner (3 steps)'), findsOneWidget);
  });

  testWidgets('a one-timer bundle adds a plain timer card', (tester) async {
    saveBundles([tea]);
    await openMain(tester);

    await useBundle(tester, 'Tea');

    expect(find.byType(TimerCard), findsOneWidget);
    expect(find.byType(ChainCard), findsNothing);
    expect(find.text('Steep'), findsOneWidget);
  });

  testWidgets('a one-timer bundle says "1 timer"', (tester) async {
    saveBundles([tea]);
    await openMain(tester);

    await useBundle(tester, 'Tea');

    expect(find.text('Added 1 timer from Tea'), findsOneWidget);
  });

  testWidgets('the chain is saved with the steps and links of the bundle', (
    tester,
  ) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    final saved = (await savedItems()).single;
    expect(saved['type'], 'chain');
    expect(saved['name'], 'Dinner');
    final steps = (saved['steps'] as List).cast<Map<String, dynamic>>();
    expect(steps.map((s) => s['title']), ['Pasta', 'Sauce', 'Bread']);
    expect(steps.map((s) => s['seconds']), [600, 900, 1200]);
    expect(steps.map((s) => s['startsNext']), [false, true, false]);
  });

  testWidgets('a chain is added after what is already there', (tester) async {
    saveBundles(
      [dinner],
      timers: [TimerModel(title: 'Existing', remainingSeconds: 60)],
    );
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    expect(shownOrder(tester, ['Existing', 'Pasta']), ['Existing', 'Pasta']);
  });

  testWidgets('adding the same bundle twice gives two separate chains', (
    tester,
  ) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');
    await useBundle(tester, 'Dinner');

    expect(find.byType(ChainCard), findsNWidgets(2));
    final saved = await savedItems();
    expect(saved.map((s) => s['id']).toSet().length, 2);
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

  testWidgets('the added chain is not running', (tester) async {
    saveBundles([dinner]);
    await openMain(tester);

    await useBundle(tester, 'Dinner');

    expect(find.byTooltip('Start'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsNothing);
    expect((await savedItems()).single['isRunning'], false);
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
