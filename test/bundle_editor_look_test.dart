import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/app_colors.dart';
import 'package:multitimer/bundle_editor_page.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/chain_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final bread = Bundle(
    name: 'Bread',
    items: const [
      BundleItem(title: 'Mix', seconds: 300, startsNext: true),
      BundleItem(title: 'Rise', seconds: 2700),
      BundleItem(title: 'Bake', seconds: 2100),
    ],
  );

  Future<void> openEditor(WidgetTester tester, BundleEditorPage page) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  Finder stepCards() => find.byType(Card);

  Finder number(int n) =>
      find.descendant(of: find.byType(CircleAvatar), matching: find.text('$n'));

  Finder linkRows() => find.ancestor(
    of: find.text('Start next automatically'),
    matching: find.byType(Row),
  );

  group('Steps', () {
    testWidgets('are numbered', (tester) async {
      await openEditor(tester, BundleEditorPage(editing: bread));

      for (final n in [1, 2, 3]) {
        expect(number(n), findsOneWidget);
      }
    });

    testWidgets('numbers follow the new order after reordering', (
      tester,
    ) async {
      await openEditor(tester, BundleEditorPage(editing: bread));

      final distance = tester.getSize(stepCards().first).height * 1.3;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_handle).first),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, distance / 10));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        tester.getCenter(find.text('Rise')).dy,
        lessThan(tester.getCenter(find.text('Mix')).dy),
      );
      expect(
        tester.getCenter(number(1)).dy,
        closeTo(tester.getCenter(find.text('Rise')).dy, 40),
      );
    });

    testWidgets('are compact', (tester) async {
      await openEditor(tester, BundleEditorPage(editing: bread));

      expect(tester.getSize(stepCards().first).height, lessThanOrEqualTo(130));
    });

    testWidgets('the time boxes keep their labels above them', (tester) async {
      await openEditor(tester, BundleEditorPage(editing: bread));

      final hours = tester.widget<TextField>(
        find.widgetWithText(TextField, 'HH').first,
      );
      expect(
        hours.decoration!.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
    });
  });

  group('Links', () {
    testWidgets('sit between the cards, none after the last step', (
      tester,
    ) async {
      await openEditor(tester, BundleEditorPage(editing: bread));

      expect(find.text('Start next automatically'), findsNWidgets(2));
      final cards = stepCards();
      final link = tester.getCenter(
        find.text('Start next automatically').first,
      );
      expect(link.dy, greaterThan(tester.getRect(cards.at(0)).bottom));
      expect(link.dy, lessThan(tester.getRect(cards.at(1)).top));
    });

    testWidgets('show an arrow when automatic and a pause sign when manual', (
      tester,
    ) async {
      await openEditor(tester, BundleEditorPage(editing: bread));

      expect(
        find.descendant(
          of: linkRows().at(0),
          matching: find.byIcon(Icons.arrow_downward),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: linkRows().at(1),
          matching: find.byIcon(Icons.pause),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();

      expect(
        find.descendant(
          of: linkRows().at(1),
          matching: find.byIcon(Icons.arrow_downward),
        ),
        findsOneWidget,
      );
    });
  });

  group('Chain mode', () {
    ChainModel dinner() => ChainModel(
      name: 'Dinner',
      steps: [
        ChainStep(title: 'Pasta', seconds: 600),
        ChainStep(title: 'Sauce', seconds: 900),
        ChainStep(title: 'Bread', seconds: 1200),
      ],
      currentIndex: 1,
    );

    testWidgets('the current step has the running colour', (tester) async {
      await openEditor(tester, BundleEditorPage(chain: dinner()));

      final colors = Theme.of(tester.element(find.text('Now'))).colorScheme;
      final current = tester.widget<Card>(
        find.ancestor(of: find.text('Now'), matching: find.byType(Card)),
      );
      expect(current.color, runningCardColor(colors));
    });

    testWidgets('a done step keeps the normal card colour', (tester) async {
      await openEditor(tester, BundleEditorPage(chain: dinner()));

      final done = tester.widget<Card>(
        find.ancestor(of: find.text('Done'), matching: find.byType(Card)),
      );
      expect(done.color, isNull);
    });
  });
}
