import 'dart:typed_data';

import 'package:gal/gal.dart';

/// Writes the picture into the device gallery, where the family's photos are.
///
/// Throws on failure — the caller shows the message, the same as before.
Future<void> saveImageBytes(Uint8List bytes, {required String name}) =>
    Gal.putImageBytes(bytes, name: name);
