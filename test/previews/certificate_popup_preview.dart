import 'dart:io';
import 'dart:math' as math;

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/widgets/certificate_earned_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two ways to tell a child they have just earned the certificate, drawn
/// side by side for choosing. Neither is in the app yet. Not part of the
/// suite — run by hand:
///
///   flutter test --update-goldens test/previews/certificate_popup_preview.dart
void main() {
  setUpAll(() async {
    for (final (family, file) in const [
      ('Roboto', r'C:\Windows\Fonts\arialbd.ttf'),
      ('Fredoka', 'assets/fonts/Fredoka.ttf'),
    ]) {
      final f = File(file);
      if (!f.existsSync()) continue;
      final bytes = ByteData.view(f.readAsBytesSync().buffer);
      await (FontLoader(family)..addFont(Future.value(bytes))).load();
    }
  });

  Future<void> shoot(WidgetTester tester, Widget popup, String name) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(400, 820) * 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Stack(children: [
          // Where the child was: the dashboard, dimmed behind the pop-up.
          const Center(
            child: Text('E-Tarabay',
                style: TextStyle(fontSize: 28, color: Colors.black26)),
          ),
          Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.55))),
          popup,
        ]),
      ),
    ));
    await tester.runAsync(() async {
      for (final img in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(
            img.image, tester.element(find.byWidget(img).first));
      }
    });
    // Past the app's own entrance (the last part fades in after 0.8 s).
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../../build/size_audit/$name.png'));
  }

  testWidgets('A: celebration card', (tester) async {
    await shoot(
        tester, const _CardPopup(name: 'Ana'), 'certificate_popup_A_fil');
  });

  testWidgets('B: certificate reveal', (tester) async {
    await shoot(
        tester, const _RevealPopup(name: 'Ana'), 'certificate_popup_B_fil');
  });

  // The chosen design as the app now draws it, to lay beside A.
  testWidgets('A as built into the app', (tester) async {
    await shoot(
        tester,
        Localizations(
          locale: const Locale('fil'),
          delegates: AppLocalizations.localizationsDelegates,
          // Without the falling confetti: its random burst made the picture
          // differ from run to run, and the comparison fail now and then.
          child: const CertificateEarnedPopup(name: 'Ana', confetti: false),
        ),
        'certificate_popup_A_app_fil');
  });

  testWidgets('C: golden trophy', (tester) async {
    await shoot(
        tester, const _TrophyPopup(name: 'Ana'), 'certificate_popup_C_fil');
  });

  testWidgets('D: graduation stage', (tester) async {
    await shoot(
        tester, const _StagePopup(name: 'Ana'), 'certificate_popup_D_fil');
  });

  testWidgets('E: from the bottom', (tester) async {
    await shoot(
        tester, const _SheetPopup(name: 'Ana'), 'certificate_popup_E_fil');
  });
}

const _trophy = 'assets/images/trophy_happy.webp';
const _stars = [
  'assets/images/star_happy_1.webp',
  'assets/images/star_happy_2.webp',
  'assets/images/star_happy_3.webp',
];

Widget _viewButton({double height = 60, double fontSize = 22}) => _ChunkyButton(
      label: 'Tingnan ang Sertipiko',
      top: const Color(0xFF5BE08A),
      bottom: const Color(0xFF22B45A),
      edge: const Color(0xFF168344),
      height: height,
      fontSize: fontSize,
    );

Widget _later(Color color) => Text('Mamaya na',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color));

// ─── C: a golden trophy in a burst of light ─────────────────────────────────

class _TrophyPopup extends StatelessWidget {
  final String name;
  const _TrophyPopup({required this.name});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned(
        left: -200,
        right: -200,
        top: 20,
        height: 560,
        child: CustomPaint(painter: _RaysPainter()),
      ),
      ..._confetti(400, 820, 11),
      Positioned.fill(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 30),
          Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                        colors: [Color(0xAAFFF3B0), Color(0x00FFF3B0)]),
                  ),
                ),
                Image.asset(_trophy, width: 200, height: 200),
                Positioned(
                    left: -58,
                    top: 24,
                    child: Image.asset(_stars[0], width: 62)),
                Positioned(
                    right: -58,
                    top: 24,
                    child: Image.asset(_stars[2], width: 62)),
                Positioned(top: -50, child: Image.asset(_stars[1], width: 72)),
              ]),
          const SizedBox(height: 14),
          const _RimmedTitle('PAGTATAPOS!', fontSize: 46),
          const SizedBox(height: 12),
          Text(
            'Ang galing mo, $name!\nNatapos mo ang lahat ng aralin\nat nakuha mo ang lahat ng medalya.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                height: 1.3,
                color: Colors.white,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD23F), width: 3),
            ),
            child: const Text('Sertipiko ng Pagtatapos',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4F5BB5))),
          ),
          const SizedBox(height: 26),
          SizedBox(width: 300, child: _viewButton(height: 62, fontSize: 23)),
          const SizedBox(height: 12),
          _later(Colors.white70),
        ]),
      ),
    ]);
  }
}

class _RaysPainter extends CustomPainter {
  const _RaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.4);
    final paint = Paint()..color = const Color(0x40FFE27A);
    const n = 16;
    for (int i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(c.dx + 700 * math.cos(a - 0.09),
                c.dy + 700 * math.sin(a - 0.09))
            ..lineTo(c.dx + 700 * math.cos(a + 0.09),
                c.dy + 700 * math.sin(a + 0.09))
            ..close(),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── D: on a stage, the curtains open ───────────────────────────────────────

class _StagePopup extends StatelessWidget {
  final String name;
  const _StagePopup({required this.name});

  @override
  Widget build(BuildContext context) {
    Widget curtain({required bool left}) => Container(
          width: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF8E1B2C),
              Color(0xFFD4374E),
              Color(0xFF9E2235),
              Color(0xFFD4374E),
              Color(0xFF8E1B2C),
            ]),
            borderRadius: BorderRadius.only(
              bottomRight: left ? const Radius.circular(56) : Radius.zero,
              bottomLeft: left ? Radius.zero : const Radius.circular(56),
            ),
          ),
        );
    return Stack(children: [
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.15),
              radius: 0.85,
              colors: [Color(0xFF6A58B0), Color(0xFF241A4A)],
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: 210,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC98A4B), Color(0xFF8A5A2B)],
            ),
          ),
        ),
      ),
      ..._confetti(400, 820, 19),
      Positioned(left: 0, top: 0, bottom: 210, child: curtain(left: true)),
      Positioned(right: 0, top: 0, bottom: 210, child: curtain(left: false)),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: 62,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFB02A40),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            border:
                Border(bottom: BorderSide(color: Color(0xFFFFC93C), width: 5)),
          ),
          alignment: Alignment.center,
          child: const Text('PAGTATAPOS',
              style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFE27A))),
        ),
      ),
      Positioned.fill(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 50),
          _RimmedTitle('Mabuhay ka,\n$name!', fontSize: 40),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8A5A2B), width: 6),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _MiniCertificate(name: name, width: 250),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(_mascot, height: 104),
            const SizedBox(width: 8),
            Image.asset(_popper, height: 66),
          ]),
          const SizedBox(height: 10),
          SizedBox(width: 290, child: _viewButton()),
          const SizedBox(height: 10),
          _later(const Color(0xFFFFF1DC)),
        ]),
      ),
    ]);
  }
}

// ─── E: a lighter card rising from the bottom ───────────────────────────────

class _SheetPopup extends StatelessWidget {
  final String name;
  const _SheetPopup({required this.name});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ..._confetti(400, 300, 23),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DEEA),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Image.asset(_mascot, height: 92),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Binabati kita, $name!',
                          style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE8405F))),
                      const SizedBox(height: 4),
                      const Text(
                          'Natapos mo ang lahat! Heto ang iyong Sertipiko ng Pagtatapos.',
                          style: TextStyle(
                              fontSize: 16,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F5BB5))),
                    ]),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD23F), width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _MiniCertificate(name: name, width: 340),
              ),
            ),
            const SizedBox(height: 20),
            _viewButton(),
            const SizedBox(height: 8),
            _later(const Color(0xFF7A84A6)),
          ]),
        ),
      ),
    ]);
  }
}

const _certificate = 'assets/images/E-TarabayCertificate.webp';
const _popper = 'assets/images/celebrate_popper.webp';
const _mascot = 'assets/images/mascot_dino.webp';
const _mascotWave = 'assets/images/mascot_wave.webp';

/// The real certificate with the child's name on its line, at any width.
class _MiniCertificate extends StatelessWidget {
  final String name;
  final double width;
  const _MiniCertificate({required this.name, required this.width});

  @override
  Widget build(BuildContext context) {
    // The background image's own size, as the certificate screen measures it.
    const w = 1492.0, h = 1054.0;
    return SizedBox(
      width: width,
      height: width * h / w,
      child: FittedBox(
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(_certificate, fit: BoxFit.fill)),
            Positioned(
              left: w * 0.19,
              width: w * 0.62,
              top: h * 0.36 - 45,
              height: 90,
              child: Center(
                child: Text(name.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF19416B))),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Bits of confetti in fixed places, so the picture is the same each run.
List<Widget> _confetti(double width, double height, int seed) {
  final r = math.Random(seed);
  const colors = [
    Color(0xFFFF5A5F),
    Color(0xFFFFB25B),
    Color(0xFF3D8BF2),
    Color(0xFF6C5CE7),
    Color(0xFF2ECC71),
    Color(0xFFFFD23F),
  ];
  // Around the edges and above and below, never over the words.
  final spots = <Offset>[];
  while (spots.length < 34) {
    final p = Offset(r.nextDouble() * width, r.nextDouble() * height);
    final edge = p.dx < 34 || p.dx > width - 34;
    if (edge || p.dy < 130 || p.dy > height - 110) spots.add(p);
  }
  return [
    for (int i = 0; i < spots.length; i++)
      Positioned(
        left: spots[i].dx,
        top: spots[i].dy,
        child: Transform.rotate(
          angle: r.nextDouble() * math.pi,
          child: Container(
            width: 7 + r.nextDouble() * 6,
            height: 12 + r.nextDouble() * 8,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
  ];
}

// ─── A: the team's celebration card, with the certificate on it ─────────────

class _CardPopup extends StatelessWidget {
  final String name;
  const _CardPopup({required this.name});

  @override
  Widget build(BuildContext context) {
    const cardWidth = 336.0;
    return Stack(children: [
      ..._confetti(400, 820, 3),
      Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 96),
              Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    _rainbowCard(
                      cardWidth,
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        _RimmedTitle('Binabati kita,\n$name!', fontSize: 38),
                        const SizedBox(height: 10),
                        const Text(
                          'Nakuha mo ang iyong\nSertipiko ng Pagtatapos!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              height: 1.15,
                              color: Color(0xFF4F5BB5),
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 18),
                        Transform.rotate(
                          angle: -0.05,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: _MiniCertificate(name: name, width: 250),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        const _ChunkyButton(
                          label: 'Tingnan ang Sertipiko',
                          top: Color(0xFF5BE08A),
                          bottom: Color(0xFF22B45A),
                          edge: Color(0xFF168344),
                          height: 58,
                          fontSize: 22,
                        ),
                        const SizedBox(height: 10),
                        const Text('Mamaya na',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7A84A6))),
                      ]),
                    ),
                    Positioned(
                        top: -112,
                        child: Image.asset(_popper, width: 150, height: 150)),
                    Positioned(
                      top: -78,
                      left: -6,
                      child: Transform.flip(
                        flipX: true,
                        child: Transform.rotate(
                            angle: -0.35,
                            child: Image.asset(_popper, width: 72, height: 72)),
                      ),
                    ),
                    Positioned(
                      top: -78,
                      right: -6,
                      child: Transform.rotate(
                          angle: 0.35,
                          child: Image.asset(_popper, width: 72, height: 72)),
                    ),
                    Positioned(
                        right: -30,
                        top: 300,
                        child: Image.asset(_mascot, height: 104)),
                  ]),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _rainbowCard(double width, Widget child) {
    const rim = 7.0;
    return Container(
      width: width,
      padding: const EdgeInsets.all(rim),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        gradient: const SweepGradient(colors: [
          Color(0xFFFF8A3D),
          Color(0xFFFF5A5F),
          Color(0xFF6C5CE7),
          Color(0xFF3D8BF2),
          Color(0xFF7CC6F7),
          Color(0xFFFFB25B),
          Color(0xFFFF8A3D),
        ]),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(44 - rim),
          gradient: const RadialGradient(
            radius: 0.9,
            colors: [Colors.white, Colors.white, Color(0xFFEFF6FF)],
            stops: [0, 0.75, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─── B: the certificate itself, revealed ────────────────────────────────────

class _RevealPopup extends StatelessWidget {
  final String name;
  const _RevealPopup({required this.name});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ..._confetti(400, 820, 7),
      // Close, small, out of the way.
      Positioned(
        top: 44,
        right: 18,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('X',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4F5BB5))),
          ),
        ),
      ),
      Positioned.fill(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _GoldRibbon('Natapos mo ang LAHAT!'),
          const SizedBox(height: 40),
          Stack(clipBehavior: Clip.none, children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD23F), width: 5),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFFFD23F).withValues(alpha: 0.55),
                      blurRadius: 30,
                      spreadRadius: 4),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: _MiniCertificate(name: name, width: 360),
              ),
            ),
            // At the certificate's bottom corner, over its own art only.
            Positioned(
                right: -14,
                bottom: -46,
                child: Image.asset(_mascotWave, height: 100)),
          ]),
          const SizedBox(height: 62),
          const Text(
            'Binabati kita, Ana!\nIto ang iyong Sertipiko ng Pagtatapos.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 19,
                height: 1.25,
                color: Colors.white,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 26),
          const SizedBox(
            width: 300,
            child: _ChunkyButton(
              label: 'Tingnan ang Sertipiko',
              top: Color(0xFF5BE08A),
              bottom: Color(0xFF22B45A),
              edge: Color(0xFF168344),
              height: 62,
              fontSize: 23,
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _GoldRibbon extends StatelessWidget {
  final String text;
  const _GoldRibbon(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE27A), Color(0xFFF5B400)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFC98A00), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFFC98A00), offset: Offset(0, 5)),
        ],
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7A3E00))),
    );
  }
}

// ─── Copies of the celebration card's own title and button ──────────────────

class _RimmedTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  const _RimmedTitle(this.text, {required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: fontSize, fontWeight: FontWeight.w900, height: 1.02);
    Text stroke(double width, Color color) => Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..strokeJoin = StrokeJoin.round
              ..color = color,
          ),
        );
    return Stack(alignment: Alignment.center, children: [
      stroke(13, const Color(0xFFB0303A)),
      stroke(8, Colors.white),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2385A), Color(0xFFFF7A1A), Color(0xFFFFA21F)],
        ).createShader(r),
        child: Text(text,
            textAlign: TextAlign.center,
            style: style.copyWith(color: Colors.white)),
      ),
    ]);
  }
}

class _ChunkyButton extends StatelessWidget {
  final String label;
  final Color top, bottom, edge;
  final double height;
  final double fontSize;

  const _ChunkyButton({
    required this.label,
    required this.top,
    required this.bottom,
    required this.edge,
    required this.height,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: edge, width: 3),
        boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
      ),
    );
  }
}
