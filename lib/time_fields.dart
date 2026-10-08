import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'max_value_formatter.dart';

class TimeFieldsController {
  final TextEditingController hours = TextEditingController();
  final TextEditingController minutes = TextEditingController();
  final TextEditingController seconds = TextEditingController();
  final FocusNode hoursFocus = FocusNode();
  final FocusNode minutesFocus = FocusNode();
  final FocusNode secondsFocus = FocusNode();

  TimeFieldsController() {
    _padWhenLeft(hours, hoursFocus);
    _padWhenLeft(minutes, minutesFocus);
    _padWhenLeft(seconds, secondsFocus);
  }

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
    hoursFocus.dispose();
    minutesFocus.dispose();
    secondsFocus.dispose();
    hours.dispose();
    minutes.dispose();
    seconds.dispose();
  }

  static void _padWhenLeft(TextEditingController controller, FocusNode focus) {
    focus.addListener(() {
      if (!focus.hasFocus && controller.text.length == 1) {
        controller.text = controller.text.padLeft(2, '0');
      }
    });
  }

  static int _value(TextEditingController controller) =>
      int.tryParse(controller.text) ?? 0;

  static String _digits(int value) =>
      value == 0 ? '' : value.toString().padLeft(2, '0');
}

class TimeFields extends StatelessWidget {
  final TimeFieldsController controller;
  final TextInputAction lastAction;
  final bool compact;

  const TimeFields({
    super.key,
    required this.controller,
    this.lastAction = TextInputAction.done,
    this.compact = false,
  });

  Widget _field(
    BuildContext context,
    TextEditingController textController,
    FocusNode focusNode,
    String label, {
    int? max,
    bool isLast = false,
  }) {
    return Expanded(
      child: TextField(
        controller: textController,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          isDense: compact,
          floatingLabelBehavior:
              compact ? FloatingLabelBehavior.always : null,
        ),
        keyboardType: TextInputType.number,
        textInputAction: isLast ? lastAction : TextInputAction.next,
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
        _field(context, controller.hours, controller.hoursFocus, 'HH'),
        const Text(' : '),
        _field(context, controller.minutes, controller.minutesFocus, 'MM',
            max: 59),
        const Text(' : '),
        _field(context, controller.seconds, controller.secondsFocus, 'SS',
            max: 59, isLast: true),
      ],
    );
  }
}
