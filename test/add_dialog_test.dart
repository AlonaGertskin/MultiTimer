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

      expect(textIn(tester, 'MM'), '8');
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

      expect(textIn(tester, 'SS'), '8');
      expect(tester.testTextInput.isVisible, false);
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
