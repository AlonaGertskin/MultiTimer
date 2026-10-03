import 'dart:async';
import 'dart:convert';

class TimerModel {
  String title;
  int remainingSeconds;
  int initialSeconds;
  bool isRunning;
  DateTime? endTime;
  Timer? internalTimer;
  final DateTime Function() _now;

  TimerModel({
    required this.title,
    required this.remainingSeconds,
    this.isRunning = false,
    this.endTime,
    DateTime Function()? now,
  })  : initialSeconds = remainingSeconds,
        _now = now ?? DateTime.now;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'initialSeconds': initialSeconds,
      'remainingSeconds': remainingSeconds,
      'isRunning': isRunning,
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory TimerModel.fromMap(Map<String, dynamic> map,
      {DateTime Function()? now}) {
    bool running = map['isRunning'] ?? false;
    int remaining = map['remainingSeconds'] ?? map['initialSeconds'];
    DateTime? end = map['endTime'] != null ? DateTime.parse(map['endTime']) : null;

    final timer = TimerModel(
      title: map['title'],
      remainingSeconds: remaining,
      isRunning: running,
      endTime: end,
      now: now,
    )..initialSeconds = map['initialSeconds'];

    if (running && end != null) timer.syncWithClock();
    return timer;
  }

  static List<TimerModel> listFromJson(String json, {DateTime Function()? now}) {
    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(json) as List<dynamic>;
    } catch (_) {
      return [];
    }

    final timers = <TimerModel>[];
    for (final item in decoded) {
      try {
        timers.add(TimerModel.fromMap(item as Map<String, dynamic>, now: now));
      } catch (_) {
        continue;
      }
    }
    return timers;
  }

  void syncWithClock() {
    final end = endTime;
    if (end == null) return;
    remainingSeconds = (end.difference(_now()).inMilliseconds / 1000).round();
  }

  void start(Function onTick) {
    if (isRunning && internalTimer != null) return;

    isRunning = true;
    endTime = _now().add(Duration(seconds: remainingSeconds));

    internalTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      syncWithClock();
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
