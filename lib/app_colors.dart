import 'package:flutter/material.dart';

final lightColors = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));

final darkColors = ColorScheme.fromSeed(
  seedColor: Color.lerp(Colors.teal, Colors.green, 0.25)!,
  brightness: Brightness.dark,
);

Color readyCardColor(ColorScheme colors) =>
    Color.lerp(colors.surfaceContainerHighest, colors.primaryContainer, 0.3)!;

Color runningCardColor(ColorScheme colors) =>
    Color.lerp(colors.primaryContainer, colors.primary, 0.25)!;

Color finishedCardColor(ColorScheme colors) => colors.primaryContainer;

Color progressTrackColor(ColorScheme colors) =>
    colors.primary.withValues(alpha: 0.25);

Color deleteButtonColor(ColorScheme colors) =>
    colors.brightness == Brightness.light
    ? Color.lerp(colors.errorContainer, colors.error, 0.2)!
    : colors.errorContainer;
