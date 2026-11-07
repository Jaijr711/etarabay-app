import 'package:e_tarabay/services/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the update opens the website, told which version is installed', () {
    expect(UpdateChecker.updatePageUrl('1.2.56'),
        'https://jaijr711.github.io/etarabay-releases/?v=1.2.56');
  });
}
