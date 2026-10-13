/// Saving a picture the child made, on whichever platform they are using.
///
/// The Save button on a certificate called `Gal.putImageBytes` directly, and
/// `gal` has no web implementation at all — it is not in the generated web
/// plugin registrant. On the phone that means the call throws
/// `MissingPluginException`, the surrounding catch swallows it, and the child
/// is shown "could not save" every single time they press Save. The button
/// has never once worked on the platform this app is actually run on.
///
/// So the save is chosen at compile time instead: the phone keeps the gallery
/// write, and the browser gets the browser's own download. Both are a real
/// save, and neither screen has to know which one it got.
library;

export 'save_image_io.dart' if (dart.library.js_interop) 'save_image_web.dart';
