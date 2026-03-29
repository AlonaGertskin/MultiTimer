import 'dart:async'; //contains the Timer class

class TimerModel {
  String title;
  int remainingSeconds;
  bool isRunning;
  int initialSeconds;
  Timer? internalTimer; // like a pointer to the process

  TimerModel({
    required this.title,
    required this.remainingSeconds,
    this.isRunning = false,
  }) : initialSeconds = remainingSeconds;
}