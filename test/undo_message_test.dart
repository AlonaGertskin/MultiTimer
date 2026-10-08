import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/swipe_to_delete.dart';

void main() {
  Future<void> showMessage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showUndoSnackBar(context, 'Tea deleted', () {}),
              child: const Text('delete'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
  }

  testWidgets('the Undo message shows with its button', (tester) async {
    await showMessage(tester);

    expect(find.text('Tea deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('the Undo message goes away by itself after a few seconds', (
    tester,
  ) async {
    await showMessage(tester);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Tea deleted'), findsNothing);
    expect(find.text('Undo'), findsNothing);
  });
}
