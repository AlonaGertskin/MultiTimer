import 'dart:async';
import 'id_generator.dart';
import 'list_item.dart';

class ChainStep {
  final int id;
  final String title;
  final int seconds;
  final bool startsNext;

  ChainStep({
    int? id,
    required this.title,
    required this.seconds,
    this.startsNext = false,
  }) : id = id ?? newId();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'seconds': seconds,
      'startsNext': startsNext,
    };
  }

  factory ChainStep.fromMap(Map<String, dynamic> map) {
    final seconds = map['seconds'] as int;
    if (seconds <= 0) {
      throw const FormatException('A chain step needs a time above zero');
    }
    return ChainStep(
      id: map['id'] as int?,
      title: map['title'] as String,
      seconds: seconds,
      startsNext: map['startsNext'] as bool? ?? false,
    );
  }
}

class ChainAlert {
  final int id;
  final String title;
  final String body;
  final DateTime when;

  const ChainAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });
}

class ChainModel implements ListItem {
  @override
  final int id;
  String name;
  final List<ChainStep> steps;
  int currentIndex;
  int remainingSeconds;
  @override
  bool isRunning;
  @override
  DateTime? endTime;
  @override
  Timer? internalTimer;
  final DateTime Function() _now;

  ChainModel({
    int? id,
    required this.name,
    required List<ChainStep> steps,
    this.currentIndex = 0,
    int? remainingSeconds,
    this.isRunning = false,
    this.endTime,
    DateTime Function()? now,
  }) : id = id ?? newId(),
       steps = List.of(steps),
       remainingSeconds = remainingSeconds ?? steps[currentIndex].seconds,
       _now = now ?? DateTime.now;

  ChainStep get currentStep => steps[currentIndex];

  bool get isLastStep => currentIndex == steps.length - 1;

  bool get _isStepFinished => isRunning && remainingSeconds <= 0;

  bool get isWaitingForContinue => _isStepFinished && !isLastStep;

  bool get isComplete => _isStepFinished && isLastStep;

  @override
  void syncWithClock() {
    var end = endTime;
    if (end == null) return;
    final now = _now();
    while (isRunning &&
        currentStep.startsNext &&
        !isLastStep &&
        !end!.isAfter(now)) {
      currentIndex++;
      end = end.add(Duration(seconds: currentStep.seconds));
      endTime = end;
    }
    remainingSeconds = (end!.difference(now).inMilliseconds / 1000).round();
  }

  List<ChainAlert> upcomingAlerts() {
    final alerts = <ChainAlert>[];
    var end = endTime;
    if (!isRunning || end == null) return alerts;
    final now = _now();

    for (var i = currentIndex; i < steps.length; i++) {
      final step = steps[i];
      final isLast = i == steps.length - 1;
      if (end!.isAfter(now)) {
        alerts.add(
          ChainAlert(
            id: step.id,
            title: isLast ? '$name complete' : '${step.title} finished',
            body: isLast
                ? '${step.title} finished'
                : step.startsNext
                ? '$name: ${steps[i + 1].title} started'
                : '$name: tap Continue to start ${steps[i + 1].title}',
            when: end,
          ),
        );
      }
      if (isLast || !step.startsNext) break;
      end = end.add(Duration(seconds: steps[i + 1].seconds));
    }
    return alerts;
  }

  void start(Function onTick) {
    if (isRunning && internalTimer != null) return;

    isRunning = true;
    endTime = _now().add(Duration(seconds: remainingSeconds));
    _startTicking(onTick);
  }

  void resume(DateTime end, Function onTick) {
    _stop();
    isRunning = true;
    endTime = end;
    syncWithClock();
    _startTicking(onTick);
  }

  void _startTicking(Function onTick) {
    internalTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      syncWithClock();
      onTick();
    });
  }

  void pause() {
    _stop();
  }

  void resetStep() {
    _stop();
    remainingSeconds = currentStep.seconds;
  }

  void skip(Function onTick) {
    if (isLastStep) return;
    final startNext = currentStep.startsNext;
    _moveToNextStep();
    if (startNext) start(onTick);
  }

  void continueToNext(Function onTick) {
    if (!isWaitingForContinue) return;
    _moveToNextStep();
    start(onTick);
  }

  void restartChain() {
    _stop();
    currentIndex = 0;
    remainingSeconds = currentStep.seconds;
  }

  bool deleteCurrentStep() {
    if (steps.length <= 1) return false;
    _stop();
    steps.removeAt(currentIndex);
    if (currentIndex >= steps.length) currentIndex = steps.length - 1;
    remainingSeconds = currentStep.seconds;
    return true;
  }

  void _moveToNextStep() {
    _stop();
    currentIndex++;
    remainingSeconds = currentStep.seconds;
  }

  void _stop() {
    internalTimer?.cancel();
    internalTimer = null;
    isRunning = false;
    endTime = null;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'chain',
      'id': id,
      'name': name,
      'steps': steps.map((step) => step.toMap()).toList(),
      'currentIndex': currentIndex,
      'remainingSeconds': remainingSeconds,
      'isRunning': isRunning,
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory ChainModel.fromMap(
    Map<String, dynamic> map, {
    DateTime Function()? now,
  }) {
    final steps = (map['steps'] as List)
        .map((step) => ChainStep.fromMap(step as Map<String, dynamic>))
        .toList();
    if (steps.isEmpty) {
      throw const FormatException('A chain needs at least one step');
    }
    final index = map['currentIndex'] as int;
    if (index < 0 || index >= steps.length) {
      throw const FormatException('The current step is not in the chain');
    }
    final end = map['endTime'] != null
        ? DateTime.parse(map['endTime'] as String)
        : null;
    final running = (map['isRunning'] as bool? ?? false) && end != null;

    final chain = ChainModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      steps: steps,
      currentIndex: index,
      remainingSeconds: map['remainingSeconds'] as int?,
      isRunning: running,
      endTime: running ? end : null,
      now: now,
    );
    if (running) chain.syncWithClock();
    return chain;
  }
}
