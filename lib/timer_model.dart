import 'dart:async';

class TimerModel {
  String title;
  int remainingSeconds;
  int initialSeconds;
  bool isRunning;
  DateTime? endTime;
  Timer? internalTimer;

  TimerModel({
    required this.title,
    required this.remainingSeconds,
    this.isRunning = false,
    this.endTime,
  }) : initialSeconds = remainingSeconds;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'initialSeconds': initialSeconds,
      'remainingSeconds': remainingSeconds,
      'isRunning': isRunning,
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory TimerModel.fromMap(Map<String, dynamic> map) {
    bool running = map['isRunning'] ?? false;
    int remaining = map['remainingSeconds'] ?? map['initialSeconds'];
    DateTime? end = map['endTime'] != null ? DateTime.parse(map['endTime']) : null;

    if (running && end != null) {
      remaining = end.difference(DateTime.now()).inSeconds;
    }

    return TimerModel(
      title: map['title'],
      remainingSeconds: remaining,
      isRunning: running,
      endTime: end,
    )..initialSeconds = map['initialSeconds'];
  }

  void start(Function onTick) {
    if (isRunning && internalTimer != null) return;

    isRunning = true;
    endTime = DateTime.now().add(Duration(seconds: remainingSeconds));
    
    internalTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      remainingSeconds--;
      onTick();
    });
  }

  void stop() {
    internalTimer?.cancel();
    internalTimer = null;
    isRunning = false;
    endTime = null;
  }

  void reset() {
    stop();
    remainingSeconds = initialSeconds;
  }
}
