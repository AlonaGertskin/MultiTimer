import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/font_licence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Nunito licence file is an app asset', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('assets/fonts/Nunito-OFL.txt'),
    );
  });

  test('the Nunito licence is listed with the app\'s licences', () async {
    registerFontLicence();

    final licences = await LicenseRegistry.licenses.toList();
    final nunito = licences.where((l) => l.packages.contains('Nunito'));

    expect(nunito, isNotEmpty);
    expect(
      nunito.first.paragraphs.map((p) => p.text).join('\n'),
      contains('SIL OPEN FONT LICENSE'),
    );
  });
}
