import 'package:e_tarabay/services/device_performance.dart';
import 'package:e_tarabay/widgets/staggered_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A weak phone gets the lighter drawing, by its own numbers or by how it
/// keeps up; a capable one keeps everything.
void main() {
  group('a weak phone, by its numbers', () {
    bool weak({bool lowRam = false, int mem = 6144, int cores = 8}) =>
        DevicePerformance.isWeakDevice(
            lowRam: lowRam, totalMemMb: mem, cores: cores);

    test('Android calls it low-RAM', () => expect(weak(lowRam: true), isTrue));
    test('2 GB of memory', () => expect(weak(mem: 2048), isTrue));
    test('four cores', () => expect(weak(cores: 4), isTrue));
    test('a capable phone is not', () => expect(weak(), isFalse));
    test('3 GB and eight cores is not', () {
      expect(weak(mem: 3072, cores: 8), isFalse);
    });
  });

  group('a phone that cannot keep up, by its frames', () {
    const budget = 16667;
    List<int> frames(int slow, {int total = 180}) => [
          for (int i = 0; i < total; i++) i < slow ? 40000 : 9000,
        ];

    test('smooth drawing', () {
      expect(DevicePerformance.framesAreSlow(frames(0), budget), isFalse);
    });

    test('a slow frame now and then is not it', () {
      expect(DevicePerformance.framesAreSlow(frames(20), budget), isFalse);
    });

    test('a quarter of the frames late is', () {
      expect(DevicePerformance.framesAreSlow(frames(45), budget), isTrue);
    });

    test('too few frames to judge', () {
      expect(DevicePerformance.framesAreSlow(frames(60, total: 60), budget),
          isFalse);
    });
  });

  testWidgets('with animations off, a card is simply there', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: StaggeredEntrance(index: 5, child: Text('Bilang')),
      ),
    ));
    // No fade, no slide, no waiting for its turn.
    expect(find.byType(FadeTransition), findsNothing);
    expect(find.text('Bilang'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('with animations on, it still comes in', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: StaggeredEntrance(index: 1, child: Text('Bilang')),
      ),
    ));
    final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(fade.opacity.value, 0);
    // Its turn comes, then it plays.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(fade.opacity.value, 1);
  });
}
