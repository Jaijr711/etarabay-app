import 'package:e_tarabay/services/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's update button opens the download website and says which
/// version is installed, so the page can offer Update rather than Install.
void main() {
  test('the page is told the installed version', () {
    expect(UpdateChecker.updatePageUrl('1.2.55'),
        'https://jaijr711.github.io/etarabay-releases/?v=1.2.55');
  });

  test('the page is the published website', () {
    expect(UpdateChecker.downloadPageUrl,
        startsWith('https://jaijr711.github.io/etarabay-releases/'));
  });

  test('an odd version cannot break the address', () {
    final uri = Uri.parse(UpdateChecker.updatePageUrl('1.2.55 &x=1'));
    expect(uri.queryParameters, {'v': '1.2.55 &x=1'});
  });
}
