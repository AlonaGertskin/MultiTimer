import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/app_colors.dart';

void main() {
  double hue(Color color) => HSLColor.fromColor(color).hue;

  double brightness(Color color) => color.computeLuminance();

  for (final (name, colors) in [('light', lightColors), ('dark', darkColors)]) {
    test('$name: every card colour has the hue of the main colour', () {
      for (final card in [
        readyCardColor(colors),
        runningCardColor(colors),
        finishedCardColor(colors),
      ]) {
        expect(hue(card), closeTo(hue(colors.primary), 15));
      }
    });
  }

  double saturation(Color color) => HSLColor.fromColor(color).saturation;

  test('dark: ready is darkest, finished in the middle, running brightest', () {
    final ready = brightness(readyCardColor(darkColors));
    final finished = brightness(finishedCardColor(darkColors));
    final running = brightness(runningCardColor(darkColors));
    expect(ready, lessThan(finished));
    expect(finished, lessThan(running));
  });

  test('light: running is the deepest colour', () {
    final running = brightness(runningCardColor(lightColors));
    expect(running, lessThan(brightness(readyCardColor(lightColors))));
    expect(running, lessThan(brightness(finishedCardColor(lightColors))));
  });

  test('light: finished is more colourful than ready', () {
    expect(
      saturation(finishedCardColor(lightColors)),
      greaterThan(saturation(readyCardColor(lightColors))),
    );
  });
}
