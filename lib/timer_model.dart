import 'dart:async'; //contains the Timer class

class TimerModel {
  String title;
  int remainingSeconds;
  int initialSeconds;
  bool isRunning;
  Timer? internalTimer; // like a pointer to the process

  TimerModel({
    required this.title,
    required this.remainingSeconds,
    this.isRunning = false,
  }) : initialSeconds = remainingSeconds;
}