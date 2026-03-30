import 'dart:async'; //contains the Timer class
import 'timer_card.dart';

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

  void start(Function onTick) {
    isRunning = true;
    internalTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        onTick(); // Tell the UI to refresh
      } else {
        stop();
        onTick();
      }
    });
  }

  void stop() {
    internalTimer?.cancel();
    isRunning = false;
  }

// Move reset logic here
  void reset() {
    stop();
    remainingSeconds = initialSeconds;
  }

}

