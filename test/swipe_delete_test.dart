import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/bundle_store.dart';
import 'package:multitimer/bundles_page.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/notification_service.dart';
import 'package:multitimer/timer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotificationService extends NotificationService {
  final List<String> calls = [];
  final Map<int, DateTime> scheduled = {};

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
    String body = 'Time is up',
  }) async {
    calls.add('schedule $id');
    scheduled[id] = when;
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel $id');
    scheduled.remove(id);
  }
}

Finder trashFor(String text) => find.descendant(
  of: find.ancestor(of: find.text(text), matching: find.byType(Slidable)),
  matching: find.byIcon(Icons.delete_outline),
);

Future<void> slide(
  WidgetTester tester,
  String text, {
  double distance = -300,
}) async {
  await tester.drag(find.text(text), Offset(distance, 0));
  await tester.pumpAndSettle();
}

Future<void> slideAndDelete(WidgetTester tester, String text) async {
  await slide(tester, text);
  await tester.tap(trashFor(text));
  await tester.pumpAndSettle();
}

void main() {
  late FakeNotificationService fake;

  setUp(() {
    fake = FakeNotificationService();
    NotificationService.instance = fake;
  });

  tearDown(() => NotificationService.instance = NotificationService());

  group('Swipe to delete a timer', () {
    TimerModel plain(String title, int seconds) =>
        TimerModel(title: title, remainingSeconds: seconds);

    TimerModel running(String title, int seconds) => TimerModel(
      title: title,
      remainingSeconds: seconds,
      isRunning: true,
      endTime: DateTime.now().add(Duration(seconds: seconds)),
    );

    void saveTimers(List<TimerModel> timers) {
      SharedPreferences.setMockInitialValues({
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

    Future<void> undo(WidgetTester tester) async {
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
    }

    Future<List<String>> savedTitles() async {
      final prefs = await SharedPreferences.getInstance();
      return TimerModel.listFromJson(
        prefs.getString('saved_timers')!,
      ).map((t) => t.title).toList();
    }

    List<String> shownOrder(WidgetTester tester, List<String> titles) {
      final found = titles
          .where((t) => find.text(t).evaluate().isNotEmpty)
          .toList();
      found.sort(
        (a, b) => tester
            .getTopLeft(find.text(a))
            .dy
            .compareTo(tester.getTopLeft(find.text(b)).dy),
      );
      return found;
    }

    testWidgets('the cards have no trash button until swiped', (tester) async {
      saveTimers([plain('Tea', 60)]);
      await openMain(tester);

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('swiping left shows a trash button but deletes nothing', (
      tester,
    ) async {
      saveTimers([plain('Tea', 60), plain('Eggs', 300)]);
      await openMain(tester);

      await slide(tester, 'Tea');

      expect(trashFor('Tea'), findsOneWidget);
      expect(find.text('Tea'), findsOneWidget);
      expect(find.text('Tea deleted'), findsNothing);
      expect(await savedTitles(), ['Tea', 'Eggs']);
    });

    testWidgets('tapping the trash button deletes the timer and shows Undo', (
      tester,
    ) async {
      saveTimers([plain('Tea', 60), plain('Eggs', 300)]);
      await openMain(tester);

      await slideAndDelete(tester, 'Tea');

      expect(find.text('Tea'), findsNothing);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Tea deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('swiping right does nothing', (tester) async {
      saveTimers([plain('Tea', 60)]);
      await openMain(tester);
      final before = tester.getTopLeft(find.text('Tea'));

      await slide(tester, 'Tea', distance: 300);

      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.text('Tea'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Tea')), before);
    });

    testWidgets('a short swipe springs back closed', (tester) async {
      saveTimers([plain('Tea', 60)]);
      await openMain(tester);
      final before = tester.getTopLeft(find.text('Tea'));

      await slide(tester, 'Tea', distance: -20);

      expect(tester.getTopLeft(find.text('Tea')), before);
      expect(find.text('Tea deleted'), findsNothing);
    });

    testWidgets('only one card is open at a time', (tester) async {
      saveTimers([plain('A', 60), plain('B', 120)]);
      await openMain(tester);
      final closedA = tester.getTopLeft(find.text('A'));

      await slide(tester, 'A');
      expect(tester.getTopLeft(find.text('A')).dx, lessThan(closedA.dx));

      await tester.drag(
        find.text('B'),
        const Offset(-300, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('A')), closedA);
    });

    testWidgets('swiping is off in edit mode, so handles stay put', (
      tester,
    ) async {
      saveTimers([plain('Tea', 60)]);
      await openMain(tester);
      await tester.tap(find.byTooltip('Edit list'));
      await tester.pumpAndSettle();
      final handleBefore = tester.getCenter(find.byIcon(Icons.drag_handle));
      final cardBefore = tester.getTopLeft(find.text('Tea'));

      await slide(tester, 'Tea');

      expect(trashFor('Tea'), findsNothing);
      expect(tester.getCenter(find.byIcon(Icons.drag_handle)), handleBefore);
      expect(tester.getTopLeft(find.text('Tea')), cardBefore);
    });

    testWidgets('swiping works again after leaving edit mode', (tester) async {
      saveTimers([plain('Tea', 60)]);
      await openMain(tester);
      await tester.tap(find.byTooltip('Edit list'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      await slide(tester, 'Tea');

      expect(trashFor('Tea'), findsOneWidget);
    });

    testWidgets('the deletion is saved', (tester) async {
      saveTimers([plain('Tea', 60), plain('Eggs', 300)]);
      await openMain(tester);

      await slideAndDelete(tester, 'Tea');

      expect(await savedTitles(), ['Eggs']);
    });

    testWidgets('undo puts the timer back in the same place', (tester) async {
      saveTimers([plain('A', 60), plain('B', 120), plain('C', 180)]);
      await openMain(tester);

      await slideAndDelete(tester, 'B');
      expect(shownOrder(tester, ['A', 'B', 'C']), ['A', 'C']);
      await undo(tester);

      expect(shownOrder(tester, ['A', 'B', 'C']), ['A', 'B', 'C']);
      expect(find.text('00:02:00'), findsOneWidget);
      expect(await savedTitles(), ['A', 'B', 'C']);
    });

    testWidgets('undo brings back a paused timer paused', (tester) async {
      saveTimers([plain('Tea', 60)]);
      await openMain(tester);

      await slideAndDelete(tester, 'Tea');
      await undo(tester);

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('deleting a running timer cancels its alert', (tester) async {
      final timer = running('Pasta', 600);
      saveTimers([timer]);
      await openMain(tester);
      expect(fake.scheduled.containsKey(timer.id), true);

      await slideAndDelete(tester, 'Pasta');

      expect(fake.scheduled.containsKey(timer.id), false);
      expect(fake.calls.last, 'cancel ${timer.id}');
    });

    testWidgets('undo brings back a running timer, running, with its alert', (
      tester,
    ) async {
      final timer = running('Pasta', 600);
      saveTimers([timer]);
      await openMain(tester);
      final originalEnd = fake.scheduled[timer.id]!;

      await slideAndDelete(tester, 'Pasta');
      await undo(tester);

      expect(find.byIcon(Icons.pause), findsOneWidget);
      final restoredEnd = fake.scheduled[timer.id]!;
      expect(restoredEnd.difference(originalEnd).inSeconds.abs(), lessThan(2));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a new deletion replaces the earlier message', (tester) async {
      saveTimers([plain('A', 60), plain('B', 120)]);
      await openMain(tester);

      await slideAndDelete(tester, 'A');
      await slideAndDelete(tester, 'B');

      expect(find.text('B deleted'), findsOneWidget);
      expect(find.text('A deleted'), findsNothing);
    });
  });

  group('Swipe to delete a bundle', () {
    final dinner = Bundle(
      name: 'Dinner',
      items: const [BundleItem(title: 'Pasta', seconds: 600)],
    );
    final tea = Bundle(
      name: 'Tea',
      items: const [BundleItem(title: 'Steep', seconds: 180)],
    );

    Future<void> openBundles(WidgetTester tester, List<Bundle> bundles) async {
      SharedPreferences.setMockInitialValues({
        'saved_bundles': Bundle.listToJson(bundles),
      });
      await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('swiping shows a trash button but removes nothing', (
      tester,
    ) async {
      await openBundles(tester, [dinner, tea]);

      await slide(tester, 'Dinner');

      expect(trashFor('Dinner'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect((await BundleStore().load()).length, 2);
    });

    testWidgets('tapping the trash button removes the bundle and shows Undo', (
      tester,
    ) async {
      await openBundles(tester, [dinner, tea]);

      await slideAndDelete(tester, 'Dinner');

      expect(find.text('Dinner'), findsNothing);
      expect(find.text('Tea'), findsOneWidget);
      expect(find.text('Dinner deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('the removal is saved', (tester) async {
      await openBundles(tester, [dinner, tea]);

      await slideAndDelete(tester, 'Dinner');

      expect((await BundleStore().load()).map((b) => b.name), ['Tea']);
    });

    testWidgets('undo puts the bundle back in the same place', (tester) async {
      await openBundles(tester, [dinner, tea]);
      await slideAndDelete(tester, 'Dinner');

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Dinner'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Dinner')).dy,
        lessThan(tester.getTopLeft(find.text('Tea')).dy),
      );
      expect((await BundleStore().load()).map((b) => b.name), [
        'Dinner',
        'Tea',
      ]);
    });

    testWidgets('removing the last bundle shows the empty message', (
      tester,
    ) async {
      await openBundles(tester, [tea]);

      await slideAndDelete(tester, 'Tea');

      expect(find.textContaining('No bundles yet'), findsOneWidget);
    });

    testWidgets('tapping a bundle still chooses it', (tester) async {
      await openBundles(tester, [dinner]);

      await tester.tap(find.text('Dinner'));
      await tester.pumpAndSettle();

      expect(find.text('Dinner deleted'), findsNothing);
    });
  });
}
