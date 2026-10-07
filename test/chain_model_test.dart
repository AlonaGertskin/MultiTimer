import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/chain_model.dart';

void main() {
  late DateTime fakeNow;

  setUp(() => fakeNow = DateTime(2026, 1, 1, 12));

  void pass(ChainModel chain, int seconds) {
    fakeNow = fakeNow.add(Duration(seconds: seconds));
    chain.syncWithClock();
  }

  // A (60s, starts B by itself), B (120s, manual), C (30s, last)
  ChainModel newChain({List<ChainStep>? steps}) => ChainModel(
        name: 'Dinner',
        steps:
            steps ??
            [
              ChainStep(title: 'A', seconds: 60, startsNext: true),
              ChainStep(title: 'B', seconds: 120),
              ChainStep(title: 'C', seconds: 30),
            ],
        now: () => fakeNow,
      );

  group('Starting', () {
    test('a new chain waits ready on its first step', () {
      final chain = newChain();

      expect(chain.currentIndex, 0);
      expect(chain.currentStep.title, 'A');
      expect(chain.remainingSeconds, 60);
      expect(chain.isRunning, false);
    });

    test('start counts down the current step', () {
      final chain = newChain();

      chain.start(() {});
      pass(chain, 20);

      expect(chain.isRunning, true);
      expect(chain.remainingSeconds, 40);
      chain.pause();
    });

    test('pause keeps the time and start carries on from it', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 20);
      chain.pause();

      pass(chain, 100);
      expect(chain.isRunning, false);
      expect(chain.remainingSeconds, 40);

      chain.start(() {});
      pass(chain, 10);
      expect(chain.remainingSeconds, 30);
      chain.pause();
    });

    test('reset step restarts only the current step', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 70);
      expect(chain.currentIndex, 1);

      chain.resetStep();

      expect(chain.currentIndex, 1);
      expect(chain.remainingSeconds, 120);
      expect(chain.isRunning, false);
    });

    testWidgets('ticks once per second and calls back', (tester) async {
      final chain = newChain();
      var ticks = 0;

      chain.start(() => ticks++);
      for (var i = 0; i < 3; i++) {
        fakeNow = fakeNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }

      expect(ticks, 3);
      expect(chain.remainingSeconds, 57);
      chain.pause();
    });
  });

  group('Automatic link', () {
    test('the next step starts by itself when a step ends', () {
      final chain = newChain();
      chain.start(() {});

      pass(chain, 60);

      expect(chain.currentIndex, 1);
      expect(chain.isRunning, true);
      expect(chain.remainingSeconds, 120);
      chain.pause();
    });

    test('time carries over exactly when the screen was late', () {
      final chain = newChain();
      chain.start(() {});

      pass(chain, 65);

      expect(chain.currentIndex, 1);
      expect(chain.remainingSeconds, 115);
      chain.pause();
    });

    test('several automatic steps can pass at once', () {
      final chain = newChain(
        steps: [
          ChainStep(title: 'A', seconds: 60, startsNext: true),
          ChainStep(title: 'B', seconds: 120, startsNext: true),
          ChainStep(title: 'C', seconds: 30),
        ],
      );
      chain.start(() {});

      pass(chain, 190);

      expect(chain.currentIndex, 2);
      expect(chain.remainingSeconds, 20);
      chain.pause();
    });

    test('stops at a manual link and counts into negative time', () {
      final chain = newChain();
      chain.start(() {});

      pass(chain, 500);

      expect(chain.currentIndex, 1);
      expect(chain.remainingSeconds, 120 - 440);
      expect(chain.isWaitingForContinue, true);
      expect(chain.isComplete, false);
      chain.pause();
    });

    test('is not waiting while the step still has time', () {
      final chain = newChain();
      chain.start(() {});

      pass(chain, 100);

      expect(chain.isWaitingForContinue, false);
      chain.pause();
    });

    test('the last step finishing means the chain is complete', () {
      final chain = newChain(
        steps: [
          ChainStep(title: 'A', seconds: 10),
          ChainStep(title: 'B', seconds: 10),
        ],
      );
      chain.start(() {});
      pass(chain, 10);
      chain.continueToNext(() {});

      pass(chain, 15);

      expect(chain.currentIndex, 1);
      expect(chain.isComplete, true);
      expect(chain.isWaitingForContinue, false);
      expect(chain.remainingSeconds, -5);
      chain.pause();
    });
  });

  group('Continue', () {
    ChainModel waitingAtB() {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 60 + 120 + 30);
      return chain;
    }

    test('starts the next step right away, from now', () {
      final chain = waitingAtB();
      expect(chain.isWaitingForContinue, true);

      chain.continueToNext(() {});

      expect(chain.currentIndex, 2);
      expect(chain.isRunning, true);
      expect(chain.remainingSeconds, 30);
      expect(chain.endTime, fakeNow.add(const Duration(seconds: 30)));
      chain.pause();
    });

    test('does nothing when the step is not finished', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 100);

      chain.continueToNext(() {});

      expect(chain.currentIndex, 1);
      expect(chain.remainingSeconds, 80);
      chain.pause();
    });
  });

  group('Skip', () {
    test('after an automatic link the next step starts', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 10);

      chain.skip(() {});

      expect(chain.currentIndex, 1);
      expect(chain.isRunning, true);
      expect(chain.remainingSeconds, 120);
      chain.pause();
    });

    test('after a manual link the next step is ready and waits', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 70);

      chain.skip(() {});

      expect(chain.currentIndex, 2);
      expect(chain.isRunning, false);
      expect(chain.endTime, isNull);
      expect(chain.remainingSeconds, 30);
    });

    test('works on a step that is not running', () {
      final chain = newChain();

      chain.skip(() {});

      expect(chain.currentIndex, 1);
      expect(chain.isRunning, true);
      chain.pause();
    });

    test('skips a finished step that was waiting for Continue', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 250);
      expect(chain.isWaitingForContinue, true);

      chain.skip(() {});

      expect(chain.currentIndex, 2);
      expect(chain.isRunning, false);
      expect(chain.remainingSeconds, 30);
    });

    test('does nothing on the last step', () {
      final chain = newChain();
      chain.skip(() {});
      chain.pause();
      chain.skip(() {});
      expect(chain.currentIndex, 2);

      chain.skip(() {});

      expect(chain.currentIndex, 2);
    });
  });

  group('Restart whole chain', () {
    test('goes back to a ready first step', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 250);

      chain.restartChain();

      expect(chain.currentIndex, 0);
      expect(chain.remainingSeconds, 60);
      expect(chain.isRunning, false);
      expect(chain.endTime, isNull);
    });
  });

  group('Deleting the current step', () {
    test('the next step becomes current and waits ready', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 10);

      final removed = chain.deleteCurrentStep();

      expect(removed, true);
      expect(chain.steps.map((s) => s.title), ['B', 'C']);
      expect(chain.currentIndex, 0);
      expect(chain.currentStep.title, 'B');
      expect(chain.isRunning, false);
      expect(chain.remainingSeconds, 120);
    });

    test('deleting the last step makes the one before it current', () {
      final chain = newChain();
      chain.skip(() {});
      chain.pause();
      chain.skip(() {});
      expect(chain.currentStep.title, 'C');

      chain.deleteCurrentStep();

      expect(chain.steps.map((s) => s.title), ['A', 'B']);
      expect(chain.currentStep.title, 'B');
      expect(chain.remainingSeconds, 120);
      expect(chain.isRunning, false);
    });

    test('the last remaining step cannot be deleted', () {
      final chain = newChain(steps: [ChainStep(title: 'A', seconds: 10)]);

      final removed = chain.deleteCurrentStep();

      expect(removed, false);
      expect(chain.steps.length, 1);
    });
  });

  group('Saving and loading', () {
    test('a chain survives a round trip', () {
      final chain = newChain();
      chain.skip(() {});
      chain.pause();
      chain.name = 'Supper';

      final copy = ChainModel.fromMap(
        jsonDecode(jsonEncode(chain.toMap())) as Map<String, dynamic>,
        now: () => fakeNow,
      );

      expect(copy.id, chain.id);
      expect(copy.name, 'Supper');
      expect(copy.currentIndex, 1);
      expect(copy.remainingSeconds, 120);
      expect(copy.isRunning, false);
      expect(copy.steps.map((s) => s.title), ['A', 'B', 'C']);
      expect(copy.steps.map((s) => s.seconds), [60, 120, 30]);
      expect(copy.steps.map((s) => s.startsNext), [true, false, false]);
      expect(copy.steps.map((s) => s.id), chain.steps.map((s) => s.id));
    });

    test('a running chain catches up on the time it spent closed', () {
      final chain = newChain();
      chain.start(() {});
      pass(chain, 10);
      final saved = jsonDecode(jsonEncode(chain.toMap())) as Map<String, dynamic>;
      chain.pause();

      fakeNow = fakeNow.add(const Duration(seconds: 100));
      final copy = ChainModel.fromMap(saved, now: () => fakeNow);

      expect(copy.isRunning, true);
      expect(copy.currentIndex, 1);
      expect(copy.remainingSeconds, 120 - 50);
      copy.pause();
    });

    test('the chain is marked with its type', () {
      expect(newChain().toMap()['type'], 'chain');
    });

    test('a missing link setting means manual', () {
      final map = newChain().toMap();
      for (final step in map['steps'] as List) {
        (step as Map<String, dynamic>).remove('startsNext');
      }

      final copy = ChainModel.fromMap(map);

      expect(copy.steps.map((s) => s.startsNext), [false, false, false]);
    });

    test('a chain without steps is refused', () {
      final map = newChain().toMap()..['steps'] = [];

      expect(() => ChainModel.fromMap(map), throwsA(anything));
    });

    test('a current step outside the list is refused', () {
      final map = newChain().toMap()..['currentIndex'] = 3;

      expect(() => ChainModel.fromMap(map), throwsA(anything));
    });

    test('a step with no time is refused', () {
      final map = newChain().toMap();
      ((map['steps'] as List).first as Map<String, dynamic>)['seconds'] = 0;

      expect(() => ChainModel.fromMap(map), throwsA(anything));
    });

    test('a chain saved as running without an end time loads as paused', () {
      final map = newChain().toMap()
        ..['isRunning'] = true
        ..['endTime'] = null;

      final copy = ChainModel.fromMap(map);

      expect(copy.isRunning, false);
    });
  });
}
