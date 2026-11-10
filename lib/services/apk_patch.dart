import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:crypto/crypto.dart';

/// Builds a new APK from the installed one and a small patch, so an update
/// downloads a few MB instead of the whole 117 MB.
///
/// The patches are made at each release by `tool/make_patches.py`
/// (bsdiff, its three blocks compressed with zlib). Measured on real
/// releases: 1.2.58 → 1.2.59 was 5 MB, 1.2.59 → 1.2.60 under 2 MB.
///
/// Everything streams: the old APK is read where the patch points, the new
/// one written in order, so memory stays small on the weakest phone.
class ApkPatch {
  static const magic = 'ETPATCH1';
  static const _chunk = 1 << 20;

  /// Writes the new APK to [outPath]. Throws [FormatException] on a patch
  /// that is not one, or does not fit; the caller checks the result's hash.
  static Future<void> apply(
      String oldPath, String patchPath, String outPath) async {
    final patch = File(patchPath);
    final total = await patch.length();
    final head = await _readHead(patch);
    if (String.fromCharCodes(head.sublist(0, 8)) != magic) {
      throw const FormatException('not an update patch');
    }
    final h = ByteData.sublistView(head);
    final ctrlLen = h.getInt64(8, Endian.little);
    final diffLen = h.getInt64(16, Endian.little);
    final newSize = h.getInt64(24, Endian.little);
    if (ctrlLen < 0 || diffLen < 0 || newSize < 0 ||
        32 + ctrlLen + diffLen > total) {
      throw const FormatException('broken update patch');
    }
    ChunkedStreamReader<int> block(int start, int end) =>
        ChunkedStreamReader(zlib.decoder.bind(patch.openRead(start, end)));
    final ctrl = block(32, 32 + ctrlLen);
    final diff = block(32 + ctrlLen, 32 + ctrlLen + diffLen);
    final extra = block(32 + ctrlLen + diffLen, total);

    final old = await File(oldPath).open();
    final oldLen = await old.length();
    final out = File(outPath).openWrite();
    try {
      var newPos = 0, oldPos = 0;
      Future<Uint8List> exactly(ChunkedStreamReader<int> r, int n) async {
        final b = await r.readBytes(n);
        if (b.length != n) throw const FormatException('short update patch');
        return b;
      }

      while (newPos < newSize) {
        final c = await exactly(ctrl, 24);
        final x = _offtin(c, 0), y = _offtin(c, 8), z = _offtin(c, 16);
        if (x < 0 || y < 0 || newPos + x + y > newSize) {
          throw const FormatException('broken update patch');
        }
        // x bytes: the patch's difference added to the old APK's bytes.
        for (var left = x; left > 0;) {
          final n = min(left, _chunk);
          final d = Uint8List.fromList(await exactly(diff, n));
          final lo = max(oldPos, 0), hi = min(oldPos + n, oldLen);
          if (hi > lo) {
            final o = Uint8List(hi - lo);
            await old.setPosition(lo);
            await old.readInto(o);
            final at = lo - oldPos;
            for (var i = 0; i < o.length; i++) {
              d[at + i] = (d[at + i] + o[i]) & 0xFF;
            }
          }
          out.add(d);
          oldPos += n;
          left -= n;
        }
        newPos += x;
        // y bytes: new, taken as they are.
        for (var left = y; left > 0;) {
          final n = min(left, _chunk);
          out.add(await exactly(extra, n));
          left -= n;
        }
        newPos += y;
        oldPos += z;
      }
    } finally {
      await out.flush();
      await out.close();
      await old.close();
      await ctrl.cancel();
      await diff.cancel();
      await extra.cancel();
    }
  }

  /// The file's SHA-256, in hex, read in pieces.
  static Future<String> sha256Of(String path) async =>
      (await sha256.bind(File(path).openRead()).first).toString();

  static Future<Uint8List> _readHead(File f) async {
    final raf = await f.open();
    try {
      final b = await raf.read(32);
      if (b.length != 32) throw const FormatException('short update patch');
      return b;
    } finally {
      await raf.close();
    }
  }

  /// bsdiff's 8-byte number: little-endian, the top bit the sign.
  static int _offtin(Uint8List b, int o) {
    var y = b[o + 7] & 0x7F;
    for (var i = 6; i >= 0; i--) {
      y = y * 256 + b[o + i];
    }
    return (b[o + 7] & 0x80) != 0 ? -y : y;
  }
}
