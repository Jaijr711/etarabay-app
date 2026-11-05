import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> creation(int date, String page, {bool full = false}) => {
      'name': page,
      'date': date,
      'sourcePagePath': page,
      'base64Image': 'small',
      if (full) 'strokes': [1, 2, 3],
    };

void main() {
  group('the drawings go to the cloud only when they change', () {
    final one = creation(5, 'assets/images/paint1.png');
    const sig = UserProvider.creationsSignature;

    test('the same drawings give the same signature', () {
      expect(sig([Map.of(one)]), sig([Map.of(one)]));
    });

    test('an update, a new rating or a deletion changes it', () {
      expect(sig([one]), isNot(sig([creation(9, 'assets/images/paint1.png')])));
      expect(
          sig([one]),
          isNot(sig([
            {...one, 'stars': 3}
          ])));
      expect(sig([one]), isNot(sig([])));
    });
  });

  group('the drawings as they go to the cloud', () {
    test('one per page, the newest, so a re-colored page leaves room', () {
      final out = UserProvider.creationsForCloud([
        for (var d = 1; d <= 20; d++) creation(d, 'assets/images/paint1.png'),
        creation(0, 'assets/images/paint2.png'),
      ]);
      expect(out.map((c) => c['date']), [20, 0]);
    });

    test('only the small picture and its page go, never the strokes', () {
      final out = UserProvider.creationsForCloud(
          [creation(5, 'assets/images/paint1.png', full: true)]);
      expect(out.single.containsKey('strokes'), isFalse);
      expect(out.single['base64Image'], 'small');
    });

    test('at most fifteen', () {
      final out = UserProvider.creationsForCloud([
        for (var d = 1; d <= 30; d++) creation(d, 'assets/images/page$d.png'),
      ]);
      expect(out, hasLength(15));
      expect(out.first['date'], 30);
    });
  });

  group('creations restored at sign-in', () {
    test("this phone's full copy is kept, not replaced by the cloud's", () {
      final merged = UserProvider.mergeRestoredCreations(
        [creation(5, 'assets/images/paint1.png', full: true)],
        [creation(5, 'assets/images/paint1.png')],
      );
      expect(merged, hasLength(1));
      expect((merged.single as Map)['strokes'], [1, 2, 3]);
    });

    test('an updated drawing does not bring its older version back', () {
      final merged = UserProvider.mergeRestoredCreations(
        [creation(9, 'assets/images/paint1.png', full: true)],
        [creation(5, 'assets/images/paint1.png')],
      );
      expect(merged.map((c) => (c as Map)['date']), [9]);
    });

    test("another phone's page this phone has none of is added", () {
      final merged = UserProvider.mergeRestoredCreations(
        [creation(9, 'assets/images/paint1.png', full: true)],
        [creation(7, 'assets/images/paint2.png')],
      );
      expect(merged.map((c) => (c as Map)['date']), [9, 7]);
    });

    test('a new phone gets everything from the cloud', () {
      final merged = UserProvider.mergeRestoredCreations(null, [
        creation(1, 'assets/images/paint1.png'),
        creation(2, 'assets/images/paint2.png'),
      ]);
      expect(merged, hasLength(2));
    });

    test('a page the app no longer has stays out', () {
      final merged = UserProvider.mergeRestoredCreations(
          [], [creation(1, 'assets/images/paint9.png')]);
      expect(merged, isEmpty);
    });
  });
}
