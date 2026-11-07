import 'package:e_tarabay/screens/kulay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Palakihin brings the spot to the middle', () {
    final m = kulayZoomToward(const Offset(150, 150), 300, 2);
    expect(MatrixUtils.transformPoint(m, const Offset(150, 150)),
        const Offset(150, 150));
  });

  test('Palakihin never slides the picture off its edges', () {
    // A corner: the picture's own corner stays at the canvas corner.
    final m = kulayZoomToward(Offset.zero, 300, 2.2);
    expect(MatrixUtils.transformPoint(m, Offset.zero), Offset.zero);
    final far = kulayZoomToward(const Offset(300, 300), 300, 2.2);
    expect(
        (MatrixUtils.transformPoint(far, const Offset(300, 300)) -
                const Offset(300, 300))
            .distance,
        lessThan(1e-6));
  });

  test('at scale 1 nothing moves', () {
    final m = kulayZoomToward(const Offset(40, 220), 300, 1);
    expect(MatrixUtils.transformPoint(m, const Offset(40, 220)),
        const Offset(40, 220));
  });
}
