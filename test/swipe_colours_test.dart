import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/app_colors.dart';
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

  Future<void> openWith(WidgetTester tester, ThemeData theme) async {
    SharedPreferences.setMockInitialValues({
      'saved_timers': jsonEncode([
        TimerModel(title: 'Tea', remainingSeconds: 60).toMap(),
        ChainModel(
          name: 'Dinner',
          steps: [
            ChainStep(title: 'Pasta', seconds: 600),
            ChainStep(title: 'Sauce', seconds: 900),
          ],
        ).toMap(),
      ]),
    });
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const MyMainPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color? buttonColour(WidgetTester tester, IconData icon) {
    final box = tester.widget<Container>(
      find
          .ancestor(of: find.byIcon(icon), matching: find.byType(Container))
          .first,
    );
    return (box.decoration as BoxDecoration).color;
  }

  Color? iconColour(WidgetTester tester, IconData icon) =>
      tester.widget<Icon>(find.byIcon(icon)).color;

  for (final (name, colors, theme) in [
    ('light', lightColors, lightTheme),
    ('dark', darkColors, darkTheme),
  ]) {
    testWidgets('$name: delete uses the theme\'s soft red', (tester) async {
      await openWith(tester, theme);

      await tester.drag(find.text('Tea'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(
        buttonColour(tester, Icons.delete_outline),
        deleteButtonColor(colors),
      );
      expect(iconColour(tester, Icons.delete_outline), colors.onErrorContainer);
    });

    testWidgets('$name: restart uses the theme\'s main colour', (tester) async {
      await openWith(tester, theme);

      await tester.drag(
        find.text('Dinner · step 1 of 2'),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();

      expect(buttonColour(tester, Icons.restart_alt), colors.primary);
      expect(iconColour(tester, Icons.restart_alt), colors.onPrimary);
    });
  }
}
