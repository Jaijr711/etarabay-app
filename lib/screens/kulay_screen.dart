import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import '../widgets/custom_back_button.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  String getTimeAgoLocalized(BuildContext context) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.justNow;
    return AppLocalizations.of(context)!.timeAgo(diff.inMinutes);
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Strokes live in their own layer: the eraser punches transparent holes
    // in that layer (BlendMode.clear) so the line art underneath is never
    // touched — it only removes the child's own coloring.
    canvas.saveLayer(Offset.zero & size, Paint());
    final baked = bakedImage;
    if (baked != null) canvas.drawImage(baked, Offset.zero, Paint());
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
      // geometry used to display the line art.
      final imgW = mask.width.toDouble();
      final imgH = mask.height.toDouble();
      final ratio = imgW / imgH;
      final side = size.shortestSide;
      double drawW, drawH, offX = 0, offY = 0;
      if (ratio > 1) {
        drawW = side;
        drawH = side / ratio;
        offY = (side - drawH) / 2;
      } else {
        drawH = side;
        drawW = side * ratio;
        offX = (side - drawW) / 2;
      }
      canvas.drawImageRect(
        mask,
        Rect.fromLTWH(0, 0, imgW, imgH),
        Rect.fromLTWH(offX, offY, drawW, drawH),
        Paint()..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(StrokePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
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
  ColoringPage? _selectedPage;

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
  img.Image? _coloredImage;
  ui.Image? _displayImage;
  int _filledPixelsCount = 0;
  double _lastSide = 300;
  bool _isLoadingAutoSave = false;
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
          imagePath: 'assets/images/paint3.png',
          difficulty: 'Medium',
          timeEstimate: '8 min',
          colors: 2),
    ]),
    ColoringCategory(name: 'Flowers', icon: '🌸', color: Colors.pink, pages: [
      ColoringPage(
          name: 'Flower Basket',
          imagePath: 'assets/images/paint_daisy.png',
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
      ColoringPage(
          name: 'Soda Pop',
          imagePath: 'assets/images/paint9.png',
          difficulty: 'Easy',
          timeEstimate: '5 min',
          colors: 3),
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
    _audioPlayer.dispose();
    _rippleController.dispose();
    _zoomResetController.dispose();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _bakedStrokes?.dispose();
    AudioManager.instance.resumeHomeMusic();
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

  // ─────────────────────────────────────────────────────────────────────────
  //  Bucket fill helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadPageImage() async {
    if (_selectedPage == null) return;
    try {
      final data = await rootBundle.load(_selectedPage!.imagePath);
      final bytes = data.buffer.asUint8List();
      _baseImage = img.decodeImage(bytes);
      if (_baseImage == null) return;
      _coloredImage = _baseImage!.clone();
      _displayImage = await _imageToUi(_coloredImage!);
    } catch (e) {
      debugPrint('Error loading coloring image: $e');
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
  };

  Future<String> _autoSaveImagePath(String pageName) async {
    final dir = await getApplicationDocumentsDirectory();
    final key = _autoSaveKey(pageName);
    return '${dir.path}/$key.png';
  }

  Future<void> _autoSave() async {
    if (_selectedPage == null) return;
    final pageName = _selectedPage!.name;
    final key = _autoSaveKey(pageName);
    final prefs = await SharedPreferences.getInstance();

    // Save strokes
    final strokesJson = jsonEncode(_strokes.map((s) => s.toMap()).toList());
    await prefs.setString('${key}_strokes', strokesJson);

    // Save bucket-fill image. The web has no files, so there it is kept in
    // the preferences as text instead — before, every fill was lost on the
    // web as soon as the child left the page.
    if (_coloredImage != null) {
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
  }

  Future<void> _loadAutoSave() async {
    if (_selectedPage == null) return;
    final pageName = _selectedPage!.name;
    final key = _autoSaveKey(pageName);
    final prefs = await SharedPreferences.getInstance();

    final strokesJson = prefs.getString('${key}_strokes');
    final imagePath = prefs.getString('${key}_imagePath');
    final imageData = prefs.getString('${key}_imageData');
    final filledPixels = prefs.getInt('${key}_filledPixels');
    final colorVal = prefs.getInt('${key}_color');
    final brushSize = prefs.getDouble('${key}_brushSize');
    final isEraser = prefs.getBool('${key}_isEraser');

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
        final image = img.decodeImage(base64Decode(imageData));
        if (image != null && _baseImage != null) {
          loadedColoredImage = image;
          loadedDisplayImage = await _imageToUi(loadedColoredImage);
        }
      } catch (e) {
        debugPrint('Error loading autosave image: $e');
      }
    } else if (!kIsWeb && imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final image = img.decodeImage(bytes);
          if (image != null && _baseImage != null) {
            loadedColoredImage = image;
            loadedDisplayImage = await _imageToUi(loadedColoredImage);
          }
        }
      } catch (e) {
        debugPrint('Error loading autosave image: $e');
      }
    }

    if (!mounted) return;
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
    });
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
  static const int _maskCacheLimit = 8;
  final List<_RegionMask> _maskCache = [];

  Future<ui.Image?> _computeRegionMask(Offset local) async {
    final base = _baseImage;
    if (base == null) return null;
    final w = base.width;
    final h = base.height;
    final coords = _localToImageCoords(local, _lastSide);
    int sx = coords.dx.toInt().clamp(0, w - 1);
    int sy = coords.dy.toInt().clamp(0, h - 1);

    bool isPaintable(int x, int y) {
      final p = base.getPixel(x, y);
      if (p.a < 50) return false;
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
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
    final startPixel = base.getPixel(sx, sy);
    final startR = startPixel.r.toInt();
    final startG = startPixel.g.toInt();
    final startB = startPixel.b.toInt();
    final startA = startPixel.a.toInt();
    const threshold = 40;

    final visited = Uint8List(w * h);
    final bits = Uint8List(w * h);
    final qx = <int>[sx];
    final qy = <int>[sy];
    int head = 0;
    visited[sy * w + sx] = 1;

    while (head < qx.length) {
      final x = qx[head];
      final y = qy[head];
      head++;

      final p = base.getPixel(x, y);
      if (p.a < 50 ||
          (p.r - startR).abs() > threshold ||
          (p.g - startG).abs() > threshold ||
          (p.b - startB).abs() > threshold ||
          (p.a - startA).abs() > threshold) {
        continue;
      }
      bits[y * w + x] = 1;

      void tryAdd(int nx, int ny) {
        if (nx < 0 || nx >= w || ny < 0 || ny >= h) return;
        final idx = ny * w + nx;
        if (visited[idx] != 0) return;
        visited[idx] = 1;
        qx.add(nx);
        qy.add(ny);
      }

      tryAdd(x + 1, y);
      tryAdd(x - 1, y);
      tryAdd(x, y + 1);
      tryAdd(x, y - 1);
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

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(side, side);
    canvas.saveLayer(Offset.zero & size, Paint());
    final baked = _bakedStrokes;
    if (baked != null) canvas.drawImage(baked, Offset.zero, Paint());
    for (int i = startCount; i < target; i++) {
      StrokePainter.drawStroke(canvas, _strokes[i],
          i < _strokePaths.length ? _strokePaths[i] : null, size);
    }
    canvas.restore();
    final image =
        await recorder.endRecording().toImage(side.ceil(), side.ceil());

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

  void _showStarRatingDialog(MyCreation creation) {
    int selectedStars = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(AppLocalizations.of(context)!.rateYourArtwork,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.howManyStars,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedStars = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        idx <= selectedStars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 40,
                        color: idx <= selectedStars
                            ? const Color(0xFFFFB800)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
              onPressed: () {
                creation.stars = selectedStars > 0 ? selectedStars : null;
                _saveCreationsToHive();
                Navigator.pop(context);
                _snack(AppLocalizations.of(context)!.saved);
                final oldBaked = _bakedStrokes;
                setState(() {
                  _strokes.clear();
                  _strokePaths.clear();
                  _activeStroke = null;
                  _editingCreation = null;
                  _selectedPage = null;
                  _bakedStrokes = null;
                  _bakedCount = 0;
                });
                oldBaked?.dispose();
              },
              child: Text(AppLocalizations.of(context)!.done,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// A creation's picture: the saved file on the device that made it, else
  /// the small copy kept with it (all a creation restored from the cloud
  /// has), else the page it was colored on.
  Widget _creationPicture(MyCreation creation) {
    Widget fallback() => Icon(LucideIcons.image,
        size: 40, color: Colors.grey.shade300);
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
          final resized = img.copyResize(decoded, width: 220);
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

  bool _isCurrentPageSaved() {
    if (_selectedPage == null) return false;
    if (_editingCreation != null) return true;
    return _myCreations.any(_selectedPage!.owns);
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
      case 'Soda Pop':
        return l10n.pageSodaPop;
      default:
        return name;
    }
  }

  // One-tap save: no typing needed — a daycare child can't use a keyboard,
  // so the artwork is named after its coloring page automatically.
  Future<void> _saveCreation() async {
    // Brush strokes AND bucket fills both count as coloring.
    if (_strokes.isEmpty && _filledPixelsCount == 0) {
      _snack(AppLocalizations.of(context)!.colorSomethingFirst);
      return;
    }

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
          isFavorite: _editingCreation!.isFavorite,
          stars: _editingCreation!.stars,
          durationSeconds: _editingCreation!.durationSeconds + elapsed,
        );
        _myCreations[idx] = creation;
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

    // Sync to UserProvider
    if (mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final cat = _categories[_selectedCategory];
      final pageIndex = cat.pages.indexOf(_selectedPage!);
      userProvider.updateKulayProgress('coloring', true,
          category: cat.name, index: pageIndex);
    }

    _saveCreationsToHive();
    _clearAutoSave();
    if (mounted) {
      if (creation.stars == null) {
        _showStarRatingDialog(creation);
      } else {
        _snack(AppLocalizations.of(context)!.saved);
        final oldBaked = _bakedStrokes;
        setState(() {
          _strokes.clear();
          _strokePaths.clear();
          _activeStroke = null;
          _editingCreation = null;
          _selectedPage = null;
          _bakedStrokes = null;
          _bakedCount = 0;
        });
        oldBaked?.dispose();
      }
    }
  }

  Future<void> _loadCreations() async {
    try {
      final box = await Hive.openBox('userProgress');
      final List? savedRaw = box.get('coloring_creations');
      if (savedRaw != null) {
        setState(() {
          _myCreations.clear();
          for (var item in savedRaw) {
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
  }

  Future<void> _syncKulayProgressWithCreations() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: (isError ? Colors.red : AppColors.primary)
                      .withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isError ? Colors.red : AppColors.primary)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isError
                          ? LucideIcons.circle_alert
                          : LucideIcons.circle_check,
                      color: isError ? Colors.red : AppColors.primary,
                      size: 40),
                ),
                const SizedBox(height: 20),
                Text(msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
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

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      leading: CustomBackButton(
        iconColor: AppColors.textDark,
        onPressed: colouring
            ? () => setState(() {
                  _selectedPage = null;
                  _editingCreation = null;
                })
            : () => Navigator.pop(context),
      ),
      title: Text(
          colouring
              ? _localizedPageName(_selectedPage!.name)
              : AppLocalizations.of(context)!.coloringBook,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
      bottom: colouring
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
    if (_selectedPage == null) return _gallery();
    return _canvas();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GALLERY
  // ─────────────────────────────────────────────────────────────────────────

  IconData _categoryIcon(String name) {
    switch (name) {
      case 'Animals':
        return LucideIcons.paw_print;
      case 'Flowers':
        return LucideIcons.flower;
      case 'Fruits':
        return LucideIcons.apple;
      case 'Toys':
        return LucideIcons.blocks;
      default:
        return LucideIcons.palette;
    }
  }

  Widget _gallery() {
    final cat = _categories[_selectedCategory];
    final pages = cat.pages;

    return Column(children: [
      const SizedBox(height: 12),
      // The picture categories. Sized to be hit by a small finger rather
      // than a cursor: the chip was 46 tall with a 15-pixel icon beside
      // 13-pixel text, which is a control built for an adult thumb.
      SizedBox(
        height: 58,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final c = _categories[i];
            final sel = _selectedCategory == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: sel ? c.color : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border:
                      Border.all(color: sel ? c.color : Colors.grey.shade300),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: c.color.withOpacity(0.3), blurRadius: 8)
                        ]
                      : [],
                ),
                child: Row(children: [
                  Icon(_categoryIcon(c.name),
                      size: 20, color: sel ? Colors.white : c.color),
                  const SizedBox(width: 8),
                  Text(c.name,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.grey.shade700,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15)),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: pages.isEmpty
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
              ),
      ),
    ]);
  }

  Widget _pageCard(ColoringPage page, ColoringCategory cat) {
    // Check if this page is already completed (local creations + provider)
    final pageIndex = cat.pages.indexOf(page);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isCompleted = _myCreations.any(page.owns) ||
        (pageIndex >= 0 &&
            userProvider.isKulayPageCompleted(cat.name, pageIndex));

    return GestureDetector(
      onTap: () {
        // A finished page stays open: children colour the same picture over
        // and over, and that repetition is the point of the activity.
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
        });
        oldBaked?.dispose();
        _maskCache.clear();
        _loadPageImage()
            .then((_) => _loadAutoSave())
            .then((_) => _rebuildStrokeMasks());
      },
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
                      child: Image.asset(
                        page.imagePath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        color: isCompleted ? Colors.grey.shade400 : null,
                        colorBlendMode:
                            isCompleted ? BlendMode.saturation : null,
                        errorBuilder: (_, __, ___) => Icon(LucideIcons.palette,
                            size: 52, color: cat.color.withOpacity(0.4)),
                      ),
                    ),
                  ),
                  if (isCompleted)
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
            if (_isLoadingAutoSave)
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

  Widget _drawingSurface(double side) {
    _lastSide = side;
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
              ),
              size: Size(side, side),
              child: Container(color: Colors.transparent),
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
    setState(() {
      _activeStroke = _activeStroke!.copyWith(
        points: [..._activeStroke!.points, e.localPosition],
      );
      _lastPos = e.localPosition;
    });
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
      _autoSave();
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
      // Tight at the bottom: the row of tools is the last thing on the
      // screen, so the padding under it is space taken from the drawing for
      // nothing.
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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

        const SizedBox(height: 6),

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

        const SizedBox(height: 6),

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
            active: _isEraser,
            onTap: () => setState(() => _isEraser = !_isEraser),
          ),
          _tBtn(
              icon: LucideIcons.undo_2,
              label: AppLocalizations.of(context)!.undo,
              active: false,
              disabled: _strokes.isEmpty && _bucketUndoImages.isEmpty,
              onTap: _undo),
          _tBtn(
            icon: LucideIcons.trash_2,
            label: AppLocalizations.of(context)!.clear,
            active: false,
            onTap: _confirmClearAll,
          ),
          _tBtn(
              icon: _editingCreation != null
                  ? LucideIcons.save
                  : (_isCurrentPageSaved()
                      ? LucideIcons.eye
                      : LucideIcons.save),
              label: _editingCreation != null
                  ? AppLocalizations.of(context)!.update
                  // Was the bare English word "View" — the one label on this
                  // screen that stayed English in every language.
                  : (_isCurrentPageSaved()
                      ? AppLocalizations.of(context)!.viewArtwork
                      : AppLocalizations.of(context)!.save),
              active: false,
              onTap: _editingCreation != null
                  ? _saveCreation
                  : (_isCurrentPageSaved()
                      ? () => setState(() => _selectedTab = 1)
                      : _saveCreation)),
        ]),
      ]),
    );
  }

  /// One of the three brush sizes, drawn as the dot it actually makes.
  Widget _brushBtn(double size, String label) {
    // Shared with the eraser — it needs the same three sizes to erase a
    // small mistake versus a whole limb, and it reads its radius off this
    // same [_brushSize].
    final selected = _brushSize == size;
    final dot = (size / 48 * 26).clamp(8.0, 26.0);
    return GestureDetector(
      onTap: () => setState(() {
        _brushSize = size;
      }),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2),
          ),
          child: Center(
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // The dot wears the colour the child is about to draw with,
                // so one button previews both size and colour at once.
                color: selected ? Colors.white : _selectedColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        contentPadding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.trash_2,
                size: 42, color: Color(0xFFE5484D)),
          ),
          const SizedBox(height: 16),
          Text(loc.clearCanvasQuestion,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.brush, size: 20),
              label: Text(loc.keepColoring,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E9E5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _clearAll();
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.rotate_ccw, size: 20),
              label: Text(loc.startOverYes,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE5484D),
                side: const BorderSide(color: Color(0xFFE5484D), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tBtn(
      {required IconData icon,
      required String label,
      required bool active,
      required VoidCallback onTap,
      bool disabled = false}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.3 : 1.0,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: active ? Colors.white : AppColors.primary, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: active ? AppColors.primary : Colors.grey.shade600,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
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
          Text(
              '${_myCreations.length} artwork${_myCreations.length == 1 ? '' : 's'}',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          _sc(0, 'Recent'),
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
                    ...List.generate(
                        5,
                        (i) => Icon(
                              i < creation.stars!
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: i < creation.stars!
                                  ? const Color(0xFFFFB800)
                                  : const Color(0xFFCBD5E1),
                            )),
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
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_creationTitle(creation),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (creation.stars != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < creation.stars!
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 28,
                                color: i < creation.stars!
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFFCBD5E1),
                              )),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${creation.stars} / 5 Stars • Color Detail & Completeness',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: const Color(0xFFF0F1FF),
                    child: _creationPicture(creation),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                '${creation.date.day}/${creation.date.month}/${creation.date.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.pencil, size: 18),
                      label: Text(AppLocalizations.of(context)!.edit),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        for (final cat in _categories) {
                          for (final page in cat.pages) {
                            if (page.owns(creation)) {
                              _clearZoom();
                              setState(() {
                                _selectedPage = page;
                                _strokes
                                  ..clear()
                                  ..addAll(creation.strokes);
                                _activeStroke = null;
                                _editingCreation = creation;
                                _selectedTab = 0;
                                _coloringStartTime = DateTime.now();
                              });
                              _maskCache.clear();
                              _loadPageImage().then((_) {
                                if (!mounted) return;
                                setState(() {});
                                _rebuildStrokeMasks();
                              });
                              return;
                            }
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.trash_2,
                          size: 18, color: Colors.red),
                      label: Text(AppLocalizations.of(context)!.delete,
                          style: const TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeleteCreation(creation);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCreation(MyCreation creation) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.triangle_alert, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(AppLocalizations.of(context)!.deleteArtwork)),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.confirmDeleteArtwork),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCreation(creation);
            },
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCreation(MyCreation creation) async {
    setState(() => _myCreations.remove(creation));
    _saveCreationsToHive();
    if (creation.thumbnailPath.isNotEmpty &&
        !creation.thumbnailPath.startsWith('assets/')) {
      try {
        File(creation.thumbnailPath).deleteSync();
      } catch (e) {
        debugPrint('Error deleting thumbnail: $e');
      }
    }

    // Reset the original coloring page so it can be colored again
    if (creation.sourcePagePath.isNotEmpty) {
      for (final cat in _categories) {
        final pageIndex = cat.pages.indexWhere(
          (p) => p.usesImage(creation.sourcePagePath),
        );
        if (pageIndex >= 0) {
          final pageName = cat.pages[pageIndex].name;
          _clearAutoSaveForPage(pageName);
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.updateKulayProgress('coloring', false,
              category: cat.name, index: pageIndex);
          break;
        }
      }
    }

    _snack(AppLocalizations.of(context)!.artworkDeleted);
    await _syncKulayProgressWithCreations();
  }
}

/// A cached stay-inside-the-lines region: membership bits for fast lookup
/// plus the alpha mask image used to clip strokes.
class _RegionMask {
  final Uint8List bits;
  final ui.Image image;
  _RegionMask(this.bits, this.image);
}
