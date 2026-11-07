import 'dart:async';

import 'package:e_tarabay/widgets/how_to_video.dart';

/// Runs before every test file. A how-to video that plays on a first visit
/// would open a player in the middle of a test's taps, so it is off here; a
/// test about the videos turns it back on itself.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  HowToVideo.autoPlay = false;
  await testMain();
}
