import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/bundles_page.dart';
import 'package:multitimer/home_page.dart';
import 'package:multitimer/timer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder field(String label) => find.widgetWithText(TextField, label);
  final askDialog = find.text('Discard changes?');

  String textIn(WidgetTester tester, String label) =>
      tester.widget<TextField>(field(label)).controller!.text;

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  group('Bundle editor', () {
    Future<void> openEditor(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BundlesPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New bundle'));
      await tester.pumpAndSettle();
    }

    Future<void> pressBack(WidgetTester tester) async {
      await tester.tap(find.byType(BackButton));
      await settle(tester);
    }

    testWidgets('leaves without asking when nothing was entered',
        (tester) async {
      await openEditor(tester);

      await pressBack(tester);

      expect(askDialog, findsNothing);
      expect(find.text('New Bundle'), findsNothing);
    });

    testWidgets('asks before leaving with a name typed', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');

      await pressBack(tester);

      expect(askDialog, findsOneWidget);
      expect(find.text('New Bundle'), findsOneWidget);
    });

    testWidgets('asks before leaving with a timer entered', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Timer name'), 'Pasta');

      await pressBack(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('asks before leaving with only a time entered',
        (tester) async {
      await openEditor(tester);
      await tester.enterText(field('MM'), '10');

      await pressBack(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('asks before leaving after adding a timer', (tester) async {
      await openEditor(tester);
      await tester.tap(find.text('Add timer'));
      await tester.pump();

      await pressBack(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('does not ask if what was typed was erased again',
        (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await tester.enterText(field('Bundle name'), '');

      await pressBack(tester);

      expect(askDialog, findsNothing);
      expect(find.text('New Bundle'), findsNothing);
    });

    testWidgets('keep editing stays in the editor with everything intact',
        (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await pressBack(tester);

      await tester.tap(find.text('Keep editing'));
      await settle(tester);

      expect(askDialog, findsNothing);
      expect(textIn(tester, 'Bundle name'), 'Dinner');
    });

    testWidgets('discard leaves and saves nothing', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await pressBack(tester);

      await tester.tap(find.text('Discard'));
      await settle(tester);

      expect(find.text('New Bundle'), findsNothing);
      expect(find.text('Dinner'), findsNothing);
      expect(find.textContaining('No bundles yet'), findsOneWidget);
    });

    testWidgets('the phone back button asks too', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('saving does not ask', (tester) async {
      await openEditor(tester);
      await tester.enterText(field('Bundle name'), 'Dinner');
      await tester.enterText(field('Timer name'), 'Pasta');
      await tester.enterText(field('MM'), '10');

      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(askDialog, findsNothing);
      expect(find.text('Dinner'), findsOneWidget);
    });
  });

  group('Add timer dialog', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
    }

    Future<void> tapOutside(WidgetTester tester) async {
      await tester.tapAt(const Offset(5, 5));
      await settle(tester);
    }

    testWidgets('closes without asking when nothing was entered',
        (tester) async {
      await openDialog(tester);

      await tapOutside(tester);

      expect(askDialog, findsNothing);
      expect(find.text('Add New Timer'), findsNothing);
    });

    testWidgets('asks when tapping outside with a title typed',
        (tester) async {
      await openDialog(tester);
      await tester.enterText(field('Timer Title'), 'Tea');

      await tapOutside(tester);

      expect(askDialog, findsOneWidget);
      expect(find.text('Add New Timer'), findsOneWidget);
    });

    testWidgets('asks when only a time was typed', (tester) async {
      await openDialog(tester);
      await tester.enterText(field('MM'), '5');

      await tapOutside(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('the phone back button asks too', (tester) async {
      await openDialog(tester);
      await tester.enterText(field('Timer Title'), 'Tea');

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('keep editing leaves the dialog and its text as they were',
        (tester) async {
      await openDialog(tester);
      await tester.enterText(field('Timer Title'), 'Tea');
      await tapOutside(tester);

      await tester.tap(find.text('Keep editing'));
      await settle(tester);

      expect(askDialog, findsNothing);
      expect(textIn(tester, 'Timer Title'), 'Tea');
    });

    testWidgets('discard closes the dialog and the next one starts empty',
        (tester) async {
      await openDialog(tester);
      await tester.enterText(field('Timer Title'), 'Tea');
      await tapOutside(tester);

      await tester.tap(find.text('Discard'));
      await settle(tester);
      expect(find.text('Add New Timer'), findsNothing);

      await tester.tap(find.byIcon(Icons.add));
      await settle(tester);
      expect(textIn(tester, 'Timer Title'), '');
    });

    testWidgets('the Cancel button never asks', (tester) async {
      await openDialog(tester);
      await tester.enterText(field('Timer Title'), 'Tea');

      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(askDialog, findsNothing);
      expect(find.text('Add New Timer'), findsNothing);
    });
  });

  group('Edit timer dialog', () {
    setUp(() {
      final saved = jsonEncode([
        TimerModel(title: 'Tea', remainingSeconds: 90).toMap(),
      ]);
      SharedPreferences.setMockInitialValues({'saved_timers': saved});
    });

    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
    }

    Future<void> tapOutside(WidgetTester tester) async {
      await tester.tapAt(const Offset(5, 5));
      await settle(tester);
    }

    testWidgets('closes without asking when nothing was changed',
        (tester) async {
      await openDialog(tester);
      expect(textIn(tester, 'Timer Title'), 'Tea');

      await tapOutside(tester);

      expect(askDialog, findsNothing);
      expect(find.text('Edit Timer'), findsNothing);
    });

    testWidgets('asks when the name was changed', (tester) async {
      await openDialog(tester);
      await tester.enterText(field('Timer Title'), 'Green tea');

      await tapOutside(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('asks when the time was changed', (tester) async {
      await openDialog(tester);
      await tester.enterText(field('MM'), '05');

      await tapOutside(tester);

      expect(askDialog, findsOneWidget);
    });

    testWidgets('does not ask if the change was put back', (tester) async {
      await openDialog(tester);
      await tester.enterText(field('Timer Title'), 'Green tea');
      await tester.enterText(field('Timer Title'), 'Tea');

      await tapOutside(tester);

      expect(askDialog, findsNothing);
      expect(find.text('Edit Timer'), findsNothing);
    });

    testWidgets('discard leaves the timer as it was', (tester) async {
      await openDialog(tester);
      await tester.enterText(field('Timer Title'), 'Green tea');
      await tapOutside(tester);

      await tester.tap(find.text('Discard'));
      await settle(tester);

      expect(find.text('Edit Timer'), findsNothing);
      expect(find.text('Tea'), findsOneWidget);
      expect(find.text('Green tea'), findsNothing);
    });
  });
}
