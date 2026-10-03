import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'max_value_formatter.dart';

class TimeFieldsController {
  final TextEditingController hours = TextEditingController();
  final TextEditingController minutes = TextEditingController();
  final TextEditingController seconds = TextEditingController();

  int get totalSeconds =>
      (_value(hours) * 3600) + (_value(minutes) * 60) + _value(seconds);

  set totalSeconds(int total) {
    hours.text = _digits(total ~/ 3600);
    minutes.text = _digits(total % 3600 ~/ 60);
    seconds.text = _digits(total % 60);
  }

  void clear() {
    hours.clear();
    minutes.clear();
    seconds.clear();
  }

  void dispose() {
    hours.dispose();
    minutes.dispose();
    seconds.dispose();
  }

  static int _value(TextEditingController controller) =>
      int.tryParse(controller.text) ?? 0;

  static String _digits(int value) => value == 0 ? '' : value.toString();
}

class TimeFields extends StatelessWidget {
  final TimeFieldsController controller;

  const TimeFields({super.key, required this.controller});

  Widget _field(
    BuildContext context,
    TextEditingController textController,
    String label, {
    int? max,
    bool isLast = false,
  }) {
    return Expanded(
      child: TextField(
        controller: textController,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
          if (max != null) MaxValueFormatter(max),
        ],
        onChanged: (value) {
          final isFull = value.length >= 2 ||
              (max != null && value.isNotEmpty && int.parse(value) * 10 > max);
          if (!isFull) return;
          if (isLast) {
            FocusScope.of(context).unfocus();
          } else {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _field(context, controller.hours, 'HH'),
        const Text(' : '),
        _field(context, controller.minutes, 'MM', max: 59),
        const Text(' : '),
        _field(context, controller.seconds, 'SS', max: 59, isLast: true),
      ],
    );
  }
}
