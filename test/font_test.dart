import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/app_colors.dart';
import 'package:multitimer/card_parts.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Nunito');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
        File(
          'assets/fonts/Nunito-$weight.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await loader.load();
  });

  for (final (name, theme) in [('light', lightTheme), ('dark', darkTheme)]) {
    test('$name: the theme uses Nunito', () {
      expect(theme.textTheme.bodyMedium!.fontFamily, 'Nunito');
      expect(theme.textTheme.titleMedium!.fontFamily, 'Nunito');
    });

    testWidgets('$name: every digit in the card time has the same width', (
      tester,
    ) async {
      Future<double> width(String text) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    Center(child: Text(text, style: cardTimeStyle(context))),
              ),
            ),
          ),
        );
        return tester.getSize(find.text(text)).width;
      }

      expect(
        await width('iiiiiiii'),
        lessThan(await width('WWWWWWWW')),
        reason: 'the real font is drawn, not the square test font',
      );

      final zeros = await width('00:00:00');
      for (var digit = 1; digit <= 9; digit++) {
        final d = '$digit$digit';
        expect(await width('$d:$d:$d'), zeros, reason: 'digit $digit');
      }
    });
  }
}
