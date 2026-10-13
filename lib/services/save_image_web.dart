import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Hands the picture to the browser as a download.
///
/// There is no gallery to write to in a browser, so the save is the one the
/// browser already gives every page: a blob, a link pointed at it, and a
/// click. On the phone Chrome puts the file in Downloads and shows its own
/// notification, which is the confirmation the child's parent actually sees.
///
/// The object URL is revoked straight after the click. The download has
/// already been handed to the browser by then, and leaving it would pin the
/// certificate's bytes in memory for as long as the tab is open.
Future<void> saveImageBytes(Uint8List bytes, {required String name}) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
