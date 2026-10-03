import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/timer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    final saved = jsonEncode([
      for (final title in ['First', 'Second', 'Third'])
        TimerModel(title: title, remainingSeconds: 60).toMap(),
    ]);
    SharedPreferences.setMockInitialValues({'saved_timers': saved});
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
    await tester.pumpAndSettle();
  }

  List<String> shownOrder(WidgetTester tester) {
    final titles = ['First', 'Second', 'Third'];
    titles.sort((a, b) => tester
        .getTopLeft(find.text(a))
        .dy
        .compareTo(tester.getTopLeft(find.text(b)).dy));
    return titles;
  }

  Future<void> dragDown(WidgetTester tester, String title, double distance) async {
    final gesture = await tester.startGesture(tester.getCenter(find.text(title)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, distance / 10));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('timers load in their saved order', (tester) async {
    await openPage(tester);

    expect(shownOrder(tester), ['First', 'Second', 'Third']);
  });

  testWidgets('dragging a timer down moves it and saves the new order',
      (tester) async {
    await openPage(tester);

    await dragDown(tester, 'First', 160);

    expect(shownOrder(tester), ['Second', 'First', 'Third']);

    final prefs = await SharedPreferences.getInstance();
    final saved = (jsonDecode(prefs.getString('saved_timers')!) as List)
        .map((item) => item['title']);
    expect(saved, ['Second', 'First', 'Third']);
  });

  group('reorder mode', () {
    testWidgets('the button shows and hides the drag handles', (tester) async {
      await openPage(tester);
      expect(find.byIcon(Icons.drag_handle), findsNothing);

      await tester.tap(find.byTooltip('Reorder timers'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));

      await tester.tap(find.byTooltip('Done reordering'));
      await tester.pump();
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('a handle drags right away, without holding', (tester) async {
      await openPage(tester);
      await tester.tap(find.byTooltip('Reorder timers'));
      await tester.pumpAndSettle();

      final gesture = await tester
          .startGesture(tester.getCenter(find.byIcon(Icons.drag_handle).first));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 16));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(shownOrder(tester), ['Second', 'First', 'Third']);
    });

    testWidgets('holding and dragging still works in reorder mode',
        (tester) async {
      await openPage(tester);
      await tester.tap(find.byTooltip('Reorder timers'));
      await tester.pumpAndSettle();

      await dragDown(tester, 'First', 160);

      expect(shownOrder(tester), ['Second', 'First', 'Third']);
    });
  });

  testWidgets('a reordered list loads in the new order', (tester) async {
    await openPage(tester);
    await dragDown(tester, 'First', 160);

    await tester.pumpWidget(const SizedBox());
    await openPage(tester);

    expect(shownOrder(tester), ['Second', 'First', 'Third']);
  });
}
