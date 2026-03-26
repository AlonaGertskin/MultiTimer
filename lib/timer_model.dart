import 'dart:async'; //contains the Timer class

class TimerModel {
  String title;
  int remainingSeconds;
  bool isRunning;
  Timer? internalTimer; // like a pointer to the process

  TimerModel({
    required this.title,
    required this.remainingSeconds,
    this.isRunning = false, // Default to 'not running'
  });
}