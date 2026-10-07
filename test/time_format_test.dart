import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/time_format.dart';

void main() {
  group('formatSeconds (short form, used in bundle summaries)', () {
    test('shows M:SS under an hour', () {
      expect(formatSeconds(0), '0:00');
      expect(formatSeconds(65), '1:05');
      expect(formatSeconds(1500), '25:00');
    });

    test('shows H:MM:SS from an hour up', () {
      expect(formatSeconds(3600), '1:00:00');
      expect(formatSeconds(3725), '1:02:05');
    });
  });

  group('formatClock (full form, used on timer cards)', () {
    test('always shows HH:MM:SS', () {
      expect(formatClock(0), '00:00:00');
      expect(formatClock(1500), '00:25:00');
      expect(formatClock(3725), '01:02:05');
    });

    test('shows a minus sign for negative time', () {
      expect(formatClock(-8), '-00:00:08');
    });
  });
}
