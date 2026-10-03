String formatSeconds(int totalSeconds) {
  bool isNegative = totalSeconds < 0;
  int absSeconds = totalSeconds.abs();

  int hours = absSeconds ~/ 3600;
  int minutes = (absSeconds % 3600) ~/ 60;
  int seconds = absSeconds % 60;

  String m = minutes.toString().padLeft(2, '0');
  String s = seconds.toString().padLeft(2, '0');
  String prefix = isNegative ? '-' : '';

  if (hours > 0) {
    return '$prefix$hours:$m:$s';
  } else {
    return '$prefix$minutes:$s';
  }
}
