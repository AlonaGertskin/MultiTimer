import 'package:flutter/material.dart';

TextStyle cardTimeStyle(BuildContext context) => TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: Theme.of(context).colorScheme.onSurface,
  fontFeatures: const [FontFeature.tabularFigures()],
);
