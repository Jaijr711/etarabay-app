import 'dart:io';

import 'package:e_tarabay/services/apk_patch.dart';
import 'package:flutter_test/flutter_test.dart';

/// A patch made by tool/make_patches.py rebuilds the new file exactly from
/// the old one; anything that is not a patch is refused.
void main() {
  const fx = 'test/fixtures/apk_patch';
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('patch'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('rebuilds the new file byte for byte', () async {
    final out = '${tmp.path}/out.bin';
    await ApkPatch.apply('$fx/old.bin', '$fx/old-to-new.patch', out);
    expect(File(out).readAsBytesSync(), File('$fx/new.bin').readAsBytesSync());
    expect(await ApkPatch.sha256Of(out), await ApkPatch.sha256Of('$fx/new.bin'));
  });

  test('a file that is not a patch is refused', () async {
    await expectLater(
        ApkPatch.apply('$fx/old.bin', '$fx/new.bin', '${tmp.path}/x'),
        throwsA(isA<FormatException>()));
  });

  test('a patch cut short is refused', () async {
    final bytes = File('$fx/old-to-new.patch').readAsBytesSync();
    final cut = File('${tmp.path}/cut.patch')
      ..writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
    await expectLater(
        ApkPatch.apply('$fx/old.bin', cut.path, '${tmp.path}/x'),
        throwsA(anything));
  });

  // The real thing, when the release APKs are at hand (ET_PATCH_DIR holds
  // E-Tarabay-1.2.59.apk, E-Tarabay-1.2.60.apk and the patch between).
  final dir = Platform.environment['ET_PATCH_DIR'];
  test('rebuilds the real v1.2.60 from v1.2.59', () async {
    final out = '${tmp.path}/1.2.60.apk';
    final watch = Stopwatch()..start();
    await ApkPatch.apply('$dir/E-Tarabay-1.2.59.apk',
        '$dir/E-Tarabay-1.2.59-to-1.2.60.patch', out);
    // ignore: avoid_print
    print('built in ${watch.elapsed.inMilliseconds} ms');
    expect(await ApkPatch.sha256Of(out),
        '6f741569e6fd7084c779f544dadad8df87b98626419814d9e8fa52ddf3555ac4');
  }, skip: dir == null ? 'ET_PATCH_DIR not set' : false,
      timeout: const Timeout(Duration(minutes: 5)));
}
