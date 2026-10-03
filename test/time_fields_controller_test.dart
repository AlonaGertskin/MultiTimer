import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/time_fields.dart';

void main() {
  late TimeFieldsController controller;

  setUp(() => controller = TimeFieldsController());
  tearDown(() => controller.dispose());

  test('setting a total fills the fields with two digits', () {
    controller.totalSeconds = 3600 + 5 * 60 + 7;

    expect(controller.hours.text, '01');
    expect(controller.minutes.text, '05');
    expect(controller.seconds.text, '07');
  });

  test('zero parts are left empty', () {
    controller.totalSeconds = 90;

    expect(controller.hours.text, '');
    expect(controller.minutes.text, '01');
    expect(controller.seconds.text, '30');
  });

  test('the total is worked out from the fields', () {
    controller.hours.text = '01';
    controller.minutes.text = '5';
    controller.seconds.text = '07';

    expect(controller.totalSeconds, 3600 + 5 * 60 + 7);
  });

  test('empty fields count as zero', () {
    expect(controller.totalSeconds, 0);
  });

  test('clear empties every field', () {
    controller.totalSeconds = 125;

    controller.clear();

    expect(controller.totalSeconds, 0);
    expect(controller.minutes.text, '');
  });
}
