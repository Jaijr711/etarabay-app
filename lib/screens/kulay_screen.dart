import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../widgets/custom_back_button.dart';
import '../widgets/fun_dialog.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/crayon_swatch.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../utils/word_fit.dart';
import '../widgets/design_scale.dart';
import '../widgets/module_cards.dart';
import '../services/sfx.dart';
import 'package:confetti/confetti.dart';

class ColoringCategory {
  final String name;
  final String icon;
  final Color color;
  final List<ColoringPage> pages;
  const ColoringCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.pages,
  });
}

class ColoringPage {
  final String name;
  final String imagePath;
  final String difficulty;
  final String timeEstimate;
  final int colors;

  /// Pictures this page used before its current one. Creations saved from
  /// them still belong to this page — otherwise replacing a picture would
  /// quietly take the page's check mark away from every child who finished it.
  final List<String> formerImagePaths;
  const ColoringPage({
    required this.name,
    required this.imagePath,
    required this.difficulty,
    required this.timeEstimate,
    required this.colors,
    this.formerImagePaths = const [],
  });

  /// Whether [path] is this page's picture, now or before.
  bool usesImage(String path) =>
      path == imagePath || formerImagePaths.contains(path);

  /// Whether [creation] was colored on this page.
  bool owns(MyCreation creation) =>
      usesImage(creation.sourcePagePath) || usesImage(creation.thumbnailPath);
}

class ColoringStroke {
  final List<Offset> points;
  final Color color;
  final double size;
  final bool isEraser;

  /// Region the stroke is clipped to so a child's coloring never crosses the
  /// black outline. Recomputed from the line art when needed; not serialized.
  final ui.Image? mask;

  /// Whether [_KulayScreenState._computeRegionMask] has finished looking for
  /// that region — regardless of whether it found one.
  ///
  /// Computing the mask is async, so for a few frames after a finger goes
  /// down a fresh stroke genuinely has no mask yet, same as one whose finger
  /// landed on the background rather than the artwork and never gets one at
  /// all. Drawing unmasked in either case let paint follow the finger
  /// straight across the black outline onto the plain background — every
  /// stroke used to fall back to fully unclipped until this flips true, when
  /// it should draw nothing at all until the answer (region, or none) is
  /// known.
  final bool maskResolved;

  const ColoringStroke({
    required this.points,
    required this.color,
    required this.size,
    this.isEraser = false,
    this.mask,
    this.maskResolved = false,
  });

  ColoringStroke copyWith(
      {List<Offset>? points, ui.Image? mask, bool? maskResolved}) {
    return ColoringStroke(
      points: points ?? this.points,
      color: color,
      size: size,
      isEraser: isEraser,
      mask: mask ?? this.mask,
      maskResolved: maskResolved ?? this.maskResolved,
    );
  }

  /// The same stroke on a canvas [f] times the size.
  ColoringStroke scaled(double f) => ColoringStroke(
        points: [for (final p in points) p * f],
        color: color,
        size: size * f,
        isEraser: isEraser,
      );

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'size': size,
      'isEraser': isEraser,
    };
  }

  factory ColoringStroke.fromMap(Map<String, dynamic> map) {
    return ColoringStroke(
      points: (map['points'] as List)
          .map((p) => Offset(p['dx'] as double, p['dy'] as double))
          .toList(),
      color: Color(map['color'] as int),
      size: map['size'] as double,
      isEraser: map['isEraser'] as bool,
    );
  }
}

class MyCreation {
  final String name;
  final DateTime date;
  final String thumbnailPath;
  final String sourcePagePath;
  final String base64Image;
  final List<ColoringStroke> strokes;

  /// The bucket-filled picture (PNG, base64, at the page's own size). Kept
  /// on this device only — the cloud copy carries the small picture alone.
  /// Empty for creations saved before it was kept.
  final String fillImage;

  /// The side of the canvas the [strokes] were drawn on, in logical pixels;
  /// 0 when not known (older creations).
  final double canvasSide;
  bool isFavorite;
  int? stars;
  int durationSeconds; // time spent coloring

  MyCreation({
    required this.name,
    required this.date,
    required this.thumbnailPath,
    this.sourcePagePath = '',
    this.base64Image = '',
    required this.strokes,
    this.fillImage = '',
    this.canvasSide = 0,
    this.isFavorite = false,
    this.stars,
    this.durationSeconds = 0,
  });

  String get formattedDuration {
    final d = Duration(seconds: durationSeconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class StrokePainter extends CustomPainter {
  final List<ColoringStroke> strokes;
  // Parallel to [strokes] — each one built exactly once, when its stroke
  // was committed, rather than reconstructed from raw points on every
  // repaint. See the doc comment on [_KulayScreenState._strokePaths].
  final List<Path> strokePaths;
  final ColoringStroke? activeStroke;
  final Path? activeStrokePath;

  /// Every stroke before [bakedCount], flattened into one bitmap by
  /// [_KulayScreenState._rebakeStrokes] — see that method's doc comment for
  /// why. Null until the first stroke finishes.
  final ui.Image? bakedImage;

  /// How many leading [strokes] are already represented in [bakedImage].
  /// Only the strokes from here on still need drawing individually.
  final int bakedCount;

  const StrokePainter({
    required this.strokes,
    required this.strokePaths,
    this.activeStroke,
    this.activeStrokePath,
    this.bakedImage,
    this.bakedCount = 0,
    super.repaint,
  });

  /// Where an image of the page sits on the canvas: [BoxFit.contain],
  /// as the line art is shown.
  static Rect containRect(ui.Image image, Size size) {
    final ratio = image.width / image.height;
    final side = size.shortestSide;
    if (ratio > 1) {
      final h = side / ratio;
      return Rect.fromLTWH(0, (side - h) / 2, side, h);
    }
    final w = side * ratio;
    return Rect.fromLTWH((side - w) / 2, 0, w, side);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Strokes live in their own layer: the eraser punches transparent holes
    // in that layer (BlendMode.clear) so the line art underneath is never
    // touched — it only removes the child's own coloring.
    canvas.saveLayer(Offset.zero & size, Paint());
    final baked = bakedImage;
    if (baked != null) drawBaked(canvas, baked, size);
    // Only the strokes the cached image does not already cover — most
    // repaints while the child is actively dragging touch nothing here but
    // the one active stroke below, regardless of how much they have already
    // coloured. See _rebakeStrokes for why this list is short.
    for (int i = bakedCount; i < strokes.length; i++) {
      drawStroke(canvas, strokes[i],
          i < strokePaths.length ? strokePaths[i] : null, size);
    }
    if (activeStroke != null) {
      drawStroke(canvas, activeStroke!, activeStrokePath, size);
    }
    canvas.restore();
  }

  /// The baked strokes, rendered at the screen's own resolution (or finer),
  /// fitted back onto the canvas — see [_KulayScreenState._rebakeStrokes].
  static void drawBaked(Canvas canvas, ui.Image baked, Size size) {
    canvas.drawImageRect(
      baked,
      Rect.fromLTWH(0, 0, baked.width.toDouble(), baked.height.toDouble()),
      Offset.zero & Size(size.shortestSide, size.shortestSide),
      Paint(),
    );
  }

  /// Shared with [_KulayScreenState._rebakeStrokes] so the live painter and
  /// the baked bitmap it periodically folds strokes into can never draw a
  /// stroke two different ways.
  static void drawStroke(
      Canvas canvas, ColoringStroke stroke, Path? path, Size size) {
    if (stroke.points.isEmpty) return;

    // Nothing to clip to yet, and nothing to clip to ever — either way,
    // drawing now would put paint on screen this stroke has no right to:
    // a fresh stroke waiting on its async mask lookup, or one whose finger
    // came down somewhere the artwork has no region at all (the
    // background). Only an eraser, which has no region of its own to
    // respect, skips this check.
    if (!stroke.isEraser && (!stroke.maskResolved || stroke.mask == null)) {
      return;
    }

    // A masked stroke is drawn in its own layer, then intersected with the
    // region mask (dstIn) so paint can never cross the black outline.
    final mask = stroke.isEraser ? null : stroke.mask;
    if (mask != null) canvas.saveLayer(Offset.zero & size, Paint());

    final blend = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.size
      ..blendMode = blend
      ..color = stroke.color.withOpacity(1.0);

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first,
        stroke.size / 2,
        Paint()
          ..style = PaintingStyle.fill
          ..blendMode = blend
          ..color = stroke.color.withOpacity(1.0),
      );
    } else if (path != null) {
      canvas.drawPath(path, paint);
    }

    if (mask != null) {
      // Map the image-space mask onto the canvas with the same BoxFit.contain
      // geometry used to display the line art. Its pixel steps fall under
      // the outlines drawn over the coloring (see _drawingSurface), so the
      // cheapest sampling does — smoothing it cost every frame of a stroke.
      canvas.drawImageRect(
        mask,
        Rect.fromLTWH(0, 0, mask.width.toDouble(), mask.height.toDouble()),
        containRect(mask, size),
        Paint()..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(StrokePainter old) => true;
}

/// Whether the unsaved draft under [key] has anything on it: a stroke, or a
/// fill with its picture. A card picture alone does not count — that is how
/// a page came to say "in progress" with colours on its card and open empty.
@visibleForTesting
bool kulayDraftHasContent(SharedPreferences prefs, String key) {
  final strokes = prefs.getString('${key}_strokes');
  final hasStrokes = strokes != null && strokes.isNotEmpty && strokes != '[]';
  final hasFill = (prefs.getInt('${key}_filledPixels') ?? 0) > 0 &&
      (prefs.containsKey('${key}_imageData') ||
          prefs.containsKey('${key}_imagePath'));
  return hasStrokes || hasFill;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
/// How many strokes, or points across them, a picture keeps as strokes
/// before the oldest are folded into its fill picture; and how many of the
/// newest always stay strokes, for Undo. Variables only so a test can lower
/// them.
@visibleForTesting
int kulayBakeMaxStrokes = 300;
@visibleForTesting
int kulayBakeMaxPoints = 12000;
@visibleForTesting
int kulayBakeKeep = 50;

/// Whether a picture's strokes have grown past what it keeps as strokes.
@visibleForTesting
bool kulayNeedsBake(List<ColoringStroke> strokes) {
  if (strokes.length > kulayBakeMaxStrokes) return true;
  int points = 0;
  for (final s in strokes) {
    points += s.points.length;
    if (points > kulayBakeMaxPoints) return true;
  }
  return false;
}

/// The first page after [current] in the book's order — across categories,
/// wrapping round — that is not finished, or null when every page is.
@visibleForTesting
int? kulayNextUnfinished(List<bool> finished, int current) {
  for (int k = 1; k <= finished.length; k++) {
    final i = (current + k) % finished.length;
    if (!finished[i]) return i;
  }
  return null;
}

class KulayScreen extends StatefulWidget {
  const KulayScreen({super.key});

  @override
  State<KulayScreen> createState() => _KulayScreenState();
}

class _KulayScreenState extends State<KulayScreen>
    with TickerProviderStateMixin {
  // ── Navigation ─────────────────────────────────────────────────────────────
  int _selectedTab = 0;
  int _selectedCategory = 0;

  /// The category whose pages are showing, or null for the four categories
  /// themselves. The coloring tab opens on the categories: each one shows
  /// its pages fanned out and how many are finished, and a page already
  /// started waits at the top with "Continue".
  int? _openCategory;
  ColoringPage? _selectedPage;

  /// [UserProvider.creationsVersion] when this screen last read its list.
  int? _seenCreationsVersion;

  // ── Drawing state ──────────────────────────────────────────────────────────
  final List<ColoringStroke> _strokes = [];
  ColoringStroke? _activeStroke;

  /// Every finished, mask-resolved stroke below [_bakedCount], flattened
  /// into one bitmap — see [_rebakeStrokes].
  ///
  /// Every repaint used to redraw the child's entire coloring history from
  /// scratch, each stroke its own masked saveLayer. That is fine for the
  /// first few strokes and unusable for the hundredth: a long coloring
  /// session made every later stroke, and every pinch-to-zoom frame,
  /// slower than the last, for work the canvas had already finished and
  /// was never going to change again.
  ui.Image? _bakedStrokes;

  /// How many leading [_strokes] are already inside [_bakedStrokes].
  int _bakedCount = 0;

  // A finished stroke's Path, built exactly once when it's committed — kept
  // in step with [_strokes] (same index). Coloring used to hand the raw
  // point list to StrokePainter and let it rebuild every stroke's whole
  // curve from scratch on every repaint, so a picture with dozens of past
  // strokes got a little slower to draw on with every new one added. The
  // in-progress stroke has the same problem within itself: without
  // [_activeStrokePath] its own curve was rebuilt from point zero on every
  // single pointer-move, so a long, continuous scribble visibly slowed down
  // the longer it went on.
  final List<Path> _strokePaths = [];
  Path? _activeStrokePath;
  Offset? _activeStrokePrevPoint;
  int _activeStrokePointCount = 0;

  Color _selectedColor = const Color(0xFFFF3B30);
  double _brushSize = 30.0;

  /// The nearest of the three brush sizes the tool row offers.
  static double _snapBrush(double v) => v < 21 ? 12 : (v < 39 ? 30 : 48);
  bool _isEraser = false;
  MyCreation? _editingCreation;

  /// Set when the picture was opened from My Creations: going back returns
  /// there, not to the coloring tab.
  bool _returnToCreations = false;

  /// What Clear just took away — the coloring, and the picture's place in
  /// My Creations — kept for a few seconds so Undo can put it all back.
  _ClearedPage? _pendingClear;
  Timer? _pendingClearTimer;

  // ── Zoom & pan ─────────────────────────────────────────────────────────────
  //
  // There is no zoom *mode* to switch on. One finger always colours; the
  // moment a second finger touches down the picture can be pinched and
  // dragged instead. A three-year-old cannot be asked to find a mode button
  // first, but they already know the two-finger pinch from photos and videos.

  /// Every finger currently on the canvas, so a second one can be noticed the
  /// instant it lands.
  final Set<int> _activePointers = {};

  /// True from the moment a second finger lands until every finger lifts.
  /// While it is true the canvas zooms and pans and nothing is drawn.
  bool _twoFingerGesture = false;

  /// Whether the picture is currently magnified — drives the Fit button.
  bool _isZoomed = false;

  DateTime? _coloringStartTime;
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _zoomResetController;
  Animation<Matrix4>? _zoomResetAnim;

  // ── Bucket fill ────────────────────────────────────────────────────────────
  img.Image? _baseImage;

  /// [_baseImage]'s pixels as RGBA bytes, four per pixel — read directly by
  /// the region search, which is far quicker than a getPixel per pixel.
  Uint8List? _baseRgba;
  img.Image? _coloredImage;
  ui.Image? _displayImage;
  int _filledPixelsCount = 0;
  double _lastSide = 300;
  bool _isLoadingAutoSave = false;

  /// The loading cover shows only if opening takes long enough to notice;
  /// a picture already decoded opens without a flash of white over it.
  bool _showLoadingOverlay = false;
  Timer? _loadingOverlayTimer;

  /// Each page's coloring in progress — begun but not saved — as a small
  /// picture for its card in the gallery, so unfinished work shows there
  /// too and not only once it is saved. Kept beside the page's autosave.
  final Map<String, Uint8List> _inProgress = {};
  Timer? _previewTimer;

  /// The draft key the waiting [_previewTimer] belongs to, so leaving can
  /// tidy it without looking the child up again from a closing screen.
  String? _previewKey;

  /// Whether the open picture has coloring that is not saved yet — what
  /// asks, on the way out, whether to save it.
  bool _dirty = false;
  final GlobalKey _canvasKey = GlobalKey();

  // Undo for the raster eraser below. There is no redo — see [_undo].
  final List<img.Image> _bucketUndoImages = [];
  final List<int> _bucketUndoPixelCounts = [];

  // ── Eraser (also erases _coloredImage, not just brush strokes — a page
  //    autosaved from an older version of the app, back when a tap bucket-
  //    filled a region, can still have colour sitting in that layer) ──────
  // One undo snapshot per drag, taken lazily on its first erased pixel.
  bool _eraseSnapshotPushedForStroke = false;
  bool _eraseDisplayUpdateInFlight = false;
  bool _eraseDisplayUpdatePending = false;
  Offset? _lastEraseLocalPoint;

  // ── Audio ──────────────────────────────────────────────────────────────────
  late AudioPlayer _audioPlayer;

  // ── Progress & animations ──────────────────────────────────────────────────
  late AnimationController _rippleController;
  late Animation<double> _rippleAnim;
  Offset? _lastPos;

  /// Ticks on every finger move, repainting the drawing alone.
  final ValueNotifier<int> _strokeTick = ValueNotifier<int>(0);

  // ── My Creations ───────────────────────────────────────────────────────────
  final List<MyCreation> _myCreations = [];
  int _sortMode = 0;

  // ── Palette ────────────────────────────────────────────────────────────────
  // The standard 8-crayon box — red, orange, yellow, blue, green, purple,
  // brown, black — the same set almost every child already owns and has
  // opened before, so nothing about picking a colour here has to be taught.
  final List<Color> _palette = const [
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF007AFF),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
    Color(0xFF964B00),
    Color(0xFF000000),
  ];

  // Keys into AppLocalizations, same order as _palette — the palette itself
  // stays a plain List<Color> so nothing else that reads it has to change.
  static const List<String> _paletteKeys = [
    'red',
    'orange',
    'yellow',
    'blue',
    'green',
    'purple',
    'brown',
    'black',
  ];

  String _paletteLabel(AppLocalizations loc, int i) {
    switch (_paletteKeys[i]) {
      case 'red':
        return loc.red;
      case 'orange':
        return loc.orange;
      case 'yellow':
        return loc.yellow;
      case 'blue':
        return loc.blue;
      case 'green':
        return loc.green;
      case 'purple':
        return loc.purple;
      case 'brown':
        return loc.brown;
      case 'black':
        return loc.black;
    }
    return _paletteKeys[i];
  }

  // ── Categories ─────────────────────────────────────────────────────────────
  final List<ColoringCategory> _categories = const [
    ColoringCategory(name: 'Animals', icon: '🐶', color: Colors.orange, pages: [
      ColoringPage(
          name: 'Puppy',
          imagePath: 'assets/images/paint1.png',
          difficulty: 'Easy',
          timeEstimate: '5 min',
          colors: 4),
      ColoringPage(
          name: 'Cat',
          imagePath: 'assets/images/paint2.png',
          difficulty: 'Easy',
          timeEstimate: '5 min',
          colors: 3),
      ColoringPage(
          name: 'Elephant',
          imagePath: 'assets/images/paint_elephant.webp',
          formerImagePaths: ['assets/images/paint3.png'],
          difficulty: 'Medium',
          timeEstimate: '8 min',
          colors: 2),
    ]),
    ColoringCategory(name: 'Flowers', icon: '🌸', color: Colors.pink, pages: [
      ColoringPage(
          name: 'Flower Basket',
          imagePath: 'assets/images/paint_daisy.webp',
          formerImagePaths: ['assets/images/paint4.png'],
          difficulty: 'Medium',
          timeEstimate: '10 min',
          colors: 5),
      ColoringPage(
          name: 'Rose',
          imagePath: 'assets/images/paint5.png',
          difficulty: 'Hard',
          timeEstimate: '12 min',
          colors: 3),
    ]),
    ColoringCategory(name: 'Fruits', icon: '🍎', color: Colors.red, pages: [
      ColoringPage(
          name: 'Apple',
          imagePath: 'assets/images/paint6.png',
          difficulty: 'Easy',
          timeEstimate: '3 min',
          colors: 2),
      ColoringPage(
          name: 'Banana',
          imagePath: 'assets/images/paint7.png',
          difficulty: 'Easy',
          timeEstimate: '4 min',
          colors: 2),
    ]),
    ColoringCategory(name: 'Toys', icon: '🧸', color: Colors.brown, pages: [
      ColoringPage(
          name: 'Teddy Bear',
          imagePath: 'assets/images/paint8.png',
          difficulty: 'Medium',
          timeEstimate: '8 min',
          colors: 3),
      // Took the soda can's place (2026-10-19). The soda page is gone for
      // good, its saved creations with it — see
      // UserProvider.isRemovedColoringCreation.
      ColoringPage(
          name: 'Race Car',
          imagePath: 'assets/images/paint_racecar.png',
          difficulty: 'Medium',
          timeEstimate: '8 min',
          colors: 4),
    ]),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  //  Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playModuleMusic(ModuleMusic.kulay);
    _loadCreations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prewarmPages();
      _loadInProgressPreviews();
      // The sign-in read may have missed; this is another go at it.
      final provider = Provider.of<UserProvider>(context, listen: false);
      if (!provider.creationsPulled) {
        unawaited(provider.pullCreationsFromCloud());
      }
    });

    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _rippleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _rippleAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _rippleController, curve: Curves.easeOut));

    _zoomResetController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _zoomResetController.addListener(_applyZoomReset);
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _loadingOverlayTimer?.cancel();
    // Left within moments of clearing the picture: the card's old picture
    // would stay, saying "in progress" over a page with nothing on it.
    final waitingKey = _previewKey;
    if ((_previewTimer?.isActive ?? false) &&
        waitingKey != null &&
        _strokes.isEmpty &&
        _filledPixelsCount == 0) {
      unawaited(SharedPreferences.getInstance()
          .then((prefs) => prefs.remove('${waitingKey}_preview')));
    }
    _previewTimer?.cancel();
    _commitClear(rebuild: false);
    _autoSaveTimer?.cancel();
    _strokeTick.dispose();
    _audioPlayer.dispose();
    _rippleController.dispose();
    _zoomResetController.dispose();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _bakedStrokes?.dispose();
    AudioManager.instance.resumeHomeMusicAfter(ModuleMusic.kulay);
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Gesture: separate drawing (1 pointer) from zoom/pan (2+ pointers)
  // ─────────────────────────────────────────────────────────────────────────

  /// Keeps the Fit button in step with the picture without rebuilding on
  /// every frame of a pinch — only the moment zoomed-ness flips matters.
  void _onTransformChanged() {
    final zoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed && mounted) setState(() => _isZoomed = zoomed);
  }

  void _applyZoomReset() {
    final anim = _zoomResetAnim;
    if (anim != null) _transformationController.value = anim.value;
  }

  /// Eases the picture back to its normal size and position.
  ///
  /// A child who has pinched the drawing off to one corner has no way back on
  /// their own, so one big button always returns the whole picture.
  void _resetZoom() {
    _zoomResetAnim = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
        parent: _zoomResetController, curve: Curves.easeOutCubic));
    _zoomResetController.forward(from: 0);
  }

  /// Drops any magnification without animating — used when a new picture is
  /// opened, so it never appears already zoomed in.
  void _clearZoom() {
    _zoomResetController.stop();
    _zoomResetAnim = null;
    _transformationController.value = Matrix4.identity();
    _twoFingerGesture = false;
    _activePointers.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Drawing (single-finger pan gestures on the INNER canvas)
  // ─────────────────────────────────────────────────────────────────────────

  /// Takes back the last thing the child coloured.
  ///
  /// One direction only. A child who has just undone something does not ask
  /// to put it back — they colour it again, which is the same gesture that
  /// made it in the first place. Keeping a redo meant keeping a second copy
  /// of the whole bitmap after every bucket fill for a button nobody pressed.
  Future<void> _undo() async {
    // Straight after Clear, Undo brings the whole picture back.
    if (_pendingClear != null) {
      await _restoreCleared();
      return;
    }
    if (_strokes.isNotEmpty) {
      // The baked bitmap may include the very stroke just undone — there is
      // no way to un-bake one stroke out of it, so the whole cache is
      // dropped and rebuilt (see _rebakeStrokes) from what remains.
      final oldBaked = _bakedStrokes;
      setState(() {
        _strokes.removeLast();
        if (_strokePaths.isNotEmpty) _strokePaths.removeLast();
        _bakedStrokes = null;
        _bakedCount = 0;
      });
      oldBaked?.dispose();
      unawaited(_rebakeStrokes());
      _autoSave();
      return;
    }
    if (_bucketUndoImages.isEmpty) return;

    _coloredImage = _bucketUndoImages.removeLast();
    _filledPixelsCount = _bucketUndoPixelCounts.removeLast();
    final uiImg = await _imageToUi(_coloredImage!);
    if (!mounted) return;
    setState(() => _displayImage = uiImg);
    _autoSave();
  }

  void _clearAll() {
    final oldBaked = _bakedStrokes;
    setState(() {
      _strokes.clear();
      _strokePaths.clear();
      _activeStroke = null;
      _filledPixelsCount = 0;
      if (_baseImage != null) {
        _coloredImage = _baseImage!.clone();
      }
      _displayImage = null;
      _bakedStrokes = null;
      _bakedCount = 0;
    });
    oldBaked?.dispose();
    _bucketUndoImages.clear();
    _bucketUndoPixelCounts.clear();
    _autoSave();
  }

  /// Clear, said yes to: the picture goes back to blank, and a picture
  /// already saved leaves My Creations and is no longer ticked. Nothing is
  /// thrown away yet — for a few seconds Undo (the note under the picture,
  /// or the Undo tool) puts it all back. The star it gave stays either way.
  Future<void> _wipePage() async {
    _commitClear();
    final page = _selectedPage;
    if (page == null) return;
    final owned = <(int, MyCreation)>[
      for (int i = 0; i < _myCreations.length; i++)
        if (page.owns(_myCreations[i])) (i, _myCreations[i]),
    ];
    final hadColor = _strokes.isNotEmpty || _filledPixelsCount > 0;
    if (!hadColor && owned.isEmpty) {
      _clearAll();
      return;
    }
    final place = _placeOf(page);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final snapshot = _ClearedPage(
      page: page,
      strokes: List.of(_strokes),
      paths: List.of(_strokePaths),
      colored: _coloredImage,
      filled: _filledPixelsCount,
      bucketImages: List.of(_bucketUndoImages),
      bucketCounts: List.of(_bucketUndoPixelCounts),
      creations: owned,
      editing: _editingCreation,
      dirty: _dirty,
      wasDone: place != null &&
          userProvider.isKulayPageCompleted(place.$1.name, place.$2),
    );
    _clearAll();
    setState(() {
      _pendingClear = snapshot;
      _myCreations.removeWhere(page.owns);
      _editingCreation = null;
    });
    if (owned.isNotEmpty) {
      _saveCreationsToHive();
      if (place != null) {
        await userProvider.updateKulayProgress('coloring', false,
            category: place.$1.name, index: place.$2);
      }
    }
    _pendingClearTimer?.cancel();
    _pendingClearTimer = Timer(const Duration(seconds: 6), _commitClear);
  }

  /// Makes the last Clear final: Undo can no longer bring it back, and the
  /// saved pictures it took out of My Creations are deleted from the device.
  void _commitClear({bool rebuild = true}) {
    _pendingClearTimer?.cancel();
    final gone = _pendingClear;
    if (gone == null) return;
    _pendingClear = null;
    for (final (_, c) in gone.creations) {
      if (kIsWeb ||
          c.thumbnailPath.isEmpty ||
          c.thumbnailPath.startsWith('assets/')) {
        continue;
      }
      try {
        File(c.thumbnailPath).deleteSync();
      } catch (e) {
        debugPrint('Error deleting thumbnail: $e');
      }
    }
    if (rebuild && mounted) setState(() {});
  }

  /// Undo after Clear: the coloring, the saved picture in My Creations at
  /// the place it had, and its tick.
  Future<void> _restoreCleared() async {
    final c = _pendingClear;
    if (c == null) return;
    _pendingClearTimer?.cancel();
    if (_selectedPage != c.page) {
      _commitClear();
      return;
    }
    final colored = c.colored;
    final display =
        colored != null && c.filled > 0 ? await _imageToUi(colored) : null;
    if (!mounted) return;
    final oldBaked = _bakedStrokes;
    setState(() {
      _pendingClear = null;
      _strokes
        ..clear()
        ..addAll(c.strokes);
      _strokePaths
        ..clear()
        ..addAll(c.paths);
      if (colored != null) _coloredImage = colored;
      _displayImage = display;
      _filledPixelsCount = c.filled;
      _bakedStrokes = null;
      _bakedCount = 0;
      _editingCreation = c.editing;
      for (final (i, creation) in c.creations) {
        _myCreations.insert(math.min(i, _myCreations.length), creation);
      }
    });
    oldBaked?.dispose();
    _bucketUndoImages
      ..clear()
      ..addAll(c.bucketImages);
    _bucketUndoPixelCounts
      ..clear()
      ..addAll(c.bucketCounts);
    unawaited(_rebakeStrokes());
    // A saved picture that had no unsaved coloring goes back to having
    // none, so its card does not turn "in progress".
    if (c.dirty || c.creations.isEmpty) {
      await _autoSave();
    } else {
      await _clearAutoSave();
      _dirty = false;
    }
    if (c.creations.isNotEmpty) {
      _saveCreationsToHive();
      final place = _placeOf(c.page);
      if (c.wasDone && place != null && mounted) {
        await Provider.of<UserProvider>(context, listen: false)
            .updateKulayProgress('coloring', true,
                category: place.$1.name, index: place.$2);
      }
    }
  }

  /// Folds the oldest finished strokes into the fill picture.
  ///
  /// Every stroke used to be kept forever, every point of it, and a page
  /// colored again day after day grew with each visit until it took seconds
  /// to open and its saved copy ran to tens of megabytes. Past
  /// [kulayNeedsBake] the oldest strokes become pixels of the fill picture,
  /// which is the same size however much is on it. It looks exactly the same;
  /// only those strokes can no longer be undone one by one — the newest
  /// [kulayBakeKeep] still can.
  Future<void> _bakeStrokesIntoFill() async {
    final base = _baseImage;
    final side = _lastSide;
    if (base == null || side <= 0) return;
    // The leading strokes that are settled: drawn the same way every time.
    var n = 0;
    while (n < _strokes.length &&
        (_strokes[n].isEraser || _strokes[n].maskResolved)) {
      n++;
    }
    n = math.min(n, _strokes.length - kulayBakeKeep);
    if (n <= 0) return;

    final w = base.width;
    final h = base.height;
    final fill = await _imageToUi(_coloredImage ?? base);
    final size = Size(side, side);
    final rect = StrokePainter.containRect(fill, size);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(fill, Offset.zero, Paint());
    // From the canvas the strokes were drawn on to the picture's own pixels.
    canvas.scale(w / rect.width, h / rect.height);
    canvas.translate(-rect.left, -rect.top);
    // Their own layer, as on screen: an eraser stroke clears strokes, never
    // the picture under them.
    canvas.saveLayer(rect, Paint());
    for (int i = 0; i < n; i++) {
      StrokePainter.drawStroke(canvas, _strokes[i],
          i < _strokePaths.length ? _strokePaths[i] : null, size);
    }
    canvas.restore();
    final out = await recorder.endRecording().toImage(w, h);
    fill.dispose();
    final bytes = await out.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null || !mounted) {
      out.dispose();
      return;
    }
    final baked = img.Image.fromBytes(
        width: w, height: h, bytes: bytes.buffer, numChannels: 4);
    final oldBaked = _bakedStrokes;
    setState(() {
      _strokes.removeRange(0, n);
      _strokePaths.removeRange(0, math.min(n, _strokePaths.length));
      _coloredImage = baked;
      _displayImage = out;
      // Something is in the fill now: it has to be saved with the picture.
      if (_filledPixelsCount == 0) _filledPixelsCount = 1;
      _bakedStrokes = null;
      _bakedCount = 0;
    });
    oldBaked?.dispose();
    // A fill undo from before would bring back a picture without them.
    _bucketUndoImages.clear();
    _bucketUndoPixelCounts.clear();
    unawaited(_rebakeStrokes());
  }

  /// The category a page is in, and its place there.
  (ColoringCategory, int)? _placeOf(ColoringPage page) {
    for (final cat in _categories) {
      final i = cat.pages.indexOf(page);
      if (i >= 0) return (cat, i);
    }
    return null;
  }

  /// The next page to color after [page], with its category's index.
  (int, ColoringPage)? _nextUnfinished(ColoringPage page) {
    final order = <(int, int)>[
      for (int c = 0; c < _categories.length; c++)
        for (int i = 0; i < _categories[c].pages.length; i++) (c, i),
    ];
    final here = order.indexWhere((o) => _categories[o.$1].pages[o.$2] == page);
    final next = kulayNextUnfinished(
        [for (final o in order) _pageFinished(_categories[o.$1], o.$2)],
        here < 0 ? 0 : here);
    if (next == null) return null;
    final (c, i) = order[next];
    return (c, _categories[c].pages[i]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Bucket fill helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadPageImage() async {
    final page = _selectedPage;
    if (page == null) return;
    final art = await _pageArt(page.imagePath);
    // Opened, left, and another page opened while this one was still
    // decoding: its picture must not land on the new page.
    if (art == null || !identical(_selectedPage, page)) return;
    _baseImage = art.image;
    _baseRgba = art.rgba;
    // A copy to color on: the decoded picture stays clean in the cache.
    _coloredImage = art.image.clone();
    _displayImage = art.display;
  }

  /// Every picture decoded once and kept for as long as the app runs.
  ///
  /// Opening a page used to decode its picture again each time, in Dart, on
  /// the thread that draws the screen — the long "Loading your artwork…".
  /// The pictures ship inside the app, so nothing here needs the internet;
  /// it was only ever the phone's own work, and now it is done once.
  static final Map<String, _PageArt> _artCache = {};
  static final Map<String, Future<_PageArt?>> _artLoading = {};

  static Future<_PageArt?> _pageArt(String path) {
    final cached = _artCache[path];
    if (cached != null) return Future.value(cached);
    return _artLoading[path] ??= () async {
      try {
        final data = await rootBundle.load(path);
        final decoded = await _decodeFast(data.buffer.asUint8List());
        if (decoded == null) return null;
        final art = _PageArt(
            decoded.image,
            decoded.rgba,
            decoded.display,
            await _outlinesOf(
                decoded.rgba, decoded.image.width, decoded.image.height));
        _artCache[path] = art;
        return art;
      } catch (e) {
        debugPrint('Error loading coloring image: $e');
        return null;
      } finally {
        _artLoading.remove(path);
      }
    }();
  }

  /// The picture's outlines alone, once per picture: black, with the
  /// picture's darkness as its opacity, so its soft edges stay soft.
  static Future<ui.Image?> _outlinesOf(Uint8List rgba, int w, int h) async {
    try {
      final out = Uint8List(w * h * 4);
      for (int i = 0, o = 0; i < w * h; i++, o += 4) {
        final lum = 0.299 * rgba[o] + 0.587 * rgba[o + 1] + 0.114 * rgba[o + 2];
        out[o + 3] = ((255 - lum) * rgba[o + 3] / 255).round().clamp(0, 255);
      }
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
          out, w, h, ui.PixelFormat.rgba8888, completer.complete);
      return await completer.future;
    } catch (e) {
      debugPrint('Outlines not prepared: $e');
      return null;
    }
  }

  /// Decodes with the phone's own image decoder (the browser's on the web),
  /// many times faster than decoding in Dart, and without holding up the
  /// screen. Falls back to the Dart decoder if the platform refuses.
  static Future<({img.Image image, Uint8List rgba, ui.Image display})?>
      _decodeFast(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      final display = frame.image;
      final data =
          await display.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      if (data == null) return null;
      final rgba =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final image = img.Image.fromBytes(
        width: display.width,
        height: display.height,
        bytes: rgba.buffer,
        bytesOffset: rgba.offsetInBytes,
        numChannels: 4,
      );
      return (image: image, rgba: rgba, display: display);
    } catch (e) {
      debugPrint('Native decode refused, decoding in Dart: $e');
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final image = decoded.convert(numChannels: 4);
      final rgba = image.getBytes(order: img.ChannelOrder.rgba);
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(rgba, image.width, image.height,
          ui.PixelFormat.rgba8888, completer.complete);
      return (image: image, rgba: rgba, display: await completer.future);
    }
  }

  /// The pictures decoded in the background while the child is still
  /// choosing, one at a time, so the one they tap is already waiting.
  Future<void> _prewarmPages() async {
    for (final cat in _categories) {
      for (final page in cat.pages) {
        if (!mounted) return;
        await _pageArt(page.imagePath);
        // A frame between pictures, so the gallery keeps scrolling smoothly.
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }
  }

  /// Straight from the edited pixel buffer to a displayable [ui.Image] — no
  /// PNG encode/decode round trip. That round trip ran synchronously on
  /// every bucket fill, undo and (once the eraser started touching this
  /// same bitmap) every drag frame; compressing a whole page-sized image
  /// that often is exactly what made fills and erasing feel laggy.
  Future<ui.Image> _imageToUi(img.Image image) async {
    final bytes = image.getBytes(order: img.ChannelOrder.rgba);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      bytes,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  String _autoSaveKey(String pageName) {
    String studentId = 'guest';
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      studentId = userProvider.userProfile?.lrn ?? 'guest';
      if (studentId.isEmpty) studentId = 'guest';
    } catch (_) {}
    final revision = _pictureRevisions[pageName];
    final page = revision == null ? pageName : '${pageName}_v$revision';
    return 'kulay_autosave_${studentId}_$page';
  }

  /// Pages whose picture has been replaced. A coloring saved on the old
  /// picture would be painted over the new one, so a new revision gives the
  /// page a fresh save of its own.
  static const Map<String, int> _pictureRevisions = {
    // The flower in a pot (paint4.png) became a daisy (2026-10-13). The daisy
    // has its own file name: browsers had cached paint4.png and kept showing
    // the pot. The pot itself was then removed; it is still named in the
    // page's formerImagePaths so creations saved from it stay its own.
    // The page is shown as "Flower" but keeps this name, which its saves
    // are filed under.
    'Flower Basket': 2,
    // The elephant was redrawn (2026-10-16), under a new file name for the
    // same reason; paint3.png is gone and named in formerImagePaths.
    'Elephant': 2,
  };

  Future<String> _autoSaveImagePath(String pageName) async {
    final dir = await getApplicationDocumentsDirectory();
    final key = _autoSaveKey(pageName);
    return '${dir.path}/$key.png';
  }

  /// Saves the draft once the strokes pause, not after every one: each
  /// save encodes every stroke (and, with fills, the whole picture), which
  /// a weak phone felt as a hitch at the end of every line. Leaving the
  /// picture or finishing it saves at once (see [_flushAutoSave]).
  void _scheduleAutoSave() {
    _dirty = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), _autoSave);
  }

  /// A draft still waiting to be saved, saved now.
  Future<void> _flushAutoSave() async {
    if (!(_autoSaveTimer?.isActive ?? false)) return;
    _autoSaveTimer!.cancel();
    await _autoSave();
  }

  Timer? _autoSaveTimer;

  Future<void> _autoSave() async {
    if (_selectedPage == null) return;
    _dirty = true;
    final pageName = _selectedPage!.name;
    final key = _autoSaveKey(pageName);
    final prefs = await SharedPreferences.getInstance();

    // Save strokes
    final strokesJson = jsonEncode(_strokes.map((s) => s.toMap()).toList());
    await prefs.setString('${key}_strokes', strokesJson);
    await prefs.setDouble('${key}_side', _lastSide);

    // Save bucket-fill image. The web has no files, so there it is kept in
    // the preferences as text instead — before, every fill was lost on the
    // web as soon as the child left the page.
    //
    // Only when something was filled. Brush strokes are saved above; the
    // picture with no fill is just the page, and writing it out after every
    // stroke, then decoding it again on opening, was time for nothing.
    if (_coloredImage == null || _filledPixelsCount == 0) {
      await prefs.remove('${key}_imageData');
      await prefs.remove('${key}_imagePath');
    } else {
      try {
        final bytes = img.encodePng(_coloredImage!);
        if (kIsWeb) {
          await prefs.setString('${key}_imageData', base64Encode(bytes));
        } else {
          final path = await _autoSaveImagePath(pageName);
          await File(path).writeAsBytes(bytes);
          await prefs.setString('${key}_imagePath', path);
        }
      } catch (e) {
        debugPrint('Autosave image skipped: $e');
      }
    }

    // Save metadata
    await prefs.setInt('${key}_filledPixels', _filledPixelsCount);
    await prefs.setInt('${key}_color', _selectedColor.value);
    await prefs.setDouble('${key}_brushSize', _brushSize);
    await prefs.setBool('${key}_isEraser', _isEraser);
    _schedulePreview();
  }

  Future<void> _loadInProgressPreviews() async {
    final prefs = await SharedPreferences.getInstance();
    final found = <String, Uint8List>{};
    final empty = <String>[];
    for (final cat in _categories) {
      for (final page in cat.pages) {
        final key = _autoSaveKey(page.name);
        final saved = prefs.getString('${key}_preview');
        if (saved == null || saved.isEmpty) continue;
        // A card picture with no drawing behind it is left over, not work
        // in progress: dropped rather than shown.
        if (!kulayDraftHasContent(prefs, key)) {
          empty.add(page.name);
          continue;
        }
        try {
          found[page.name] = base64Decode(saved);
        } catch (_) {}
      }
    }
    for (final name in empty) {
      await _clearAutoSaveForPage(name);
    }
    if (!mounted) return;
    setState(() => _inProgress
      ..clear()
      ..addAll(found));
  }

  /// A short wait first: a stroke draws only once its stay-inside-the-lines
  /// mask is ready, and a picture taken at once would miss the last one.
  void _schedulePreview() {
    _previewTimer?.cancel();
    final page = _selectedPage;
    _previewKey = page == null ? null : _autoSaveKey(page.name);
    _previewTimer =
        Timer(const Duration(milliseconds: 600), () => _savePreview());
  }

  /// Pictures the canvas as it is now for the page's card.
  Future<void> _savePreview() async {
    _previewTimer?.cancel();
    final page = _selectedPage;
    if (page == null) return;
    final key = _autoSaveKey(page.name);
    final prefs = await SharedPreferences.getInstance();
    if (_strokes.isEmpty && _filledPixelsCount == 0) {
      // Cleared: the card goes back to the page itself.
      await prefs.remove('${key}_preview');
      if (mounted) setState(() => _inProgress.remove(page.name));
      return;
    }
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    try {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final bytes = data.buffer.asUint8List();
      await prefs.setString('${key}_preview', base64Encode(bytes));
      if (mounted) setState(() => _inProgress[page.name] = bytes);
    } catch (e) {
      debugPrint('Progress picture skipped: $e');
    }
  }

  Future<void> _loadAutoSave() async {
    final page = _selectedPage;
    if (page == null) return;
    final pageName = page.name;
    final key = _autoSaveKey(pageName);
    final prefs = await SharedPreferences.getInstance();

    final strokesJson = prefs.getString('${key}_strokes');
    final imagePath = prefs.getString('${key}_imagePath');
    final imageData = prefs.getString('${key}_imageData');
    final filledPixels = prefs.getInt('${key}_filledPixels');
    final colorVal = prefs.getInt('${key}_color');
    final brushSize = prefs.getDouble('${key}_brushSize');
    final isEraser = prefs.getBool('${key}_isEraser');
    final savedSide = prefs.getDouble('${key}_side');

    List<ColoringStroke>? loadedStrokes;
    img.Image? loadedColoredImage;
    ui.Image? loadedDisplayImage;

    if (strokesJson != null && strokesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(strokesJson);
        loadedStrokes = decoded
            .map((m) => ColoringStroke.fromMap(m as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error loading autosave strokes: $e');
      }
    }

    if (kIsWeb && imageData != null && imageData.isNotEmpty) {
      try {
        final decoded = await _decodeFast(base64Decode(imageData));
        if (decoded != null && _baseImage != null) {
          loadedColoredImage = decoded.image;
          loadedDisplayImage = decoded.display;
        }
      } catch (e) {
        debugPrint('Error loading autosave image: $e');
      }
    } else if (!kIsWeb && imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final decoded = await _decodeFast(await file.readAsBytes());
          if (decoded != null && _baseImage != null) {
            loadedColoredImage = decoded.image;
            loadedDisplayImage = decoded.display;
          }
        }
      } catch (e) {
        debugPrint('Error loading autosave image: $e');
      }
    }

    // Another page opened while this one's colors were loading: they
    // belong to this one, not to that.
    if (!mounted || !identical(_selectedPage, page)) return;
    final oldBaked = _bakedStrokes;
    setState(() {
      if (loadedStrokes != null) {
        _strokes.clear();
        _strokePaths.clear();
        _strokes.addAll(loadedStrokes);
        // A one-time cost per loaded stroke, unlike rebuilding every
        // stroke's path on every repaint — see [_strokePaths].
        _strokePaths.addAll(loadedStrokes.map(_buildPathFromPoints));
        _bakedStrokes = null;
        _bakedCount = 0;
        // Drawn on a canvas of this size; rescaled once the canvas is laid
        // out — see [_drawingSurface].
        _strokesDrawnAtSide = savedSide;
      }
      if (loadedColoredImage != null) _coloredImage = loadedColoredImage;
      if (loadedDisplayImage != null) _displayImage = loadedDisplayImage;
      if (filledPixels != null) _filledPixelsCount = filledPixels;
      if (colorVal != null) _selectedColor = Color(colorVal);
      // Snapped to one of the three sizes the buttons offer. A drawing
      // saved before the slider was replaced can carry any value between 5
      // and 50, and an unsnapped 37 would leave all three buttons looking
      // unselected — the child could see no brush was chosen while one
      // plainly was.
      if (brushSize != null) _brushSize = _snapBrush(brushSize);
      if (isEraser != null) _isEraser = isEraser;
      _isLoadingAutoSave = false;
      _showLoadingOverlay = false;
    });
    _loadingOverlayTimer?.cancel();
    oldBaked?.dispose();
  }

  Future<void> _clearAutoSaveForPage(String pageName) async {
    final key = _autoSaveKey(pageName);
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('${key}_strokes');
    await prefs.remove('${key}_imagePath');
    await prefs.remove('${key}_imageData');
    await prefs.remove('${key}_filledPixels');
    await prefs.remove('${key}_color');
    await prefs.remove('${key}_brushSize');
    await prefs.remove('${key}_isEraser');
    await prefs.remove('${key}_side');
    await prefs.remove('${key}_preview');
    if (mounted) setState(() => _inProgress.remove(pageName));

    try {
      final imagePath = await _autoSaveImagePath(pageName);
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Autosave file cleanup skipped: $e');
    }
  }

  Future<void> _clearAutoSave() async {
    if (_selectedPage == null) return;
    await _clearAutoSaveForPage(_selectedPage!.name);
  }

  Offset _localToImageCoords(Offset local, double side) {
    if (_baseImage == null) return Offset.zero;
    final imgW = _baseImage!.width.toDouble();
    final imgH = _baseImage!.height.toDouble();
    final imgRatio = imgW / imgH;

    double drawW, drawH, offsetX, offsetY;
    if (imgRatio > 1.0) {
      drawW = side;
      drawH = side / imgRatio;
      offsetX = 0;
      offsetY = (side - drawH) / 2;
    } else {
      drawH = side;
      drawW = side * imgRatio;
      offsetX = (side - drawW) / 2;
      offsetY = 0;
    }

    final x = ((local.dx - offsetX) / drawW * imgW)
        .toInt()
        .clamp(0, _baseImage!.width - 1);
    final y = ((local.dy - offsetY) / drawH * imgH)
        .toInt()
        .clamp(0, _baseImage!.height - 1);
    return Offset(x.toDouble(), y.toDouble());
  }

  // ── Stay-inside-the-lines masks ────────────────────────────────────────────
  // Each brush stroke is clipped to the outlined region where it started, so
  // young children can scribble freely without the color crossing the lines.
  // Masks are cached per region (children recolor the same area repeatedly).
  // Room for every region of a busy drawing, so reopening one searches each
  // region once; a mask is about a megabyte, so not unbounded.
  static const int _maskCacheLimit = 16;
  final List<_RegionMask> _maskCache = [];

  Future<ui.Image?> _computeRegionMask(Offset local) async {
    final base = _baseImage;
    final px = _baseRgba;
    if (base == null || px == null) return null;
    final w = base.width;
    final h = base.height;
    final coords = _localToImageCoords(local, _lastSide);
    int sx = coords.dx.toInt().clamp(0, w - 1);
    int sy = coords.dy.toInt().clamp(0, h - 1);

    // Pixels straight from the RGBA bytes, four per pixel. A getPixel per
    // pixel made an object each time, and a reopened drawing waits on one
    // search per brushed region before its strokes can show.
    bool isPaintable(int x, int y) {
      final o = (y * w + x) * 4;
      if (px[o + 3] < 50) return false;
      final lum = 0.299 * px[o] + 0.587 * px[o + 1] + 0.114 * px[o + 2];
      return lum >= 100;
    }

    // If the child starts on the outline itself, hop to the nearest open
    // pixel so the stroke clips to the region they meant to color.
    if (!isPaintable(sx, sy)) {
      bool found = false;
      for (int r = 1; r <= 8 && !found; r++) {
        for (int dy = -r; dy <= r && !found; dy++) {
          for (int dx = -r; dx <= r && !found; dx++) {
            if (dx.abs() != r && dy.abs() != r) continue;
            final nx = sx + dx, ny = sy + dy;
            if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
            if (isPaintable(nx, ny)) {
              sx = nx;
              sy = ny;
              found = true;
            }
          }
        }
      }
      if (!found) return null;
    }

    for (final m in _maskCache) {
      if (m.bits[sy * w + sx] != 0) return m.image;
    }

    // BFS over similar pixels — same rules as the bucket fill.
    final so = (sy * w + sx) * 4;
    final startR = px[so];
    final startG = px[so + 1];
    final startB = px[so + 2];
    final startA = px[so + 3];
    const threshold = 40;

    final visited = Uint8List(w * h);
    final bits = Uint8List(w * h);
    // Each pixel joins the queue at most once, so a fixed array holds it.
    final queue = Int32List(w * h);
    int head = 0, tail = 0;
    queue[tail++] = sy * w + sx;
    visited[sy * w + sx] = 1;

    while (head < tail) {
      final idx = queue[head++];
      final o = idx * 4;
      final a = px[o + 3];
      if (a < 50 ||
          (px[o] - startR).abs() > threshold ||
          (px[o + 1] - startG).abs() > threshold ||
          (px[o + 2] - startB).abs() > threshold ||
          (a - startA).abs() > threshold) {
        continue;
      }
      bits[idx] = 1;

      final x = idx % w;
      final y = idx ~/ w;
      if (x + 1 < w && visited[idx + 1] == 0) {
        visited[idx + 1] = 1;
        queue[tail++] = idx + 1;
      }
      if (x > 0 && visited[idx - 1] == 0) {
        visited[idx - 1] = 1;
        queue[tail++] = idx - 1;
      }
      if (y + 1 < h && visited[idx + w] == 0) {
        visited[idx + w] = 1;
        queue[tail++] = idx + w;
      }
      if (y > 0 && visited[idx - w] == 0) {
        visited[idx - w] = 1;
        queue[tail++] = idx - w;
      }
    }

    // Dilate the region a couple of pixels so the color tucks under the
    // anti-aliased edge of the line instead of leaving a white gap.
    var cur = bits;
    for (int pass = 0; pass < 2; pass++) {
      final next = Uint8List.fromList(cur);
      for (int y = 0; y < h; y++) {
        final row = y * w;
        for (int x = 0; x < w; x++) {
          if (cur[row + x] != 0) continue;
          if ((x > 0 && cur[row + x - 1] != 0) ||
              (x < w - 1 && cur[row + x + 1] != 0) ||
              (y > 0 && cur[row - w + x] != 0) ||
              (y < h - 1 && cur[row + w + x] != 0)) {
            next[row + x] = 1;
          }
        }
      }
      cur = next;
    }

    final rgba = Uint8List(w * h * 4);
    for (int i = 0; i < w * h; i++) {
      if (cur[i] != 0) {
        final o = i * 4;
        rgba[o] = 255;
        rgba[o + 1] = 255;
        rgba[o + 2] = 255;
        rgba[o + 3] = 255;
      }
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        rgba, w, h, ui.PixelFormat.rgba8888, completer.complete);
    final image = await completer.future;

    if (_maskCache.length >= _maskCacheLimit) _maskCache.removeAt(0);
    _maskCache.add(_RegionMask(cur, image));
    return image;
  }

  Future<void> _applyRegionMaskToStroke(Offset firstPoint) async {
    final mask = await _computeRegionMask(firstPoint);
    if (!mounted) return;
    // Resolved either way — a null mask means the finger came down
    // somewhere the artwork has no paintable region (the background, or
    // too far from one), and that stroke should draw nothing at all rather
    // than fall back to unclipped. See StrokePainter._draw.
    var resolvedWhileCommitted = false;
    setState(() {
      if (_activeStroke != null &&
          _activeStroke!.points.isNotEmpty &&
          _activeStroke!.points.first == firstPoint) {
        _activeStroke = _activeStroke!.copyWith(mask: mask, maskResolved: true);
      } else {
        final idx = _strokes.lastIndexWhere((s) =>
            !s.isEraser &&
            !s.maskResolved &&
            s.points.isNotEmpty &&
            s.points.first == firstPoint);
        if (idx >= 0) {
          _strokes[idx] =
              _strokes[idx].copyWith(mask: mask, maskResolved: true);
          // Only once it is sitting in _strokes rather than still being
          // dragged — see _rebakeStrokes's own doc comment on why an
          // active stroke is never a candidate for baking.
          resolvedWhileCommitted = true;
        }
      }
    });
    if (resolvedWhileCommitted) unawaited(_rebakeStrokes());
  }

  Future<void> _rebuildStrokeMasks() async {
    for (int i = 0; i < _strokes.length; i++) {
      final s = _strokes[i];
      if (s.isEraser || s.maskResolved || s.points.isEmpty) continue;
      final mask = await _computeRegionMask(s.points.first);
      if (!mounted) return;
      setState(() =>
          _strokes[i] = _strokes[i].copyWith(mask: mask, maskResolved: true));
    }
    unawaited(_rebakeStrokes());
  }

  /// Flattens every settled stroke below [_bakedCount] up through the last
  /// one that is now settled too, into [_bakedStrokes] — so the live
  /// painter only ever draws the handful finished since the last bake, plus
  /// whichever stroke is still moving under the child's finger, regardless
  /// of how long the coloring session has run.
  ///
  /// Called once per finished stroke rather than awaited by it: baking is
  /// itself an async round trip through the raster thread, and the child's
  /// next stroke does not wait for that. Nothing is lost either way — a
  /// stroke past [_bakedCount] is still drawn individually until whichever
  /// call catches it up.
  Future<void> _rebakeStrokes() async {
    final side = _lastSide;
    if (side <= 0) return;

    // Only strokes settled enough to draw exactly once, ever — the same
    // rule StrokePainter itself applies to skip a stroke still waiting on
    // its mask. Left for the next call, once that resolves.
    var target = _bakedCount;
    while (target < _strokes.length &&
        (_strokes[target].isEraser || _strokes[target].maskResolved)) {
      target++;
    }
    if (target <= _bakedCount) return;
    final startCount = _bakedCount;

    // At the screen's own pixels, one for one, up to 1536 across: sharp,
    // and the cheapest thing to draw every frame. Baked at the canvas's
    // logical size (about 360), every finished stroke was enlarged about
    // three times on a phone and went soft and blocky the moment the
    // finger lifted.
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final scale = math.min(dpr, 1536 / side);
    final px = (side * scale).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(side, side);
    canvas.scale(scale);
    canvas.saveLayer(Offset.zero & size, Paint());
    final baked = _bakedStrokes;
    if (baked != null) StrokePainter.drawBaked(canvas, baked, size);
    for (int i = startCount; i < target; i++) {
      StrokePainter.drawStroke(canvas, _strokes[i],
          i < _strokePaths.length ? _strokePaths[i] : null, size);
    }
    canvas.restore();
    final image = await recorder.endRecording().toImage(px, px);

    // The canvas may have been cleared, undone, or reloaded while this was
    // rendering — any of those resets _bakedCount behind this call's back,
    // which makes the image just produced stale (it is missing the reset,
    // or it bakes strokes a fresh drawing no longer has). Only apply it if
    // nothing moved _bakedCount while it was in flight.
    if (!mounted || _bakedCount != startCount) {
      image.dispose();
      return;
    }
    final oldBaked = _bakedStrokes;
    setState(() {
      _bakedStrokes = image;
      _bakedCount = target;
    });
    oldBaked?.dispose();
  }

  /// Image pixels per on-screen pixel, so a brush size chosen on the
  /// (small, fixed) canvas maps to the right radius on the (often much
  /// larger) source bitmap.
  double _imageScaleFactor(double side) {
    final base = _baseImage;
    if (base == null || side <= 0) return 1.0;
    final imgW = base.width.toDouble();
    final imgH = base.height.toDouble();
    final imgRatio = imgW / imgH;
    final drawW = imgRatio > 1.0 ? side : side * imgRatio;
    return drawW <= 0 ? 1.0 : imgW / drawW;
  }

  /// Drag-erasing: restores every pixel from [_baseImage] within a
  /// [_brushSize]-wide circle around [localPosition], directly on the
  /// bucket-filled bitmap — the same one the eraser previously left
  /// untouched, which is why it looked broken on anything coloured with the
  /// bucket tool (the app's main way of colouring).
  ///
  /// A fast swipe can land its pointer-move events a brush-width or more
  /// apart, so stamping only at each event left a trail of separate dots
  /// instead of one erased stroke. [_lastEraseLocalPoint] lets the next
  /// call walk the segment from there to here and stamp along the way, the
  /// same way [_onCanvasPointerDown]/[_onCanvasPointerMove] already do for
  /// this — [_onCanvasPointerDown] resets it to null so the very first
  /// touch of a stroke is a single stamp, not a segment from wherever the
  /// last stroke ended.
  void _eraseCircleAtLocalPoint(Offset localPosition) {
    final image = _coloredImage;
    final base = _baseImage;
    if (image == null || base == null) return;

    if (!_eraseSnapshotPushedForStroke) {
      _eraseSnapshotPushedForStroke = true;
      if (_bucketUndoImages.length >= 10) {
        _bucketUndoImages.removeAt(0);
        _bucketUndoPixelCounts.removeAt(0);
      }
      _bucketUndoImages.add(image.clone());
      _bucketUndoPixelCounts.add(_filledPixelsCount);
    }

    final radius =
        ((_brushSize / 2) * _imageScaleFactor(_lastSide)).round().clamp(
              1,
              4000,
            );

    final prev = _lastEraseLocalPoint;
    _lastEraseLocalPoint = localPosition;
    if (prev == null) {
      _eraseCircleStamp(image, base, localPosition, radius);
    } else {
      final localStepPx = (_brushSize / 2).clamp(3.0, 40.0);
      final steps =
          ((localPosition - prev).distance / localStepPx).ceil().clamp(
                1,
                80,
              );
      for (int i = 1; i <= steps; i++) {
        final p = Offset.lerp(prev, localPosition, i / steps)!;
        _eraseCircleStamp(image, base, p, radius);
      }
    }

    _scheduleEraseDisplayUpdate();
  }

  void _eraseCircleStamp(
    img.Image image,
    img.Image base,
    Offset localPosition,
    int radius,
  ) {
    final coords = _localToImageCoords(localPosition, _lastSide);
    final cx = coords.dx.toInt();
    final cy = coords.dy.toInt();

    final w = image.width, h = image.height;
    final minX = (cx - radius).clamp(0, w - 1);
    final maxX = (cx + radius).clamp(0, w - 1);
    final minY = (cy - radius).clamp(0, h - 1);
    final maxY = (cy + radius).clamp(0, h - 1);
    final r2 = radius * radius;

    for (int y = minY; y <= maxY; y++) {
      final dy = y - cy;
      for (int x = minX; x <= maxX; x++) {
        final dx = x - cx;
        if (dx * dx + dy * dy > r2) continue;
        final basePixel = base.getPixel(x, y);
        final pixel = image.getPixel(x, y);
        pixel.r = basePixel.r;
        pixel.g = basePixel.g;
        pixel.b = basePixel.b;
        pixel.a = basePixel.a;
      }
    }
  }

  /// Coalesces display refreshes during a drag so a fast swipe doesn't pile
  /// up overlapping PNG-to-texture conversions — at most one is in flight,
  /// and one more always runs after it to catch up to the latest pixels.
  void _scheduleEraseDisplayUpdate() {
    if (_eraseDisplayUpdateInFlight) {
      _eraseDisplayUpdatePending = true;
      return;
    }
    final image = _coloredImage;
    if (image == null) return;
    _eraseDisplayUpdateInFlight = true;
    _imageToUi(image).then((uiImg) {
      _eraseDisplayUpdateInFlight = false;
      if (!mounted) return;
      setState(() => _displayImage = uiImg);
      if (_eraseDisplayUpdatePending) {
        _eraseDisplayUpdatePending = false;
        _scheduleEraseDisplayUpdate();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Save
  // ─────────────────────────────────────────────────────────────────────────

  /// A creation's picture: the saved file on the device that made it, else
  /// the small copy kept with it (all a creation restored from the cloud
  /// has), else the page it was colored on.
  Widget _creationPicture(MyCreation creation) {
    Widget fallback() =>
        Icon(LucideIcons.image, size: 40, color: Colors.grey.shade300);
    Widget memory() {
      if (creation.base64Image.isEmpty) return fallback();
      try {
        return Image.memory(base64Decode(creation.base64Image),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => fallback());
      } catch (_) {
        return fallback();
      }
    }

    // A former picture is no longer in the app; its page's current one is.
    String current(String path) {
      for (final cat in _categories) {
        for (final page in cat.pages) {
          if (page.formerImagePaths.contains(path)) return page.imagePath;
        }
      }
      return path;
    }

    Widget asset(String path) => Image.asset(current(path),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback());

    final path = creation.thumbnailPath;
    if (path.isNotEmpty && !path.startsWith('assets/') && !kIsWeb) {
      return Image.file(File(path),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => memory());
    }
    if (creation.base64Image.isNotEmpty) return memory();
    if (path.startsWith('assets/')) return asset(path);
    if (creation.sourcePagePath.startsWith('assets/')) {
      return asset(creation.sourcePagePath);
    }
    return fallback();
  }

  Future<Map<String, String>> _captureThumbnailData() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        return {'path': _selectedPage!.imagePath, 'base64': ''};
      }

      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return {'path': _selectedPage!.imagePath, 'base64': ''};
      }

      final pngBytes = byteData.buffer.asUint8List();

      // The small copy first, and the file on its own. The web has no
      // documents folder: getApplicationDocumentsDirectory threw there, the
      // small copy was never made, and every creation in My Creations showed
      // the blank page instead of what the child had colored.
      String path = _selectedPage!.imagePath;
      if (!kIsWeb) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final filePath =
              '${dir.path}/creation_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(filePath).writeAsBytes(pngBytes);
          path = filePath;
        } catch (e) {
          debugPrint('Error saving creation file: $e');
        }
      }

      String base64Str = '';
      try {
        final decoded = img.decodeImage(pngBytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 300);
          final jpegBytes = img.encodeJpg(resized, quality: 60);
          base64Str = base64Encode(jpegBytes);
        }
      } catch (e) {
        debugPrint('Error encoding base64 thumbnail: $e');
      }

      return {'path': path, 'base64': base64Str};
    } catch (e) {
      debugPrint('Error capturing thumbnail: $e');
      return {'path': _selectedPage!.imagePath, 'base64': ''};
    }
  }

  /// The newest creation colored on [page]'s current picture, if any. One
  /// colored on a picture the page has since replaced does not count: its
  /// colors belong to a drawing that is no longer there.
  MyCreation? _latestCreationOn(ColoringPage page) {
    MyCreation? latest;
    for (final c in _myCreations) {
      if (!page.owns(c)) continue;
      if (c.sourcePagePath.isNotEmpty && c.sourcePagePath != page.imagePath) {
        continue;
      }
      if (latest == null || c.date.isAfter(latest.date)) latest = c;
    }
    return latest;
  }

  /// Whether [pageName] has coloring in progress that was not saved yet.
  ///
  /// An empty one does not count: a saved drawing cleared and left without
  /// saving opened blank while its card still showed the saved colors.
  /// Clearing without saving changes nothing that was saved, so the saved
  /// drawing opens — as its card shows — and the empty copy is dropped.
  Future<bool> _hasAutoSave(String pageName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _autoSaveKey(pageName);
    if (kulayDraftHasContent(prefs, key)) return true;
    // Nothing on it: whatever is left of it (a card picture, say) goes.
    await _clearAutoSaveForPage(pageName);
    return false;
  }

  /// A creation's title in the language the child is using now. The name
  /// saved with it is in whatever language was on when it was saved, so a
  /// child who switched to English still saw "Bulaklak" in My Creations.
  String _creationTitle(MyCreation creation) {
    for (final cat in _categories) {
      for (final page in cat.pages) {
        if (page.owns(creation)) return _localizedPageName(page.name);
      }
    }
    return creation.name;
  }

  /// A category's name in the reader's language; it showed in English
  /// ("Flowers", "Toys") whatever the language.
  String _categoryLabel(String name) {
    final l10n = AppLocalizations.of(context)!;
    switch (name) {
      case 'Animals':
        return l10n.catAnimals;
      case 'Flowers':
        return l10n.catFlowers;
      case 'Fruits':
        return l10n.catFruits;
      case 'Toys':
        return l10n.catToys;
      default:
        return name;
    }
  }

  String _localizedPageName(String name) {
    final l10n = AppLocalizations.of(context)!;
    switch (name) {
      case 'Puppy':
        return l10n.pagePuppy;
      case 'Cat':
        return l10n.pageKuting;
      case 'Elephant':
        return l10n.pageElepante;
      case 'Flower Basket':
        return l10n.pageFlowerBasket;
      case 'Rose':
        return l10n.pageRose;
      case 'Apple':
        return l10n.pageMansanas;
      case 'Banana':
        return l10n.pageSaging;
      case 'Teddy Bear':
        return l10n.pageTeddyBear;
      case 'Race Car':
        return l10n.pageRaceCar;
      default:
        return name;
    }
  }

  // One-tap save: no typing needed — a daycare child can't use a keyboard,
  // so the artwork is named after its coloring page automatically.
  Future<void> _saveCreation() async {
    _commitClear();
    // The picture is about to be saved whole and its draft cleared; a draft
    // save still waiting would bring the draft back after.
    _autoSaveTimer?.cancel();
    // Brush strokes AND bucket fills both count as coloring.
    if (_strokes.isEmpty && _filledPixelsCount == 0) {
      _snack(AppLocalizations.of(context)!.colorSomethingFirst);
      return;
    }
    if (kulayNeedsBake(_strokes)) await _bakeStrokesIntoFill();
    if (!mounted) return;

    final autoName = _localizedPageName(_selectedPage!.name);
    final thumbData = await _captureThumbnailData();
    final thumbnailPath = thumbData['path'] ?? _selectedPage!.imagePath;
    final base64Img = thumbData['base64'] ?? '';
    final elapsed = _coloringStartTime != null
        ? DateTime.now().difference(_coloringStartTime!).inSeconds
        : 0;
    if (!mounted) return;

    late MyCreation creation;
    if (_editingCreation != null) {
      // Update existing creation in-place
      final idx = _myCreations.indexOf(_editingCreation!);
      if (idx >= 0) {
        creation = MyCreation(
          name: _editingCreation!.name,
          date: DateTime.now(),
          thumbnailPath: thumbnailPath,
          sourcePagePath: _selectedPage!.imagePath,
          base64Image:
              base64Img.isNotEmpty ? base64Img : _editingCreation!.base64Image,
          strokes: List.from(_strokes),
          fillImage: _encodeFill(),
          canvasSide: _lastSide,
          isFavorite: _editingCreation!.isFavorite,
          stars: _editingCreation!.stars,
          durationSeconds: _editingCreation!.durationSeconds + elapsed,
        );
        _myCreations[idx] = creation;
        // The picture saved last time is replaced, not kept beside the new
        // one: every re-save used to leave its old file behind, a few
        // hundred kilobytes each, for good.
        final oldPath = _editingCreation!.thumbnailPath;
        if (!kIsWeb &&
            oldPath.isNotEmpty &&
            oldPath != thumbnailPath &&
            !oldPath.startsWith('assets/')) {
          try {
            File(oldPath).deleteSync();
          } catch (_) {}
        }
      } else {
        creation = _editingCreation!;
      }
      setState(() => _editingCreation = null);
    } else {
      creation = MyCreation(
        name: autoName,
        date: DateTime.now(),
        thumbnailPath: thumbnailPath,
        sourcePagePath: _selectedPage!.imagePath,
        base64Image: base64Img,
        strokes: List.from(_strokes),
        fillImage: _encodeFill(),
        canvasSide: _lastSide,
        durationSeconds: elapsed,
      );
      setState(() => _myCreations.add(creation));

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('kulay_total_creations',
            (prefs.getInt('kulay_total_creations') ?? 0) + 1);
      } catch (e) {
        debugPrint('Error updating parents prefs: $e');
      }
    }

    // The Parents screen's "Recent Coloring" should reflect the latest save
    // regardless of whether it was a new page or a resumed one — this used
    // to live only in the new-creation branch above, so finishing a page the
    // child had started earlier never updated it.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kulay_last_colored', _selectedPage!.name);
    } catch (e) {
      debugPrint('Error updating parents prefs: $e');
    }

    // Sync to UserProvider — under the page's own category. It was the
    // category last opened, which a picture reopened from My Creations
    // need not be in, and the page was then recorded at index -1.
    bool newStar = false;
    final place = _placeOf(_selectedPage!);
    if (mounted && place != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      newStar = !userProvider.isKulayPageCompleted(place.$1.name, place.$2) &&
          prefs.getBool(
                  UserProvider.kulayStarredKey(place.$1.name, place.$2)) !=
              true;
      if (!mounted) return;
      userProvider.updateKulayProgress('coloring', true,
          category: place.$1.name, index: place.$2);
    }

    _saveCreationsToHive();
    _clearAutoSave();
    _previewTimer?.cancel();
    _dirty = false;
    // Time from here on is the next session's, not added twice.
    _coloringStartTime = DateTime.now();
    if (!mounted) return;
    // The picture stays open under the card: finishing used to send the
    // child back to the list in the middle of coloring. Finishing again now
    // updates this same creation.
    setState(() => _editingCreation = creation);
    await _showFinished(creation, newStar: newStar);
  }

  /// The card a finished picture gets, in place of the rating question that
  /// used to stand in the way: confetti, the picture, "+1 ★" when it earned
  /// one, three hearts to tap if the child wants to, and the way on — the
  /// next picture not colored yet, My Creations, or back to this one.
  Future<void> _showFinished(MyCreation creation,
      {required bool newStar}) async {
    final loc = AppLocalizations.of(context)!;
    final page = _selectedPage;
    if (page == null) return;
    final next = _nextUnfinished(page);
    Sfx.play(Sfx.pop);
    final confetti =
        ConfettiController(duration: const Duration(milliseconds: 1500));
    if (!MediaQuery.of(context).disableAnimations) confetti.play();

    final choice = await showDialog<_AfterFinish>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialog) => Stack(
          alignment: Alignment.center,
          children: [
            FunDialog(
              child: FunDialogCard(
                frame: FunFrame.purple,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FunTitle(loc.coloringGreatJob),
                  const SizedBox(height: 12),
                  Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: const Color(0xFFFFD54F), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF282850).withOpacity(0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: _creationPicture(creation),
                        ),
                      ),
                    ),
                    if (newStar)
                      const Positioned(
                          right: -18, top: -14, child: _PlusOneStar()),
                  ]),
                  const SizedBox(height: 14),
                  // Liking it is up to the child: nothing waits on it.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final on = i < (creation.stars ?? 0);
                      return GestureDetector(
                        onTap: () {
                          setDialog(() {
                            final k = i + 1;
                            final now = creation.stars == k ? k - 1 : k;
                            creation.stars = now == 0 ? null : now;
                          });
                          _saveCreationsToHive();
                        },
                        child: AnimatedScale(
                          scale: on ? 1.12 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            width: 46,
                            height: 46,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF0F3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.favorite_rounded,
                                size: 26,
                                color: on
                                    ? const Color(0xFFFF4F7B)
                                    : const Color(0xFFD9D3DC)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (next != null)
                    _nextPictureButton(next.$2, next.$1,
                        () => Navigator.pop(dialogContext, _AfterFinish.next))
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FunPillButton(
                        label: loc.allPicturesDone,
                        icon: LucideIcons.party_popper,
                        colors: FunColors.purple,
                        onTap: () =>
                            Navigator.pop(dialogContext, _AfterFinish.home),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _softButton(
                          LucideIcons.folder_open,
                          loc.myCreations,
                          () =>
                              Navigator.pop(dialogContext, _AfterFinish.mine)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _softButton(
                          LucideIcons.brush,
                          loc.colorMore,
                          () =>
                              Navigator.pop(dialogContext, _AfterFinish.more)),
                    ),
                  ]),
                ]),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: _palette,
              ),
            ),
          ],
        ),
      ),
    );
    confetti.dispose();
    if (!mounted) return;

    switch (choice) {
      case _AfterFinish.next:
        final (c, nextPage) = next!;
        await _leaveColoring();
        if (!mounted) return;
        _openCategoryAt(c);
        await _openPage(nextPage);
      case _AfterFinish.mine:
        _returnToCreations = true;
        await _leaveColoring();
      case _AfterFinish.home:
        await _leaveColoring();
        if (mounted) setState(() => _openCategory = null);
      case _AfterFinish.more:
      case null:
        break;
    }
  }

  /// The way on from a finished picture: the next one, shown as itself.
  Widget _nextPictureButton(
      ColoringPage page, int catIndex, VoidCallback onTap) {
    final loc = AppLocalizations.of(context)!;
    const colors = FunColors.purple;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.top, colors.bottom],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: colors.edge, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _pageThumb(page),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.nextPicture,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 20,
                      fontVariations: [FontVariation('wght', 650)],
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                Text(
                    '${_localizedPageName(page.name)} · '
                    '${_categoryLabel(_categories[catIndex].name)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                    )),
              ],
            ),
          ),
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
        ]),
      ),
    );
  }

  /// A quieter way on, under the next picture.
  Widget _softButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: const Color(0xFF5B49D8)),
          const SizedBox(height: 3),
          Text(label,
              // Two lines: "Ang Aking mga Likha" does not fit one.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2A5C))),
        ]),
      ),
    );
  }

  /// Leaves the open picture for the list — or for My Creations, when it
  /// was opened from there.
  ///
  /// It used to ask "Save your coloring?" first. Nothing is lost either
  /// way — the coloring is kept, and the page's card shows it in progress
  /// with Continue — so the question was only one more thing to read and
  /// one more tap on every way out.
  Future<void> _leaveColoring() async {
    if (_selectedPage == null) return;
    _commitClear();
    await _flushAutoSave();
    if (!mounted) return;
    if (_previewTimer?.isActive ?? false) await _savePreview();
    if (!mounted) return;
    setState(() {
      _selectedPage = null;
      _editingCreation = null;
      _dirty = false;
      if (_returnToCreations) _selectedTab = 1;
      _returnToCreations = false;
    });
  }

  /// The bucket fills as PNG text, or empty when nothing was filled.
  String _encodeFill() {
    final colored = _coloredImage;
    if (colored == null || _filledPixelsCount == 0) return '';
    try {
      return base64Encode(img.encodePng(colored));
    } catch (e) {
      debugPrint('Fill not kept: $e');
      return '';
    }
  }

  Future<void> _loadCreations() async {
    try {
      final box = await Hive.openBox('userProgress');
      List? savedRaw = box.get('coloring_creations');
      if (savedRaw != null) {
        // Creations of a page the app no longer has are deleted for good,
        // saved or not, with their picture files.
        final removed = savedRaw
            .where((c) => c is Map && UserProvider.isRemovedColoringCreation(c))
            .toList();
        if (removed.isNotEmpty) {
          for (final c in removed) {
            final path = '${(c as Map)['thumbnailPath'] ?? ''}';
            if (!kIsWeb && path.isNotEmpty && !path.startsWith('assets/')) {
              try {
                final file = File(path);
                if (await file.exists()) await file.delete();
              } catch (_) {}
            }
          }
          savedRaw = savedRaw.where((c) => !removed.contains(c)).toList();
          await box.put('coloring_creations', savedRaw);
        }
        if (!mounted) return;
        final creations = savedRaw;
        setState(() {
          _myCreations.clear();
          for (var item in creations) {
            if (item is Map) {
              final strokesRaw = item['strokes'] as List?;
              final List<ColoringStroke> strokes = [];
              if (strokesRaw != null) {
                for (var s in strokesRaw) {
                  final pointsRaw = s['points'] as List?;
                  final List<Offset> points = [];
                  if (pointsRaw != null) {
                    for (var p in pointsRaw) {
                      points.add(Offset(p['dx'], p['dy']));
                    }
                  }
                  strokes.add(ColoringStroke(
                    points: points,
                    color: Color(s['color']),
                    size: s['size'],
                    isEraser: s['isEraser'] ?? false,
                  ));
                }
              }
              _myCreations.add(MyCreation(
                name: item['name'],
                date: DateTime.fromMillisecondsSinceEpoch(item['date']),
                // The cloud copy keeps no thumbnail path — a file on the
                // device that saved it — so one restored at login has none.
                thumbnailPath: item['thumbnailPath'] as String? ?? '',
                sourcePagePath: item['sourcePagePath'] ?? '',
                base64Image: item['base64Image'] ?? '',
                strokes: strokes,
                fillImage: item['fillImage'] as String? ?? '',
                canvasSide: (item['canvasSide'] as num?)?.toDouble() ?? 0,
                isFavorite: item['isFavorite'] ?? false,
                stars: item['stars'],
                durationSeconds: item['durationSeconds'] ?? 0,
              ));
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading creations: $e');
    }
    await _syncKulayProgressWithCreations();
    unawaited(_sweepOrphanPictures());
  }

  /// Deletes saved-picture files no creation points to any more — left by
  /// re-saves before they replaced their file, and by children who used
  /// this device before. Pictures of work kept aside for a child to come
  /// back to (see UserProvider's stash) are kept.
  Future<void> _sweepOrphanPictures() async {
    if (kIsWeb) return;
    try {
      // Only against a list read in full: if loading failed part way, the
      // files it missed are still someone's pictures.
      final stored = Hive.box('userProgress').get('coloring_creations');
      if (stored is List && stored.length != _myCreations.length) return;
      final used = <String>{for (final c in _myCreations) c.thumbnailPath};
      if (Hive.isBoxOpen('stashedWork') ||
          await Hive.boxExists('stashedWork')) {
        final stash = await Hive.openBox('stashedWork');
        for (final entry in stash.values) {
          final kept =
              ((entry as Map?)?['hive'] as Map?)?['coloring_creations'];
          if (kept is List) {
            for (final c in kept) {
              if (c is Map) used.add('${c['thumbnailPath'] ?? ''}');
            }
          }
        }
      }
      // Compared by file name: a path saved on one version of the folder
      // need not spell it the same way as the listing does.
      final usedNames = {for (final u in used) u.split(RegExp(r'[\\/]')).last};
      final dir = await getApplicationDocumentsDirectory();
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.startsWith('creation_') &&
            name.endsWith('.png') &&
            !usedNames.contains(name)) {
          f.deleteSync();
        }
      }
    } catch (e) {
      debugPrint('Picture sweep skipped: $e');
    }
  }

  Future<void> _syncKulayProgressWithCreations() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Until the cloud's drawings are in, a finished page with no drawing
    // here is most often one whose drawing has not come down yet — and
    // taking its mark off wrote "not done" to the cloud for every phone.
    if (!userProvider.creationsPulled) return;
    for (final cat in _categories) {
      for (int i = 0; i < cat.pages.length; i++) {
        final page = cat.pages[i];
        final hasCreation = _myCreations.any(page.owns);
        if (!hasCreation && userProvider.isKulayPageCompleted(cat.name, i)) {
          await userProvider.updateKulayProgress('coloring', false,
              category: cat.name, index: i);
        }
      }
    }
  }

  Future<void> _saveCreationsToHive() async {
    try {
      final box = await Hive.openBox('userProgress');
      final List<Map<String, dynamic>> data = _myCreations.map((c) {
        return {
          'name': c.name,
          'date': c.date.millisecondsSinceEpoch,
          'thumbnailPath': c.thumbnailPath,
          'sourcePagePath': c.sourcePagePath,
          'base64Image': c.base64Image,
          'fillImage': c.fillImage,
          'canvasSide': c.canvasSide,
          'isFavorite': c.isFavorite,
          'stars': c.stars,
          'durationSeconds': c.durationSeconds,
          'strokes': c.strokes.map((s) {
            return {
              'points': s.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
              'color': s.color.value,
              'size': s.size,
              'isEraser': s.isEraser,
            };
          }).toList(),
        };
      }).toList();
      await box.put('coloring_creations', data);
    } catch (e) {
      debugPrint('Error saving creations: $e');
      // Read before the await, not after: this catch runs at exactly the
      // moment the screen is most likely to have gone, because the save it
      // failed at is the one that happens as the child leaves.
      if (!mounted) return;
      _snack(AppLocalizations.of(context)!.errorSaveLocal, isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Auto-dismiss THIS dialog's route. Popping the navigator blindly
        // after the delay would close the whole coloring screen whenever the
        // child had already dismissed the dialog by tapping outside it.
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });
        // The same card as the other Color Fun dialogs: a green tick on a
        // gold coin for "saved" and "deleted", a red mark for a failure.
        final tone =
            isError ? const Color(0xFFE5484D) : const Color(0xFF2E9E3E);
        return FunDialog(
          child: FunDialogCard(
            frame: isError ? FunFrame.coral : FunFrame.purple,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            // Full width, like the other dialogs, however short the message.
            child: SizedBox(
              width: double.infinity,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD86B), Color(0xFFE8A21E)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0xFFC8861A), offset: Offset(0, 4)),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(tone, Colors.white, 0.85),
                    ),
                    child: Icon(
                        isError
                            ? Icons.priority_high_rounded
                            : Icons.check_rounded,
                        color: tone,
                        size: 52),
                  ),
                ),
                const SizedBox(height: 16),
                Text(msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 23,
                      fontVariations: [FontVariation('wght', 650)],
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2A5C),
                    )),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colouring = _selectedTab == 0 && _selectedPage != null;
    final inCategory = _selectedTab == 0 && _openCategory != null;
    // Drawings from the child's other phone can arrive after this screen
    // has read its list — it read it once, so they never showed, while
    // their check marks did. Read again when they come, but not under a
    // page that is being colored.
    final creationsVersion =
        context.select<UserProvider, int>((p) => p.creationsVersion);
    _seenCreationsVersion ??= creationsVersion;
    if (creationsVersion != _seenCreationsVersion && !colouring) {
      _seenCreationsVersion = creationsVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCreations();
      });
    }
    // The phone's own back button goes through the same question as the
    // arrow, instead of leaving the coloring book outright — and from a
    // category it goes back to the categories.
    return PopScope(
      canPop: !colouring && !inCategory,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (colouring) {
          _leaveColoring();
        } else {
          setState(() => _openCategory = null);
        }
      },
      child: _scaffold(),
    );
  }

  Widget _scaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: _appBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FE), Color(0xFFEDF1F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: IndexedStack(
          index: _selectedTab,
          children: [_buildColoringTab(), _buildCreationsTab()],
        ),
      ),
    );
  }

  /// The title bar, which changes shape once a picture is open.
  ///
  /// Colouring used to happen under two stacked navigation bands — this one
  /// with its tab row, and a second bar below it holding a back arrow and the
  /// picture's name. Together they took more height than the tools, and left
  /// the drawing itself under 40% of the screen on a phone.
  ///
  /// The tabs pick between colouring and the gallery, and there is nothing to
  /// pick while a picture is open — the way out is the arrow. So the picture
  /// takes the title, its arrow becomes this bar's, and the tab row is not
  /// built at all. The drawing gets the band back.
  PreferredSizeWidget _appBar() {
    final colouring = _selectedTab == 0 && _selectedPage != null;
    final inCategory = _selectedTab == 0 && _openCategory != null;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      leading: CustomBackButton(
        iconColor: AppColors.textDark,
        onPressed: colouring
            ? _leaveColoring
            : inCategory
                ? () => setState(() => _openCategory = null)
                : () => Navigator.pop(context),
      ),
      title: Text(
          colouring
              ? _localizedPageName(_selectedPage!.name)
              : inCategory
                  ? _categoryLabel(_categories[_openCategory!].name)
                  : AppLocalizations.of(context)!.coloringBook,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
      // Inside a category the title already says where the child is; the
      // tabs come back with the categories.
      bottom: colouring || inCategory
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: Colors.white,
                child: Row(children: [
                  _tabBtn(0, LucideIcons.brush,
                      AppLocalizations.of(context)!.color),
                  _tabBtn(1, LucideIcons.folder_open,
                      AppLocalizations.of(context)!.myCreations),
                ]),
              ),
            ),
    );
  }

  Widget _tabBtn(int idx, IconData icon, String label) {
    final on = _selectedTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: on
                ? const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 16, color: on ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            // Flexible with ellipsis: the Filipino label ("Aking mga
            // Likha") alone measures 195px against roughly 128px actually
            // available per tab on a 320px phone once this button's own
            // 16px side margins are subtracted — a plain Text here would
            // overflow the row outright rather than just look cramped.
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.bold : FontWeight.w500,
                      color: on ? Colors.white : Colors.grey.shade600)),
            ),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  COLORING TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildColoringTab() {
    if (_selectedPage == null) return DesignScale(child: _gallery());
    return _canvas();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GALLERY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _gallery() {
    if (_openCategory == null) return _categoryOverview();
    final cat = _categories[_openCategory!];
    final pages = cat.pages;

    return pages.isEmpty
        ? Center(
            child: Text(AppLocalizations.of(context)!.noResults,
                style: TextStyle(color: Colors.grey.shade400)))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.76,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16),
            itemCount: pages.length,
            itemBuilder: (_, i) => _pageCard(pages[i], cat),
          );
  }

  /// Whether a page counts as finished: saved here, or finished on the
  /// child's account.
  bool _pageFinished(ColoringCategory cat, int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return _myCreations.any(cat.pages[index].owns) ||
        userProvider.isKulayPageCompleted(cat.name, index);
  }

  /// A page as the child last left it: the unsaved coloring, the saved one,
  /// or the blank line art.
  Widget _pageThumb(ColoringPage page) {
    final inProgress = _inProgress[page.name];
    if (inProgress != null) {
      return Image.memory(inProgress,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium);
    }
    final saved = _latestCreationOn(page);
    if (saved != null) return _creationPicture(saved);
    return Image.asset(page.imagePath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const SizedBox());
  }

  void _openCategoryAt(int i) {
    setState(() {
      _selectedCategory = i;
      _openCategory = i;
    });
  }

  /// The four categories, each with its pages fanned out and how many are
  /// finished — and, above them, the page the child left half colored.
  Widget _categoryOverview() {
    final loc = AppLocalizations.of(context)!;

    // The first page with unsaved coloring on it, to carry on with.
    (int, ColoringPage)? started;
    for (int c = 0; c < _categories.length && started == null; c++) {
      for (final page in _categories[c].pages) {
        if (_inProgress[page.name] != null) {
          started = (c, page);
          break;
        }
      }
    }

    final stars = Provider.of<UserProvider>(context).getKulayProgress()['stars']
            as int? ??
        0;
    const possible = UserProvider.kulayStarCeiling;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ModuleTally(
          picture: 'assets/images/star_gold.webp',
          done: stars,
          total: possible,
          label: (n) => loc.starsOfPossible(n, possible),
        ),
        if (started != null) _continueStrip(started.$1, started.$2, loc),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (int r = 0; r < _categories.length; r += 2)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: r + 2 < _categories.length ? 12 : 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _categoryCard(r, loc)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: r + 1 < _categories.length
                              ? _categoryCard(r + 1, loc)
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _continueStrip(int catIndex, ColoringPage page, AppLocalizations loc) {
    final cat = _categories[catIndex];
    return GestureDetector(
      onTap: () {
        _openCategoryAt(catIndex);
        _openPage(page);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF282850).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF0F5), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _pageThumb(page),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.inProgress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8A90A0))),
                Text(_localizedPageName(page.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: cat.color,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(loc.lessonContinue,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  Widget _categoryCard(int i, AppLocalizations loc) {
    final cat = _categories[i];
    final n = cat.pages.length;
    int done = 0;
    for (int p = 0; p < n; p++) {
      if (_pageFinished(cat, p)) done++;
    }

    // The pages fanned out like cards in a hand, the middle one on top.
    final fan = <Widget>[];
    final order = List<int>.generate(n, (k) => k)
      ..sort((a, b) =>
          ((a - (n - 1) / 2).abs()).compareTo((b - (n - 1) / 2).abs()) * -1);
    for (final k in order) {
      final turn = (k - (n - 1) / 2) * 12;
      fan.add(Align(
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(turn * 1.4, 4),
          child: Transform.rotate(
            angle: turn * 3.14159 / 180,
            child: Container(
              width: 70,
              height: 84,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEF0F5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF282850).withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _pageThumb(cat.pages[k]),
            ),
          ),
        ),
      ));
    }

    return GestureDetector(
      onTap: () => _openCategoryAt(i),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF282850).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 96, child: Stack(children: fan)),
            const SizedBox(height: 8),
            Text(_categoryLabel(cat.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(loc.levelsDone(done, n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A90A0))),
            const Spacer(),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: n == 0 ? 0 : done / n,
                minHeight: 9,
                backgroundColor: const Color(0xFFECEEF4),
                valueColor: AlwaysStoppedAnimation(cat.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(bool inProgress) {
    final loc = AppLocalizations.of(context)!;
    final color = inProgress ? const Color(0xFFE8A21E) : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(inProgress ? LucideIcons.brush : LucideIcons.check,
            size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(inProgress ? loc.inProgress : loc.completed,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  /// Opens one page to color: with the child's saved colors if they have
  /// saved it, else with whatever they left unsaved on it.
  Future<void> _openPage(ColoringPage page) async {
    _commitClear();
    _returnToCreations = false;
    // A page the child has saved opens with their saved colors, and Save
    // updates that creation. It used to open blank — the in-progress
    // copy is cleared on save — with Save turned into "View", so the
    // saved coloring looked lost and coloring it again was never kept.
    final saved = _latestCreationOn(page);
    final unsaved = await _hasAutoSave(page.name);
    if (saved != null && !unsaved) {
      if (!mounted) return;
      _editCreation(page, saved);
      return;
    }
    if (!mounted) return;
    _clearZoom();
    final oldBaked = _bakedStrokes;
    setState(() {
      _selectedPage = page;
      _strokes.clear();
      _strokePaths.clear();
      _activeStroke = null;
      _baseImage = null;
      _coloredImage = null;
      _displayImage = null;
      _filledPixelsCount = 0;
      _isLoadingAutoSave = true;
      _coloringStartTime = DateTime.now();
      _bakedStrokes = null;
      _bakedCount = 0;
      // Unsaved changes to a saved creation: Save updates that creation.
      _editingCreation = saved;
      _dirty = unsaved;
      _showLoadingOverlay = false;
    });
    _loadingOverlayTimer?.cancel();
    _loadingOverlayTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _isLoadingAutoSave) {
        setState(() => _showLoadingOverlay = true);
      }
    });
    oldBaked?.dispose();
    _maskCache.clear();
    _loadPageImage().then((_) async {
      if (!identical(_selectedPage, page)) return;
      await _loadAutoSave();
      if (identical(_selectedPage, page)) await _rebuildStrokeMasks();
    });
  }

  Widget _pageCard(ColoringPage page, ColoringCategory cat) {
    // Check if this page is already completed (local creations + provider)
    final pageIndex = cat.pages.indexOf(page);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isCompleted = _myCreations.any(page.owns) ||
        (pageIndex >= 0 &&
            userProvider.isKulayPageCompleted(cat.name, pageIndex));
    final savedHere = _latestCreationOn(page);
    final inProgress = _inProgress[page.name];

    return GestureDetector(
      onTap: () => _openPage(page),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isCompleted
                    ? Colors.green.withOpacity(0.5)
                    : cat.color.withOpacity(0.25),
                width: 2),
            boxShadow: [
              BoxShadow(
                  color: cat.color.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20))),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      // The child's own coloring once they have saved one —
                      // the same creation that opens when the card is
                      // tapped. A finished page showed only its blank line
                      // art, greyed, so the work looked lost.
                      child: inProgress != null
                          ? Image.memory(inProgress,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.high)
                          : savedHere != null
                              ? _creationPicture(savedHere)
                              : Image.asset(
                                  page.imagePath,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (_, __, ___) => Icon(
                                      LucideIcons.palette,
                                      size: 52,
                                      color: cat.color.withOpacity(0.4)),
                                ),
                    ),
                  ),
                  if (isCompleted && inProgress == null)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green,
                        child: Icon(LucideIcons.check,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  // Still being colored. The tick says finished on its own;
                  // a "Completed" pill beside it said it twice, and over a
                  // page with new coloring both said opposite things.
                  if (inProgress != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _statusPill(true),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: WordSafeText(_localizedPageName(page.name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CANVAS SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _canvas() {
    return Column(children: [
      Expanded(
        child: Stack(
          children: [
            _drawingArea(),
            if (_pendingClear != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Center(child: _clearedNote()),
              ),
            if (_isLoadingAutoSave && _showLoadingOverlay)
              Container(
                color: Colors.white.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.loadingArtwork,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      _toolPanel(),
    ]);
  }

  /// Under the picture straight after Clear: what happened, and Undo.
  Widget _clearedNote() {
    final loc = AppLocalizations.of(context)!;
    final fromCreations = _pendingClear?.creations.isNotEmpty ?? false;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2340),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(LucideIcons.trash_2, size: 18, color: Colors.white),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
              fromCreations ? loc.removedFrom(loc.myCreations) : loc.cleared,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _restoreCleared,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.undo_2,
                  size: 16, color: Color(0xFF1F2340)),
              const SizedBox(width: 4),
              Text(loc.undo,
                  style: const TextStyle(
                      color: Color(0xFF1F2340),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _drawingArea() {
    return Container(
      color: const Color(0xFFDDE0EA),
      child: Stack(children: [
        Positioned.fill(
          child: Center(
            child: LayoutBuilder(builder: (ctx, cst) {
              // Was capped at 500. Nothing about the drawing wants a
              // ceiling below what the screen can actually show — the cap
              // only ever left a band of empty grey down each side.
              final side = cst.biggest.shortestSide.clamp(200.0, 900.0);
              return InteractiveViewer(
                transformationController: _transformationController,
                // Only ever true while two fingers are down, so a single
                // finger dragging across the picture colours it instead of
                // sliding it away.
                panEnabled: _twoFingerGesture,
                scaleEnabled: _twoFingerGesture,
                minScale: 1.0,
                maxScale: 5.0,
                clipBehavior: Clip.none,
                child: SizedBox(
                    width: side, height: side, child: _drawingSurface(side)),
              );
            }),
          ),
        ),

        // ── Ripple ──────────────────────────────────────────────────
        if (_lastPos != null)
          AnimatedBuilder(
            animation: _rippleAnim,
            builder: (_, __) {
              final r = 55 * _rippleAnim.value;
              return Positioned(
                left: _lastPos!.dx - r,
                top: _lastPos!.dy - r,
                child: Opacity(
                  opacity: (1 - _rippleAnim.value).clamp(0.0, 1.0),
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _selectedColor, width: 2.5),
                    ),
                  ),
                ),
              );
            },
          ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DRAWING SURFACE
  //
  //  Stack order (bottom → top):
  //    1. White background
  //    2. PNG image  (the line art)
  //    3. CustomPaint strokes  ← drawn ON TOP so color is always visible
  //    4. GestureDetector captures touch on the top-most layer
  // ─────────────────────────────────────────────────────────────────────────

  /// The canvas side the current [_strokes] were drawn at, when they came
  /// from a save made on a canvas that may not be this size. Null once they
  /// match the canvas.
  double? _strokesDrawnAtSide;

  /// Moves [_strokes] onto a canvas of [side]: they are kept in canvas
  /// pixels, so a drawing reopened on another phone, a turned screen or a
  /// resized window would otherwise land off its regions.
  void _fitStrokesTo(double side) {
    final from = _strokesDrawnAtSide;
    if (from == null) return;
    _strokesDrawnAtSide = null;
    if (from <= 0 || (from - side).abs() < 0.5 || _strokes.isEmpty) return;
    final f = side / from;
    final scaled = [for (final s in _strokes) s.scaled(f)];
    _strokes
      ..clear()
      ..addAll(scaled);
    _strokePaths
      ..clear()
      ..addAll(scaled.map(_buildPathFromPoints));
    final oldBaked = _bakedStrokes;
    _bakedStrokes = null;
    _bakedCount = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldBaked?.dispose();
      if (!mounted) return;
      _maskCache.clear();
      _rebuildStrokeMasks();
    });
  }

  Widget _drawingSurface(double side) {
    _lastSide = side;
    _fitStrokesTo(side);
    return RepaintBoundary(
      key: _canvasKey,
      child: ClipRect(
        child: Stack(fit: StackFit.expand, children: [
          // 1. White background
          Container(color: Colors.white),

          // 2. Image — bucket-filled display or original PNG
          IgnorePointer(
            child: _displayImage != null
                ? RawImage(
                    image: _displayImage,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  )
                : Image.asset(
                    _selectedPage!.imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.image_off,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(AppLocalizations.of(context)!.imageNotFound,
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 13)),
                          ]),
                    ),
                  ),
          ),

          // 3. Color strokes drawn ON TOP — one finger always draws, whether
          //    it taps (a single dot) or drags (a stroke), the same way a
          //    real crayon only ever marks the paper by moving across it.
          //    Two fingers: nothing is drawn — the pinch reaches the
          //    InteractiveViewer above instead, because a Listener observes
          //    pointers without claiming them in the gesture arena.
          Listener(
            onPointerDown: (e) {
              _activePointers.add(e.pointer);

              // A second finger means the child wants to move or enlarge the
              // picture. Drop the line the first finger had begun, otherwise
              // the act of zooming leaves a stray mark behind.
              if (_activePointers.length >= 2) {
                setState(() {
                  _twoFingerGesture = true;
                  _activeStroke = null;
                  _lastPos = null;
                });
                return;
              }
              _onCanvasPointerDown(e);
            },
            onPointerMove: (e) {
              if (_twoFingerGesture) return;
              _onCanvasPointerMove(e);
            },
            onPointerUp: (e) {
              _activePointers.remove(e.pointer);
              if (_twoFingerGesture) {
                // Stay in zoom until the very last finger lifts, so the one
                // still resting on the screen does not start drawing.
                if (_activePointers.isEmpty) {
                  setState(() => _twoFingerGesture = false);
                }
                return;
              }
              _onCanvasPointerUp(e);
            },
            onPointerCancel: (e) {
              _activePointers.remove(e.pointer);
              if (_activePointers.isEmpty && _twoFingerGesture) {
                setState(() => _twoFingerGesture = false);
              }
              if (_activeStroke != null) setState(() => _activeStroke = null);
            },
            child: CustomPaint(
              painter: StrokePainter(
                strokes: _strokes,
                strokePaths: _strokePaths,
                activeStroke: _activeStroke,
                activeStrokePath: _activeStrokePath,
                bakedImage: _bakedStrokes,
                bakedCount: _bakedCount,
                repaint: _strokeTick,
              ),
              size: Size(side, side),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 4. The outlines again, over the coloring: the color's edge then
          //    sits under the line instead of over it, so the region mask's
          //    steps never show and the color never thins a line. Its own
          //    layer, drawn once — not repainted with every stroke.
          if (_artCache[_selectedPage!.imagePath]?.lines case final lines?)
            IgnorePointer(
              child: RepaintBoundary(
                child: RawImage(
                  image: lines,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.low,
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Single-finger drawing ──────────────────────────────────────────────────

  /// Builds a stroke's whole curve in one pass, the same shape
  /// [_onCanvasPointerMove]/[_onCanvasPointerUp] build incrementally while
  /// drawing. Only ever run once per stroke — here, at autosave load — so
  /// the from-scratch reconstruction this replaced everywhere else is fine.
  Path _buildPathFromPoints(ColoringStroke stroke) {
    final points = stroke.points;
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    if (points.length > 1) {
      path.lineTo(points.last.dx, points.last.dy);
    }
    return path;
  }

  void _onCanvasPointerDown(PointerDownEvent e) {
    // Coloring again after Clear makes the Clear final.
    _commitClear();
    _eraseSnapshotPushedForStroke = false;
    _lastEraseLocalPoint = null;
    _activeStrokePath = Path()..moveTo(e.localPosition.dx, e.localPosition.dy);
    _activeStrokePrevPoint = e.localPosition;
    _activeStrokePointCount = 1;
    setState(() {
      _activeStroke = ColoringStroke(
        points: [e.localPosition],
        color: _selectedColor,
        size: _brushSize,
        isEraser: _isEraser,
      );
      _lastPos = e.localPosition;
    });
    // Clip this stroke to the region where it started so the
    // color can't cross the black lines.
    if (!_isEraser) _applyRegionMaskToStroke(e.localPosition);
  }

  void _onCanvasPointerMove(PointerMoveEvent e) {
    if (_activeStroke == null) return;
    // A point under 2 px from the last one kept adds nothing a finger can
    // see, and every point is stored with the picture for good — a slow
    // hand made thousands of them, and the saved picture grew with every
    // session it was colored in.
    if ((e.localPosition - _activeStroke!.points.last).distance < 2.0) {
      if (_isEraser) _eraseCircleAtLocalPoint(e.localPosition);
      return;
    }
    // Extends the curve by exactly the new segment — see
    // [_activeStrokePath]'s doc comment for why this replaced rebuilding
    // the whole curve from point zero on every move.
    _activeStrokePointCount++;
    if (_activeStrokePointCount >= 3) {
      final prev = _activeStrokePrevPoint!;
      final mid = Offset(
        (prev.dx + e.localPosition.dx) / 2,
        (prev.dy + e.localPosition.dy) / 2,
      );
      _activeStrokePath!.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    _activeStrokePrevPoint = e.localPosition;
    // Added in place, and only the drawing repainted. Copying every point
    // into a new list and rebuilding the whole screen on each move grew
    // slower the longer the line, and weak phones stuttered mid-stroke.
    _activeStroke!.points.add(e.localPosition);
    _lastPos = e.localPosition;
    _strokeTick.value++;
    // A real drag (as opposed to the tap this may still turn out to be)
    // erases the bucket-filled bitmap too, not just the brush-stroke layer
    // — otherwise nothing visibly happened when erasing a tap-filled area.
    if (_isEraser) _eraseCircleAtLocalPoint(e.localPosition);
  }

  void _onCanvasPointerUp(PointerUpEvent e) {
    if (_activeStroke != null) {
      // Caps the curve at the actual last point — same reason the original
      // whole-path rebuild always closed with a lineTo to stroke.points.last
      // rather than ending on the final quadraticBezierTo's midpoint.
      if (_activeStrokePointCount >= 2) {
        final last = _activeStrokePrevPoint!;
        _activeStrokePath!.lineTo(last.dx, last.dy);
      }
      final finishedPath = _activeStrokePath;
      setState(() {
        _strokes.add(_activeStroke!);
        if (finishedPath != null) _strokePaths.add(finishedPath);
        _activeStroke = null;
      });
      _activeStrokePath = null;
      _activeStrokePrevPoint = null;
      _activeStrokePointCount = 0;
      _rippleController.forward(from: 0);
      _scheduleAutoSave();
      // A no-op if this stroke's mask (or, for an eraser, nothing) is not
      // resolved yet — _applyRegionMaskToStroke calls this again once it is.
      unawaited(_rebakeStrokes());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TOOL PANEL
  // ─────────────────────────────────────────────────────────────────────────

  Widget _toolPanel() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      // Room under the Done button: it is the last thing on the screen, and
      // with only a sliver below it it sat on the phone's edge and gesture
      // handle, where a thumb reaching for it brushes the handle instead.
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Color palette — drawn as crayons, each one named on its own
        // wrapper. All eight share the row, laid out in one line the same
        // way a real 8-crayon box is, rather than one of them scrolling out
        // of sight: a swipe a child has not discovered yet hides colours no
        // differently from not having them.
        SizedBox(
          height: 108,
          child: Row(
            children: List.generate(_palette.length, (i) {
              final c = _palette[i];
              final sel = !_isEraser && _selectedColor == c;
              return Expanded(
                child: CrayonSwatch(
                  color: c,
                  label: _paletteLabel(loc, i),
                  selected: sel,
                  onTap: () => setState(() {
                    _selectedColor = c;
                    _isEraser = false;
                  }),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 4),

        // Three brush sizes, not a slider.
        //
        // A slider asks for a press, a sideways travel and a release on an
        // 8-pixel thumb, and hands back a number the child has nothing to
        // compare against. Three buttons showing the actual dot they will
        // draw with is the same choice made in one tap, and the child can
        // see what each one does before choosing it.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _brushBtn(12, AppLocalizations.of(context)!.brushSmall),
            const SizedBox(width: 14),
            _brushBtn(30, AppLocalizations.of(context)!.brushMedium),
            const SizedBox(width: 14),
            _brushBtn(48, AppLocalizations.of(context)!.brushLarge),
          ],
        ),

        const SizedBox(height: 4),

        // The tools.
        //
        // This row held six: Fit, Eraser, Undo, Redo, Clear and Save. Redo is
        // gone, and Fit now appears only once the picture has actually been
        // pinched — until then it does nothing, and a button that does
        // nothing is one a child presses and learns to distrust.
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          if (_isZoomed)
            _tBtn(
              icon: LucideIcons.minimize,
              label: AppLocalizations.of(context)!.fitPicture,
              active: true,
              onTap: _resetZoom,
            ),
          _tBtn(
            icon: LucideIcons.eraser,
            label: AppLocalizations.of(context)!.eraser,
            tint: const Color(0xFFE76FB0),
            active: _isEraser,
            onTap: () => setState(() => _isEraser = !_isEraser),
          ),
          _tBtn(
              icon: LucideIcons.undo_2,
              label: AppLocalizations.of(context)!.undo,
              tint: const Color(0xFFA8B82E),
              active: false,
              disabled: _strokes.isEmpty &&
                  _bucketUndoImages.isEmpty &&
                  _pendingClear == null,
              onTap: _undo),
          _tBtn(
            icon: LucideIcons.trash_2,
            label: AppLocalizations.of(context)!.clear,
            tint: const Color(0xFFE5484D),
            active: false,
            onTap: _confirmClearAll,
          ),
        ]),
        const SizedBox(height: 8),
        // How a picture is finished, said in one big green button. It was
        // a round "Save" among the tools, the same size as Undo, and nothing
        // said that saving was how a picture got finished.
        SizedBox(
          width: double.infinity,
          child: FunPillButton(
            label: AppLocalizations.of(context)!.finishColoring,
            icon: LucideIcons.check,
            colors: FunColors.green,
            height: 48,
            onTap: _saveCreation,
          ),
        ),
      ]),
    );
  }

  /// One of the three brush sizes: a glossy ball as big as the size, in
  /// the design's orange, teal and purple, ringed when chosen. Shared with
  /// the eraser, which reads its radius off the same [_brushSize].
  Widget _brushBtn(double size, String label) {
    final selected = _brushSize == size;
    final ball = size == 12 ? 20.0 : (size == 30 ? 30.0 : 40.0);
    final color = size == 12
        ? const Color(0xFFF07A3A)
        : (size == 30 ? const Color(0xFF2E9DA6) : const Color(0xFFB04BD6));
    return GestureDetector(
      onTap: () => setState(() => _brushSize = size),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 52,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: ball + (selected ? 8 : 0),
              height: ball + (selected ? 8 : 0),
              padding: EdgeInsets.all(selected ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : Colors.transparent,
                border: selected ? Border.all(color: color, width: 2.5) : null,
                boxShadow: selected
                    ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)]
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.45),
                    radius: 0.9,
                    colors: [
                      Color.lerp(color, Colors.white, 0.55)!,
                      color,
                      Color.lerp(color, Colors.black, 0.25)!
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontVariations: const [FontVariation('wght', 600)],
                fontWeight: FontWeight.w600,
                color: selected ? color : const Color(0xFF3A3F5C))),
      ]),
    );
  }

  /// Asks before wiping the picture, in pictures.
  ///
  /// The old dialog was prose — a question, then a sentence explaining the
  /// consequence — put in front of a child who can read neither. It now leads
  /// with a large bin, and the two ways out are full-width buttons carrying a
  /// colour and an icon each: green back to colouring, red to start again.
  /// Keeping the drawing is the easier one to hit, because it is the one that
  /// cannot lose an hour of work.
  void _confirmClearAll() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => FunDialog(
        child: FunDialogCard(
          frame: FunFrame.purple,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // The bin on a gold coin.
            Container(
              width: 104,
              height: 104,
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD86B), Color(0xFFE8A21E)],
                ),
                boxShadow: [
                  BoxShadow(color: Color(0xFFC8861A), offset: Offset(0, 4)),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFE3E1),
                ),
                child: const Icon(LucideIcons.trash_2,
                    size: 46, color: Color(0xFFE5484D)),
              ),
            ),
            const SizedBox(height: 16),
            Text(loc.clearCanvasQuestion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 25,
                  fontVariations: [FontVariation('wght', 650)],
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2A5C),
                )),
            // A saved picture leaves My Creations too: shown, with the
            // picture, before the child says yes.
            if (_selectedPage != null &&
                _myCreations.any(_selectedPage!.owns)) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _pageThumb(_selectedPage!),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(loc.clearAlsoRemoves(loc.myCreations),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC53030))),
                ),
              ]),
            ],
            const SizedBox(height: 18),
            // Keeping the drawing is the easier one to hit, because it is
            // the one that cannot lose an hour of work.
            SizedBox(
              width: double.infinity,
              child: FunPillButton(
                label: loc.keepColoring,
                icon: LucideIcons.brush,
                colors: FunColors.green,
                onTap: () => Navigator.pop(dialogContext),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FunPillButton(
                label: loc.startOverYes,
                icon: LucideIcons.rotate_ccw,
                colors: FunColors.red,
                onTap: () {
                  Navigator.pop(dialogContext);
                  _wipePage();
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// A tool as the design draws it: a round pastel button in a ring of its
  /// own colour, the icon in that colour, its name under it. A tool that is
  /// on (the eraser) glows.
  Widget _tBtn(
      {required IconData icon,
      required String label,
      required bool active,
      required VoidCallback onTap,
      Color tint = const Color(0xFF5B8DEF),
      bool disabled = false}) {
    final ink = Color.lerp(tint, Colors.black, 0.25)!;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.35 : 1.0,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(tint, Colors.white, 0.82)!,
                  Color.lerp(tint, Colors.white, 0.5)!,
                ],
              ),
              border: Border.all(color: tint, width: 4),
              boxShadow: [
                BoxShadow(color: ink, offset: const Offset(0, 3)),
                if (active)
                  BoxShadow(
                      color: tint.withOpacity(0.7),
                      blurRadius: 12,
                      spreadRadius: 3),
              ],
            ),
            child: Icon(icon, color: ink, size: 26),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontVariations: const [FontVariation('wght', 600)],
                  fontWeight: FontWeight.w600,
                  color: active ? ink : const Color(0xFF3A3F5C))),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MY CREATIONS TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCreationsTab() {
    List<MyCreation> list = List.from(_myCreations);
    if (_sortMode == 1) {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else {
      list.sort((a, b) => b.date.compareTo(a.date));
    }

    if (list.isEmpty) return _emptyCreations();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Text(AppLocalizations.of(context)!.artworkCount(_myCreations.length),
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          _sc(0, AppLocalizations.of(context)!.sortRecent),
          const SizedBox(width: 6),
          _sc(1, 'A–Z'),
        ]),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.80,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16),
          itemCount: list.length,
          itemBuilder: (_, i) => _creationCard(list[i]),
        ),
      ),
    ]);
  }

  Widget _sc(int mode, String label) {
    final sel = _sortMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _sortMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14)),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _emptyCreations() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle),
          child: const Icon(LucideIcons.palette,
              size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: 18),
        Text(AppLocalizations.of(context)!.noArtworksYet,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context)!.colorPagePrompt,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 13)),
          onPressed: () => setState(() => _selectedTab = 0),
          icon: const Icon(LucideIcons.brush, color: Colors.white, size: 18),
          label: Text(AppLocalizations.of(context)!.startColoring,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _creationCard(MyCreation creation) {
    return GestureDetector(
      onTap: () => _showCreationDetail(creation),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  color: const Color(0xFFF0F1FF),
                  child: Center(
                      child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _creationPicture(creation),
                  )),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() => creation.isFavorite = !creation.isFavorite);
                    _saveCreationsToHive();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                        creation.isFavorite
                            ? LucideIcons.heart
                            : LucideIcons.heart,
                        color: creation.isFavorite
                            ? Colors.red
                            : Colors.grey.shade400,
                        size: 15),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 11),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_creationTitle(creation),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (creation.stars != null)
                Row(
                  children: [
                    // Hearts, as the finished card gives them.
                    ...List.generate(
                        3,
                        (i) => Icon(Icons.favorite_rounded,
                            size: 14,
                            color: i < creation.stars!
                                ? const Color(0xFFFF4F7B)
                                : const Color(0xFFE2DCE4))),
                  ],
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 4),
              Row(children: [
                Icon(LucideIcons.clock, size: 10, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(creation.formattedDuration,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                const Spacer(),
                Text(AppLocalizations.of(context)!.tapToView,
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showCreationDetail(MyCreation creation) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => FunDialog(
        child: Stack(clipBehavior: Clip.none, children: [
          FunDialogCard(
            frame: FunFrame.rainbow,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.only(right: 34),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_creationTitle(creation),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 24,
                        fontVariations: [FontVariation('wght', 650)],
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2A5C),
                      )),
                ),
              ),
              if (creation.stars != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // The hearts the finished card gave it.
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.favorite_rounded,
                          size: 26,
                          color: i < creation.stars!
                              ? const Color(0xFFFF4F7B)
                              : const Color(0xFFE2DCE4)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // The picture in a rainbow-edged frame.
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFC857),
                        Color(0xFF8FD7A0),
                        Color(0xFF6EC6F5),
                        Color(0xFFB58BF0),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      color: Colors.white,
                      child: _creationPicture(creation),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.auto_awesome,
                    size: 16, color: Color(0xFF5B7BE0)),
                const SizedBox(width: 6),
                Text(
                  '${creation.date.day}/${creation.date.month}/${creation.date.year}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontVariations: [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3550C8),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.auto_awesome,
                    size: 16, color: Color(0xFF5B7BE0)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: FunPillButton(
                    label: loc.edit,
                    icon: LucideIcons.pencil,
                    colors: FunColors.purple,
                    onTap: () {
                      Navigator.pop(dialogContext);
                      for (final cat in _categories) {
                        for (final page in cat.pages) {
                          if (page.owns(creation)) {
                            _editCreation(page, creation, fromCreations: true);
                            return;
                          }
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FunPillButton(
                    label: loc.delete,
                    icon: LucideIcons.trash_2,
                    colors: FunColors.red,
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _confirmDeleteCreation(creation);
                    },
                  ),
                ),
              ]),
            ]),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: FunCloseButton(onTap: () => Navigator.pop(dialogContext)),
          ),
        ]),
      ),
    );
  }

  /// Reopens [creation] on [page] with everything the child colored.
  ///
  /// A creation keeps its brush strokes, its bucket fills and the canvas
  /// size they were drawn at. One saved before the fills were kept starts
  /// from its own saved picture instead, with its strokes already in it —
  /// opening it on the bare line art, as Edit used to, lost every filled
  /// area. And one colored on a picture the page has since replaced (the
  /// old elephant, the old flower pot) opens the new picture fresh, as a new
  /// creation: its colors belong to a drawing that is no longer there.
  void _editCreation(ColoringPage page, MyCreation creation,
      {bool fromCreations = false}) {
    _commitClear();
    final place = _placeOf(page);
    final samePicture = creation.sourcePagePath.isEmpty ||
        creation.sourcePagePath == page.imagePath;
    final hasFill = creation.fillImage.isNotEmpty;
    // Saved with its canvas size: strokes and fills are kept apart, and one
    // with no fill simply had none. It was taken for an old creation, so a
    // brush-only drawing reopened as its small blurred copy with its strokes
    // gone, and every edit was made on top of that copy.
    final keepsParts = hasFill || creation.canvasSide > 0;
    final useStrokes =
        samePicture && (keepsParts || creation.base64Image.isEmpty);
    _clearZoom();
    final oldBaked = _bakedStrokes;
    setState(() {
      _selectedPage = page;
      _strokes.clear();
      _strokePaths.clear();
      if (useStrokes) {
        _strokes.addAll(creation.strokes);
        _strokePaths.addAll(creation.strokes.map(_buildPathFromPoints));
        _strokesDrawnAtSide =
            creation.canvasSide > 0 ? creation.canvasSide : null;
      }
      _bakedStrokes = null;
      _bakedCount = 0;
      // Counted afresh: the restored picture sets it below if it has fills.
      _filledPixelsCount = 0;
      _activeStroke = null;
      _editingCreation = samePicture ? creation : null;
      _dirty = false;
      _selectedTab = 0;
      _returnToCreations = fromCreations;
      // The page's own category, so finishing records the right page.
      if (place != null) {
        _selectedCategory = _categories.indexOf(place.$1);
        _openCategory = _selectedCategory;
      }
      _coloringStartTime = DateTime.now();
    });
    oldBaked?.dispose();
    _maskCache.clear();
    _loadPageImage().then((_) async {
      if (!mounted || !samePicture) {
        if (mounted) setState(() {});
        return;
      }
      final base = _baseImage;
      final source = hasFill
          ? creation.fillImage
          : (keepsParts ? '' : creation.base64Image);
      if (base != null && source.isNotEmpty) {
        try {
          var picture = (await _decodeFast(base64Decode(source)))?.image;
          if (picture != null) {
            if (picture.width != base.width || picture.height != base.height) {
              picture = img.copyResize(picture,
                  width: base.width,
                  height: base.height,
                  interpolation: img.Interpolation.average);
            }
            final display = await _imageToUi(picture);
            if (!mounted) return;
            setState(() {
              _coloredImage = picture;
              _displayImage = display;
              // Something is colored: Save must not say otherwise.
              if (_filledPixelsCount == 0) _filledPixelsCount = 1;
            });
          }
        } catch (e) {
          debugPrint('Could not restore the creation\'s colors: $e');
        }
      }
      if (!mounted) return;
      setState(() {});
      _rebuildStrokeMasks();
    });
  }

  void _confirmDeleteCreation(MyCreation creation) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => FunDialog(
        child: FunDialogCard(
          frame: FunFrame.coral,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.warning_rounded,
                  color: Color(0xFFF26B3A), size: 40),
              const SizedBox(width: 6),
              Flexible(child: FunTitle(loc.deleteArtwork, size: 28)),
            ]),
            const SizedBox(height: 10),
            Text(loc.confirmDeleteArtwork,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B2A5C))),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: FunPillButton(
                  label: loc.cancel,
                  colors: FunColors.grey,
                  onTap: () => Navigator.pop(dialogContext),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FunPillButton(
                  label: loc.delete,
                  colors: FunColors.red,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _deleteCreation(creation);
                  },
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  /// Deletes [creation] and every other saved copy of the same page, so the
  /// page goes back to blank and unticked in the gallery.
  ///
  /// Older versions made a new creation on every save of a page; deleting
  /// one left the others behind, and the card kept showing their colors and
  /// its check mark. The page is found by [ColoringPage.owns] — its former
  /// pictures and creations saved before they recorded a page count too —
  /// rather than only an exact page path, which missed those and reset
  /// nothing. A creation no page owns is deleted alone.
  Future<void> _deleteCreation(MyCreation creation) async {
    ColoringCategory? category;
    ColoringPage? page;
    for (final cat in _categories) {
      for (final p in cat.pages) {
        if (p.owns(creation)) {
          category = cat;
          page = p;
          break;
        }
      }
      if (page != null) break;
    }

    final doomed =
        page == null ? [creation] : _myCreations.where(page.owns).toList();
    setState(() {
      _myCreations.removeWhere(doomed.contains);
      if (doomed.contains(_editingCreation)) _editingCreation = null;
    });
    _saveCreationsToHive();
    for (final c in doomed) {
      if (kIsWeb ||
          c.thumbnailPath.isEmpty ||
          c.thumbnailPath.startsWith('assets/')) {
        continue;
      }
      try {
        File(c.thumbnailPath).deleteSync();
      } catch (e) {
        debugPrint('Error deleting thumbnail: $e');
      }
    }

    // The page itself: its unsaved coloring, its card picture, its tick.
    if (page != null && category != null) {
      await _clearAutoSaveForPage(page.name);
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateKulayProgress('coloring', false,
          category: category.name, index: category.pages.indexOf(page));
    }

    if (!mounted) return;
    _snack(AppLocalizations.of(context)!.artworkDeleted);
    await _syncKulayProgressWithCreations();
  }
}

/// A cached stay-inside-the-lines region: membership bits for fast lookup
/// plus the alpha mask image used to clip strokes.
/// A coloring picture, decoded: the pixels to read, the same pixels as raw
/// RGBA bytes for the region search, and an image ready to draw.
class _PageArt {
  final img.Image image;
  final Uint8List rgba;
  final ui.Image display;

  /// Just the outlines: black, as opaque as the picture is dark, clear
  /// where it is white — laid over the coloring.
  final ui.Image? lines;
  _PageArt(this.image, this.rgba, this.display, this.lines);
}

class _RegionMask {
  final Uint8List bits;
  final ui.Image image;
  _RegionMask(this.bits, this.image);
}

/// Where the finished card sends the child.
enum _AfterFinish { next, mine, home, more }

/// Everything one Clear took away, kept until Undo or until it is final.
class _ClearedPage {
  final ColoringPage page;
  final List<ColoringStroke> strokes;
  final List<Path> paths;
  final img.Image? colored;
  final int filled;
  final List<img.Image> bucketImages;
  final List<int> bucketCounts;

  /// The page's saved pictures, each with the place it had in My Creations.
  final List<(int, MyCreation)> creations;
  final MyCreation? editing;
  final bool dirty;
  final bool wasDone;

  const _ClearedPage({
    required this.page,
    required this.strokes,
    required this.paths,
    required this.colored,
    required this.filled,
    required this.bucketImages,
    required this.bucketCounts,
    required this.creations,
    required this.editing,
    required this.dirty,
    required this.wasDone,
  });
}

/// "+1 ★" by the finished picture, rising and fading as the star goes to
/// the child's count.
class _PlusOneStar extends StatelessWidget {
  const _PlusOneStar();

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D6),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
      ),
      child: const Text('+1 ★',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 20,
            fontVariations: [FontVariation('wght', 650)],
            fontWeight: FontWeight.w700,
            color: Color(0xFFE5A100),
          )),
    );
    if (still) return chip;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2200),
      builder: (_, t, child) {
        // Pops in, holds, then rises away.
        final rise = Curves.easeIn.transform(((t - 0.45) / 0.55).clamp(0, 1));
        final pop = Curves.elasticOut.transform((t / 0.3).clamp(0, 1));
        return Opacity(
          opacity: (1 - rise).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -90 * rise),
            child: Transform.scale(scale: 0.4 + 0.6 * pop, child: child),
          ),
        );
      },
      child: chip,
    );
  }
}
