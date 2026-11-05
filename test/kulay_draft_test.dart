import 'package:e_tarabay/providers/user_provider.dart';
import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A colouring page said "in progress", with colours on its card, and opened
/// empty — on a page the child had not touched. The unsaved draft had been
/// sent to the cloud with the real progress and merged back after the page
/// was saved or cleared, card picture and all.
void main() {
  group('drafts stay on the device', () {
    test('a page draft is not backed up', () {
      for (final part in ['strokes', 'preview', 'imageData', 'filledPixels']) {
        expect(UserProvider.isDeviceOnlyKey('kulay_autosave_123_Cat_$part'),
            isTrue,
            reason: part);
      }
    });

    test('real colouring progress still is', () {
      for (final key in [
        'kulay_page_Animals_0',
        'kulay_total_creations',
        'kulay_last_colored',
        'mat_level_0_game_1',
      ]) {
        expect(UserProvider.isDeviceOnlyKey(key), isFalse, reason: key);
      }
    });
  });

  group('a draft counts as in progress only with something on it', () {
    const key = 'kulay_autosave_123_Cat';

    Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferences.getInstance();
    }

    test('a card picture alone is not', () async {
      final prefs = await prefsWith({'${key}_preview': 'iVBORw0KGgo='});
      expect(kulayDraftHasContent(prefs, key), isFalse);
    });

    test('no strokes and no fill is not', () async {
      final prefs = await prefsWith({
        '${key}_strokes': '[]',
        '${key}_filledPixels': 0,
        '${key}_preview': 'iVBORw0KGgo=',
      });
      expect(kulayDraftHasContent(prefs, key), isFalse);
    });

    test('a stroke is', () async {
      final prefs = await prefsWith({
        '${key}_strokes': '[{"points":[]}]',
      });
      expect(kulayDraftHasContent(prefs, key), isTrue);
    });

    test('a fill with its picture is', () async {
      final prefs = await prefsWith({
        '${key}_strokes': '[]',
        '${key}_filledPixels': 120,
        '${key}_imageData': 'iVBORw0KGgo=',
      });
      expect(kulayDraftHasContent(prefs, key), isTrue);
    });

    test('a fill count without its picture is not', () async {
      final prefs = await prefsWith({
        '${key}_strokes': '[]',
        '${key}_filledPixels': 120,
      });
      expect(kulayDraftHasContent(prefs, key), isFalse);
    });
  });
}
