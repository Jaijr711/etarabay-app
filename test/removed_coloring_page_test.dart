import 'package:e_tarabay/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the soda can is gone for good', () {
    test('a creation colored on it is removed', () {
      expect(
          UserProvider.isRemovedColoringCreation(
              {'name': 'Soda', 'sourcePagePath': 'assets/images/paint9.png'}),
          isTrue);
    });

    test('one saved before creations named their page, by its name', () {
      expect(
          UserProvider.isRemovedColoringCreation(
              {'name': 'Soda Pop', 'sourcePagePath': ''}),
          isTrue);
    });

    test('every other page is kept', () {
      for (final path in [
        'assets/images/paint8.png',
        'assets/images/paint_racecar.png',
        'assets/images/paint1.png',
      ]) {
        expect(
            UserProvider.isRemovedColoringCreation(
                {'name': 'Anything', 'sourcePagePath': path}),
            isFalse);
      }
    });

    test('a page named like it but recorded elsewhere is kept', () {
      expect(
          UserProvider.isRemovedColoringCreation(
              {'name': 'Soda', 'sourcePagePath': 'assets/images/paint8.png'}),
          isFalse);
    });
  });
}
