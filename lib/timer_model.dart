class TimerModel {
  String title;
  int remainingSeconds;
  bool isRunning;

  TimerModel({
    required this.title,
    required this.remainingSeconds,
    this.isRunning = false, // Default to 'not running'
  });
}