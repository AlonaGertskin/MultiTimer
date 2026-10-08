import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/app_colors.dart';
import 'package:multitimer/bundle_model.dart';
import 'package:multitimer/bundles_page.dart';
import 'package:multitimer/chain_card.dart';
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

  Bundle? chosen;

  Future<void> openBundles(WidgetTester tester, List<Bundle> bundles) async {
    chosen = null;
    SharedPreferences.setMockInitialValues({
      'saved_bundles': Bundle.listToJson(bundles),
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              chosen = await Navigator.push<Bundle>(
                context,
                MaterialPageRoute(builder: (_) => const BundlesPage()),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder cardOf(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(Card));

  Finder inCard(String name, Finder matching) =>
      find.descendant(of: cardOf(name), matching: matching);

  group('A bundle card', () {
    testWidgets('each bundle is a card in the ready colour', (tester) async {
      await openBundles(tester, [dinner, tea]);

      final colors = Theme.of(tester.element(find.text('Dinner'))).colorScheme;
      final cards = tester.widgetList<Card>(find.byType(Card));
      expect(cards, hasLength(2));
      for (final card in cards) {
        expect(card.color, readyCardColor(colors));
      }
    });

    testWidgets('several timers: chain icon, step names and a preview strip', (
      tester,
    ) async {
      await openBundles(tester, [dinner]);

      expect(inCard('Dinner', find.byIcon(Icons.link)), findsOneWidget);
      expect(find.text('Pasta · Sauce · Bread'), findsOneWidget);
      expect(inCard('Dinner', find.byType(ChainProgressStrip)), findsOneWidget);
      final gaps = inCard(
        'Dinner',
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key as ValueKey<String>).value.startsWith('manual-gap'),
        ),
      );
      expect(gaps, findsOneWidget);
    });

    testWidgets('one timer: timer icon, no step names, a one-piece strip', (
      tester,
    ) async {
      await openBundles(tester, [tea]);

      expect(inCard('Tea', find.byIcon(Icons.timer_outlined)), findsOneWidget);
      expect(find.text('Steep'), findsNothing);
      expect(inCard('Tea', find.byType(ChainProgressStrip)), findsOneWidget);
      expect(inCard('Tea', find.byType(FractionallySizedBox)), findsOneWidget);
    });

    testWidgets('keeps its summary', (tester) async {
      await openBundles(tester, [dinner, tea]);

      expect(find.text('3 timers · 45:00 total'), findsOneWidget);
      expect(find.text('1 timer · 3:00 total'), findsOneWidget);
    });

    testWidgets('has an Add button instead of the list icon', (tester) async {
      await openBundles(tester, [dinner]);

      expect(inCard('Dinner', find.text('Add')), findsOneWidget);
      expect(find.byIcon(Icons.playlist_add), findsNothing);
    });
  });

  group('Adding a bundle', () {
    testWidgets('the Add button chooses the bundle', (tester) async {
      await openBundles(tester, [dinner, tea]);

      await tester.tap(inCard('Tea', find.text('Add')));
      await tester.pumpAndSettle();

      expect(find.byType(BundlesPage), findsNothing);
      expect(chosen?.name, 'Tea');
    });

    testWidgets('tapping the card itself adds nothing', (tester) async {
      await openBundles(tester, [dinner]);

      await tester.tap(find.text('Dinner'));
      await tester.pumpAndSettle();

      expect(find.byType(BundlesPage), findsOneWidget);
      expect(chosen, isNull);
    });

    testWidgets('edit mode hides Add and the pencil', (tester) async {
      await openBundles(tester, [dinner]);

      await tester.tap(find.byTooltip('Edit list'));
      await tester.pumpAndSettle();

      expect(find.text('Add'), findsNothing);
      expect(find.byTooltip('Edit bundle'), findsNothing);
    });
  });
}
