import 'dart:math' as math;
import 'dart:ui';

/// Builds a smooth path through [pts] by rounding each interior corner with a
/// short quadratic curve of at most [cornerRadius] design-space units.
///
/// - Dense point runs (curves like C, O, S) round fully and look hand-drawn.
/// - Long straight segments meeting at a corner (L, V, Z, 7) keep their shape
///   and get only a gentle radius, so letterforms stay true to the alphabet.
///
/// NaN points act as stroke separators (same convention as the tracing data).
Path smoothPolylinePath(List<Offset> pts, {double cornerRadius = 14}) {
  final path = Path();
  final segment = <Offset>[];

  void flush() {
    if (segment.isEmpty) return;
    path.moveTo(segment[0].dx, segment[0].dy);
    if (segment.length == 1) {
      // Single point: dot handled by the caller's round stroke cap.
      path.lineTo(segment[0].dx, segment[0].dy);
    } else if (segment.length == 2) {
      path.lineTo(segment[1].dx, segment[1].dy);
    } else {
      for (int i = 1; i < segment.length - 1; i++) {
        final prev = segment[i - 1];
        final curr = segment[i];
        final next = segment[i + 1];
        final vIn = curr - prev;
        final vOut = next - curr;
        final lenIn = vIn.distance;
        final lenOut = vOut.distance;
        if (lenIn == 0 || lenOut == 0) continue;
        final r =
            math.min(cornerRadius, math.min(lenIn / 2, lenOut / 2));
        final a = curr - (vIn / lenIn) * r;
        final b = curr + (vOut / lenOut) * r;
        path.lineTo(a.dx, a.dy);
        path.quadraticBezierTo(curr.dx, curr.dy, b.dx, b.dy);
      }
      path.lineTo(segment.last.dx, segment.last.dy);
    }
    segment.clear();
  }

  for (final p in pts) {
    if (p.dx.isNaN || p.dy.isNaN) {
      flush();
    } else {
      segment.add(p);
    }
  }
  flush();
  return path;
}

/// Total length of the polyline through [pts].
double polylineLength(List<Offset> pts) {
  double total = 0;
  for (int i = 1; i < pts.length; i++) {
    total += (pts[i] - pts[i - 1]).distance;
  }
  return total;
}

/// The sub-polyline from the start up to [fraction] (0..1) of the total length.
///
/// Its last point is the point *at* that fraction, which is where Sundan Ito
/// puts the numbered handle the child drags: at 0 the handle sits on the first
/// point of the stroke, at 1 on the last, and in between it follows the finger
/// along the letter.
List<Offset> partialPolyline(List<Offset> pts, double fraction) {
  if (pts.isEmpty) return const [];
  if (pts.length < 2 || fraction <= 0) return [pts.first];
  if (fraction >= 1) return List.of(pts);
  final total = polylineLength(pts);
  final target = total * fraction;
  final out = <Offset>[pts.first];
  double acc = 0;
  for (int i = 1; i < pts.length; i++) {
    final seg = (pts[i] - pts[i - 1]).distance;
    if (acc + seg >= target) {
      final t = seg == 0 ? 0.0 : (target - acc) / seg;
      out.add(Offset.lerp(pts[i - 1], pts[i], t)!);
      return out;
    }
    acc += seg;
    out.add(pts[i]);
  }
  return out;
}

/// The stretch of the polyline between [from] and [to] (each 0..1 of the
/// total length), cut at exactly those points.
///
/// Sundan Ito matches the child's finger against this rather than against the
/// whole stroke. Matching against the whole stroke is how a letter that comes
/// back near itself — O, 8, g, 6 — could be finished by holding a finger near
/// the far side of the loop: the nearest point on the path was already most
/// of the way along, so progress ran forward without the finger ever going
/// there. Only the next stretch is offered, so the letter has to be travelled
/// in order.
List<Offset> polylineSegment(List<Offset> pts, double from, double to) {
  if (pts.isEmpty) return const [];
  if (pts.length < 2) return [pts.first];
  final a = from.clamp(0.0, 1.0);
  final b = to.clamp(0.0, 1.0);
  if (b <= a) return [partialPolyline(pts, a).last];

  final total = polylineLength(pts);
  if (total <= 0) return [pts.first];
  final startAt = total * a;
  final endAt = total * b;

  final out = <Offset>[];
  double acc = 0;
  for (int i = 1; i < pts.length; i++) {
    final p0 = pts[i - 1];
    final p1 = pts[i];
    final seg = (p1 - p0).distance;
    if (seg == 0) continue;
    final segEnd = acc + seg;
    if (segEnd >= startAt && acc <= endAt) {
      final t0 = ((startAt - acc) / seg).clamp(0.0, 1.0);
      final t1 = ((endAt - acc) / seg).clamp(0.0, 1.0);
      final q0 = Offset.lerp(p0, p1, t0)!;
      final q1 = Offset.lerp(p0, p1, t1)!;
      if (out.isEmpty) out.add(q0);
      if ((q1 - out.last).distance > 0) out.add(q1);
    }
    acc = segEnd;
  }
  if (out.isEmpty) out.add(partialPolyline(pts, a).last);
  return out;
}
