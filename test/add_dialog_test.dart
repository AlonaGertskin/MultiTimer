import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openAddDialog(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyMainPage()));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  String textIn(WidgetTester tester, String label) =>
      tester.widget<TextField>(field(label)).controller!.text;

  group('Add dialog text fields', () {
    testWidgets('the title starts with a capital letter automatically',
        (tester) async {
      await openAddDialog(tester);

      final title = tester.widget<TextField>(field('Timer Title'));

      expect(title.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('the next key on the title moves to hours', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('Timer Title'), 'Tea');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      tester.testTextInput.enterText('02');
      await tester.pump();

      expect(textIn(tester, 'HH'), '02');
      expect(textIn(tester, 'Timer Title'), 'Tea');
    });

    testWidgets('hours and minutes show next, seconds shows done',
        (tester) async {
      await openAddDialog(tester);

      expect(tester.widget<TextField>(field('HH')).textInputAction,
          TextInputAction.next);
      expect(tester.widget<TextField>(field('MM')).textInputAction,
          TextInputAction.next);
      expect(tester.widget<TextField>(field('SS')).textInputAction,
          TextInputAction.done);
    });
  });

  group('Add dialog time fields', () {
    testWidgets('a full hours field moves on to minutes', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('HH'), '01');
      await tester.pump();
      tester.testTextInput.enterText('30');
      await tester.pump();

      expect(textIn(tester, 'HH'), '01');
      expect(textIn(tester, 'MM'), '30');
    });

    testWidgets('a full minutes field moves on to seconds', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('MM'), '05');
      await tester.pump();
      tester.testTextInput.enterText('45');
      await tester.pump();

      expect(textIn(tester, 'MM'), '05');
      expect(textIn(tester, 'SS'), '45');
    });

    testWidgets('a field with one digit stays where it is', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('HH'), '1');
      await tester.pump();
      tester.testTextInput.enterText('12');
      await tester.pump();

      expect(textIn(tester, 'HH'), '12');
      expect(textIn(tester, 'MM'), '');
    });

    testWidgets('a single digit above 5 is a complete minutes value',
        (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('MM'), '8');
      await tester.pump();
      tester.testTextInput.enterText('30');
      await tester.pump();

      expect(textIn(tester, 'MM'), '08');
      expect(textIn(tester, 'SS'), '30');
    });

    testWidgets('a single digit up to 5 waits for a second digit',
        (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('MM'), '5');
      await tester.pump();
      tester.testTextInput.enterText('55');
      await tester.pump();

      expect(textIn(tester, 'MM'), '55');
      expect(textIn(tester, 'SS'), '');
    });

    testWidgets('a single digit above 5 in seconds closes the keyboard',
        (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('SS'), '8');
      await tester.pump();

      expect(textIn(tester, 'SS'), '08');
      expect(tester.testTextInput.isVisible, false);
    });

    testWidgets('a single digit is completed to two digits when you leave',
        (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('MM'), '5');
      await tester.pump();
      expect(textIn(tester, 'MM'), '5');

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(textIn(tester, 'MM'), '05');
    });

    testWidgets('a single digit is completed when you tap another field',
        (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('HH'), '1');
      await tester.enterText(field('SS'), '3');
      await tester.pump();

      expect(textIn(tester, 'HH'), '01');
      expect(textIn(tester, 'SS'), '3');
    });

    testWidgets('a zero is completed to 00 but an empty field stays empty',
        (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('HH'), '0');
      await tester.enterText(field('MM'), '');
      await tester.enterText(field('SS'), '5');
      await tester.pump();

      expect(textIn(tester, 'HH'), '00');
      expect(textIn(tester, 'MM'), '');
    });

    testWidgets('two digits are left as they are', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('HH'), '12');
      await tester.enterText(field('SS'), '5');
      await tester.pump();

      expect(textIn(tester, 'HH'), '12');
    });

    testWidgets('a single digit above 5 in hours does not move on',
        (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('HH'), '8');
      await tester.pump();
      tester.testTextInput.enterText('12');
      await tester.pump();

      expect(textIn(tester, 'HH'), '12');
      expect(textIn(tester, 'MM'), '');
    });

    testWidgets('a full seconds field closes the keyboard', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('SS'), '30');
      await tester.pump();

      expect(tester.testTextInput.isVisible, false);
    });

    testWidgets('minutes and seconds are limited to 59', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('MM'), '75');
      await tester.pump();
      await tester.enterText(field('SS'), '99');
      await tester.pump();

      expect(textIn(tester, 'MM'), '59');
      expect(textIn(tester, 'SS'), '59');
    });

    testWidgets('hours are not limited to 59', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('HH'), '75');
      await tester.pump();

      expect(textIn(tester, 'HH'), '75');
    });

    testWidgets('fields accept at most two digits', (tester) async {
      await openAddDialog(tester);

      await tester.enterText(field('MM'), '123');
      await tester.pump();

      expect(textIn(tester, 'MM'), '12');
    });
  });
}
