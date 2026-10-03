import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/timer_card.dart';
import 'package:multitimer/timer_model.dart';

void main() {
  final card = TimerCard(
    timer: TimerModel(title: 'Tea', remainingSeconds: 0),
    onStart: () {},
    onPause: () {},
    onReset: () {},
    onEdit: () {},
    onDelete: () {},
  );

  group('TimerCard.formatTime', () {
    test('shows M:SS under an hour', () {
      expect(card.formatTime(0), '0:00');
      expect(card.formatTime(5), '0:05');
      expect(card.formatTime(65), '1:05');
      expect(card.formatTime(3599), '59:59');
    });

    test('shows H:MM:SS from an hour up', () {
      expect(card.formatTime(3600), '1:00:00');
      expect(card.formatTime(3725), '1:02:05');
      expect(card.formatTime(36000), '10:00:00');
    });

    test('puts a minus sign in front of negative time', () {
      expect(card.formatTime(-1), '-0:01');
      expect(card.formatTime(-65), '-1:05');
      expect(card.formatTime(-3661), '-1:01:01');
    });
  });
}
