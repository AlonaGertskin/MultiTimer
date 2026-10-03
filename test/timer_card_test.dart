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
    test('always shows HH:MM:SS, even under an hour', () {
      expect(card.formatTime(0), '00:00:00');
      expect(card.formatTime(5), '00:00:05');
      expect(card.formatTime(65), '00:01:05');
      expect(card.formatTime(3599), '00:59:59');
    });

    test('pads every part to two digits', () {
      expect(card.formatTime(3600), '01:00:00');
      expect(card.formatTime(3725), '01:02:05');
      expect(card.formatTime(3600 + 5 * 60 + 6), '01:05:06');
      expect(card.formatTime(36000), '10:00:00');
    });

    test('puts a minus sign in front of negative time', () {
      expect(card.formatTime(-1), '-00:00:01');
      expect(card.formatTime(-65), '-00:01:05');
      expect(card.formatTime(-3661), '-01:01:01');
    });

    test('shows the time on the card', () {
      expect(card.formatTime(card.timer.remainingSeconds), '00:00:00');
    });
  });
}
