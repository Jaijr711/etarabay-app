import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:e_tarabay/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two phones on one child's account both keep what they finished, a
/// teacher's reset of one module stays reset, and a picture colored over
/// and over stops growing.
void main() {
  group('a push sends key by key', () {
    Map<String, Object?> sent(Map<Object, Object?> updates) => {
          for (final e in updates.entries)
            (e.key as FieldPath).components.join('/'): e.value,
        };

    test('only what differs from the cloud', () {
      final out = sent(UserProvider.rawProgressUpdates(
        {'kulay_page_Animals_0': true, 'mat_level_0_stars': 3},
        {'kulay_page_Animals_0': true, 'mat_level_0_stars': 2},
      ));
      expect(out, {'rawProgress/mat_level_0_stars': 3});
    });

    test("never removes what another phone sent", () {
      // The cloud holds a page this phone has not seen; nothing here
      // deletes or replaces it.
      final out = sent(UserProvider.rawProgressUpdates(
        {'kulay_page_Animals_0': true},
        {'kulay_page_Animals_0': true, 'kulay_page_Toys_1': true},
      ));
      expect(out, isEmpty);
    });

    test('old drafts the cloud still holds are deleted', () {
      final out = sent(UserProvider.rawProgressUpdates(
        const {},
        {'kulay_autosave_123_Cat_preview': 'iVBOR'},
      ));
      expect(out.keys, ['rawProgress/kulay_autosave_123_Cat_preview']);
      expect(out.values.single, isA<FieldValue>());
    });

    test('with no cloud copy to compare, every key goes, one by one', () {
      final out = sent(UserProvider.rawProgressUpdates(
        {
          'a_1': true,
          'matematika_levels': [true, false]
        },
        null,
      ));
      expect(out.keys.toSet(),
          {'rawProgress/a_1', 'rawProgress/matematika_levels'});
    });
  });

  group("a teacher's reset of one module", () {
    const raw = {
      'kulay_page_Animals_0': true,
      'kulay_starred_Animals_0': true,
      'kulay_total': 1,
      'kanta_activity_0': true,
      'mat_level_0_stars': 3,
      'matematika_levels': [true],
    };

    test('takes every raw record of that module, and only that', () {
      expect(AuthService.moduleRawKeys(raw, ['kulay']).toSet(), {
        'kulay_page_Animals_0',
        'kulay_starred_Animals_0',
        'kulay_total',
      });
      expect(AuthService.moduleRawKeys(raw, ['matematika']).toSet(),
          {'mat_level_0_stars', 'matematika_levels'});
    });

    test('nothing when the record has none', () {
      expect(AuthService.moduleRawKeys(null, ['kulay']), isEmpty);
    });
  });

  group('a picture colored over and over', () {
    ColoringStroke stroke(int points) => ColoringStroke(
          points: List.generate(points, (i) => Offset(i.toDouble(), 0)),
          color: Colors.red,
          size: 12,
        );

    test('keeps its strokes up to the limit', () {
      expect(
          kulayNeedsBake(List.generate(kulayBakeMaxStrokes, (_) => stroke(10))),
          isFalse);
    });

    test('folds them in past too many strokes or points', () {
      expect(
          kulayNeedsBake(
              List.generate(kulayBakeMaxStrokes + 1, (_) => stroke(2))),
          isTrue);
      expect(kulayNeedsBake([stroke(kulayBakeMaxPoints + 1)]), isTrue);
    });
  });
}
