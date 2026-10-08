import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/notification_service.dart';

void main() {
  const res = 'android/app/src/main/res';

  String read(String path) => File(path).readAsStringSync();

  test('the name under the icon is Multi-Timer', () {
    expect(
      read('android/app/src/main/AndroidManifest.xml'),
      contains('android:label="Multi-Timer"'),
    );
  });

  test('the launcher icon has a background, a drawing and a themed layer', () {
    final icon = read('$res/mipmap-anydpi-v26/ic_launcher.xml');

    expect(
      icon,
      contains('<background android:drawable="@color/ic_launcher_background"'),
    );
    expect(
      icon,
      contains(
        '<foreground android:drawable="@drawable/ic_launcher_foreground"',
      ),
    );
    expect(
      icon,
      contains(
        '<monochrome android:drawable="@drawable/ic_launcher_foreground"',
      ),
    );
    expect(File('$res/drawable/ic_launcher_foreground.xml').existsSync(), true);
    expect(
      read('$res/values/ic_launcher_background.xml'),
      contains('#FF65558F'),
    );
  });

  test('notifications use the white stopwatch icon', () {
    expect(NotificationService.androidIcon, '@drawable/ic_stat_timer');
    final colours = RegExp(
      r'android:(?:fill|stroke)Color="([^"]+)"',
    ).allMatches(read('$res/drawable/ic_stat_timer.xml'));
    expect(colours, isNotEmpty);
    expect(colours.map((m) => m.group(1)).toSet(), {'#FFFFFFFF'});
  });

  test('notifications are tinted with the launcher icon purple', () {
    expect(NotificationService.details.android?.color, const Color(0xFF65558F));
  });

  test('the notification icon is kept in release builds', () {
    expect(read('$res/raw/keep.xml'), contains('@drawable/ic_stat_timer'));
  });
}
