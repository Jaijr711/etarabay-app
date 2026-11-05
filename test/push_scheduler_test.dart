import 'package:e_tarabay/services/push_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // testWidgets for its fake clock: timers run as the test pumps time.
  testWidgets('a burst of changes is one push, once things settle',
      (tester) async {
    int pushes = 0;
    final s = PushScheduler(() async => pushes++);
    for (int i = 0; i < 10; i++) {
      s.schedule();
      await tester.pump(const Duration(seconds: 2));
    }
    expect(pushes, 0, reason: 'still busy: nothing sent yet');
    await tester.pump(const Duration(seconds: 21));
    expect(pushes, 1);
    expect(s.pending, isFalse);
  });

  testWidgets('a child who never stops still syncs every minute',
      (tester) async {
    int pushes = 0;
    final s = PushScheduler(() async => pushes++);
    for (int i = 0; i < 70; i++) {
      s.schedule();
      await tester.pump(const Duration(seconds: 2));
    }
    expect(pushes, 2, reason: '140 busy seconds, pushed at 60 and 120');
    s.dispose();
  });

  testWidgets('flush sends what is waiting at once, and nothing twice',
      (tester) async {
    int pushes = 0;
    final s = PushScheduler(() async => pushes++);
    s.schedule();
    await s.flush();
    expect(pushes, 1);
    await tester.pump(const Duration(minutes: 2));
    expect(pushes, 1, reason: 'the timers were cancelled by the flush');
    await s.flush();
    expect(pushes, 1, reason: 'nothing waiting, nothing sent');
    await s.flush(force: true);
    expect(pushes, 2);
  });
}
