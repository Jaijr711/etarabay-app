import 'services/audio_source.dart';
import 'services/reminder_service.dart';
import 'widgets/account_watcher.dart';
import 'widgets/tablet_scale.dart';
import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'firebase_options.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';

/// Global route observer so screens can auto-refresh when they become visible
/// again (e.g. returning to the Lessons page after playing a game).
/// The app's navigator, so the account watcher can raise a dialog over
/// whatever route the child happens to be on.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

// ========== MODULE BACKGROUND MUSIC MAP ==========
class ModuleMusic {
  static const matematika = 'audio/music/mathematics_module.m4a';
  static const pamilya = 'audio/music/about_bg.m4a';
  static const kulay = 'audio/music/color-fun_module.m4a';
  static const traceIt = 'audio/music/trace-it_bg.m4a';
  static const magbasa = 'audio/music/lets-read_module.m4a';
  static const tandaan = 'audio/music/remember-it_module.m4a';
  static const mainBg = 'audio/music/main_bg.m4a';
  static const aboutBg = 'audio/music/about_bg.m4a';
}

// ========== AUDIO MANAGER (FOR BACKGROUND MUSIC) ==========

class AudioManager extends ChangeNotifier with WidgetsBindingObserver {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioManager._internal();

  static AudioManager get instance => _instance;

  late AudioPlayer _player;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMusicEnabled = true;
  String? _currentAssetPath;
  bool _wasPlayingBeforePause = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  // Remembers each track's last playback position so switching tracks and
  // returning resumes instead of restarting from the top.

  Future<void> initialize() async {
    if (_isInitialized) return;

    _player = AudioPlayer();

    // Listen for unexpected completion and restart if needed
    _player.onPlayerComplete.listen((_) {
      if (_isMusicEnabled && _currentAssetPath != null && _isPlaying) {
        _restartMusic();
      }
    });

    // Load saved preference
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('music_enabled') ?? true;

    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        _wasPlayingBeforePause = true;
        _player.pause();
        // We don't set _isPlaying = false because we want to remember it was playing
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause && _isMusicEnabled) {
        _player.resume();
        _wasPlayingBeforePause = false;
      }
    }
  }

  /// Whether the page has been touched yet.
  ///
  /// A browser will not start sound until the person has interacted with the
  /// page; asking before that (the splash and the home screen both start the
  /// music as they open) is refused, with "The AudioContext was not allowed
  /// to start" in the console. On the web the music therefore waits for the
  /// first touch and starts then. A phone app has no such rule.
  bool _heardGesture = !kIsWeb;
  String? _waitingAsset;
  bool _listeningForGesture = false;

  void _waitForGesture(String assetPath) {
    // The latest request wins: the home track asked for at launch, or a
    // module's own if the child got into one before touching anything.
    _waitingAsset = assetPath;
    if (_listeningForGesture) return;
    _listeningForGesture = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onFirstPointer);
  }

  void _onFirstPointer(PointerEvent event) {
    // The lift of a finger (or a click's release) is what the browser
    // counts as the person interacting; a touch going down is not.
    if (event is! PointerUpEvent) return;
    _heardGesture = true;
    // Not removed mid-dispatch; the router is still walking its routes.
    scheduleMicrotask(() {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onFirstPointer);
      _listeningForGesture = false;
    });
    final asset = _waitingAsset;
    _waitingAsset = null;
    if (asset != null) startBackgroundMusic(asset);
  }

  Future<void> startBackgroundMusic(String assetPath) async {
    if (!_isInitialized) await initialize();
    if (!_isMusicEnabled) return;
    if (!_heardGesture) {
      _waitForGesture(assetPath);
      return;
    }

    // Smart Check: Don't restart if already playing the same song
    if (_isPlaying && _currentAssetPath == assetPath) return;

    _retryCount = 0;
    await _playWithRetry(assetPath);
  }

  // ── Module music helpers ───────────────────────────────────────────────
  // The main/home track. Modules switch to their own track on entry and
  // this resumes when returning home. Because startBackgroundMusic ignores
  // a request for the track that's already playing, navigating within the
  // same module (or re-entering it) never restarts the music.
  static const String homeMusicAsset = 'audio/music/main_bg.m4a';

  Future<void> playModuleMusic(String assetPath) =>
      startBackgroundMusic(assetPath);

  Future<void> resumeHomeMusic() => startBackgroundMusic(homeMusicAsset);

  Future<void> _playWithRetry(String assetPath) async {
    try {
      // From the beginning. This used to resume the remembered position,
      // so leaving a module and coming back dropped the child into the
      // middle of a phrase. Backgrounding the app is a different path —
      // pauseMusic and resumeMusic use the player's own pause, which keeps
      // its place without any of this.
      _currentAssetPath = assetPath;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(musicVolume);
      await _player.play(audioSourceFor(assetPath));
      _isPlaying = true;
      _wasPlayingBeforePause = false;
      _retryCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing music: $e');
      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('Retrying music playback ($_retryCount/$_maxRetries)...');
        await Future.delayed(const Duration(seconds: 1));
        await _playWithRetry(assetPath);
      } else {
        debugPrint('Music playback failed after $_maxRetries retries.');
        _isPlaying = false;
      }
    }
  }

  Future<void> _restartMusic() async {
    if (_currentAssetPath == null || !_isMusicEnabled) return;
    debugPrint('Music stopped unexpectedly, restarting...');
    _isPlaying = false;
    await _playWithRetry(_currentAssetPath!);
  }

  /// The volume the music plays at when nothing is talking over it.
  static const double musicVolume = 0.3;

  /// Quieten the music without stopping it.
  ///
  /// For narration — a poem being read, a story, a song. Pausing would be the
  /// obvious thing, but a paused element needs a fresh `play()` to come back
  /// and Chrome refuses `play()` outside a user gesture; resuming from a
  /// screen teardown was therefore rejected and the music never returned.
  /// At zero volume the element is still playing, so nothing has to be
  /// restarted and there is no call for the browser to refuse.
  Future<void> duckMusic() async {
    try {
      await _player.setVolume(0);
    } catch (e) {
      debugPrint('Error ducking music: $e');
    }
  }

  /// Back to full volume after narration.
  Future<void> unduckMusic() async {
    if (!_isMusicEnabled) return;
    try {
      await _player.setVolume(musicVolume);
    } catch (e) {
      debugPrint('Error unducking music: $e');
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }
    _isPlaying = false;
    _wasPlayingBeforePause = false;
    notifyListeners();
  }

  Future<void> resumeMusic() async {
    if (!_isMusicEnabled || !_isInitialized) return;
    try {
      await _player.resume();
      _isPlaying = true;
      _wasPlayingBeforePause = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming music: $e');
      if (_currentAssetPath != null) {
        await _playWithRetry(_currentAssetPath!);
      }
    }
  }

  Future<void> stopMusic() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }
    _isPlaying = false;
    _wasPlayingBeforePause = false;
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    if (_isPlaying) {
      await pauseMusic();
    } else {
      await resumeMusic();
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);

    if (!enabled && _isPlaying) {
      await stopMusic();
    }

    notifyListeners();
  }

  bool get isPlaying => _isPlaying;
  bool get isMusicEnabled => _isMusicEnabled;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }
}

// Filled in main() before runApp so a crash screenshot always says which
// build produced it — the same-looking "app-release.apk" filename across
// releases has already caused a stale/old build to be re-tested by mistake.
String _diagnosticBuildLabel = 'unknown version';

// Release builds normally swap a crashed widget for a plain grey box with
// no message, to avoid leaking details to end users. That grey box is
// indistinguishable from a stuck loading screen, so while we're chasing an
// intermittent blank-screen report, show the real error instead: whoever
// hits it can screenshot the text and that becomes the actual bug report.
void _showErrorsOnScreen() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFFFF3F3),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            'DIAGNOSTIC BUILD ($_diagnosticBuildLabel) - screenshot this:\n\n'
            '${details.exceptionAsString()}\n\n'
            '${details.stack}',
            style: const TextStyle(color: Colors.red, fontSize: 11),
          ),
        ),
      ),
    );
  };
}

/// Shown instead of the app on an iPhone or iPad. E-Tarabay is released for
/// Android only; the iOS project was removed (2026-10-13), and this stops a
/// regenerated one from running anyway. The web version is not affected.
class _AndroidOnly extends StatelessWidget {
  const _AndroidOnly();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'E-Tarabay is available on Android only.\n\n'
              'Ang E-Tarabay ay para sa Android lamang.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    runApp(const _AndroidOnly());
    return;
  }
  // Not awaited: only the on-screen error report reads this label, and it
  // was costing every launch a platform round-trip before the first frame.
  PackageInfo.fromPlatform().then((info) {
    _diagnosticBuildLabel = '${info.version}+${info.buildNumber}';
  }).catchError((Object e) {
    debugPrint('PackageInfo unavailable: $e');
  });
  _showErrorsOnScreen();

  // Portrait only.
  //
  // Every board in the app is budgeted against the height a phone has
  // standing up — about 790 logical pixels. Turned sideways that becomes
  // roughly 360, and the fixed parts of a game board alone come to more than
  // that: in "Drag the Number" the app bar, the level tabs, the progress bar,
  // the basket and the row of numbers already need about 434 before a single
  // object is drawn. The app was free to rotate and simply broke when it did.
  //
  // Viewing a finished certificate still turns sideways — it asks for that
  // itself, and it is a picture with nothing to overflow.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Local storage opens alongside Firebase rather than after it: the two do
  // not depend on each other, and on a slow phone each is a noticeable wait.
  final localStorageReady = () async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('userProfile'),
      Hive.openBox('userProgress'),
      Hive.openBox('settings'),
    ]);
  }();
  final prefsReady = SharedPreferences.getInstance();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── Smart network caching (offline-first) ──
    // Cache all Firestore data locally so the app works fully offline:
    // reads are served from cache when there's no network, writes are
    // queued locally and automatically synced once the network returns.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Give every app instance a stable Firebase identity (anonymous).
    // This is additive — students are still identified by their Firestore
    // record — but it lets us secure Firestore behind authentication later.
    // Fails gracefully (e.g. offline first-run, or provider disabled).
    //
    // Not awaited. It used to sit in front of runApp() with a five-second
    // timeout, so a first launch on a weak signal showed a blank screen for
    // up to five seconds before anything else happened. Signing in is not
    // needed to play; it finishes in the background.
    if (FirebaseAuth.instance.currentUser == null) {
      unawaited(FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 15))
          .then((_) {}, onError: (Object e) {
        debugPrint('Anonymous auth skipped: $e');
      }));
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  await localStorageReady;
  final prefs = await prefsReady;
  final savedLanguage = prefs.getString('language') ?? 'en';

  // Initialize UserProvider and wait for its internal async setup
  final userProvider = UserProvider();

  // Initialize AudioManager
  final audioManager = AudioManager.instance;
  await audioManager.initialize();

  // The daily "come back and play" reminder, if the child (or their
  // parent) already had it on. Not awaited: this only re-arms an alarm
  // that OS-level events (a reboot, an app update) can drop, so it is
  // never worth a child's first frame. It never asks for permission here —
  // that stays behind the Settings switch in settings_screen.dart, so the
  // system prompt only ever appears next to the control a parent just
  // touched, not silently on first launch.
  // Defaults to off, not on: 'notifications_enabled' is only ever written
  // true by the Settings switch, which requests the OS permission first.
  // Defaulting this to true on a key that has simply never been set yet
  // called schedule() before that permission had ever been asked for —
  // Android 13+ silently drops a notification it was never granted, so
  // this looked like it was working (no error, no crash) while nothing
  // ever actually reached the lock screen.
  if (prefs.getBool('notifications_enabled') ?? false) {
    // Read straight from the box rather than through [userProvider]: that
    // provider's own load is still in flight (its constructor kicks it off
    // but nothing here awaits it), so asking it for a name this early would
    // just read null every time.
    final savedProfile = Hive.box('userProfile').get('currentUser');
    final childName =
        savedProfile is Map ? (savedProfile['name']?.toString() ?? '') : '';
    unawaited(ReminderService.instance
        .schedule(languageCode: savedLanguage, childName: childName));
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => LanguageProvider(savedLanguage)),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (context) => audioManager),
      ],
      child: const ETarabayApp(),
    ),
  );
}

// Fallback delegate that loads English MaterialLocalizations for unsupported locales
class _MaterialFallback extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialFallback();

  static const delegate = _MaterialFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final target = GlobalMaterialLocalizations.delegate.isSupported(locale)
        ? locale
        : const Locale('en');
    return GlobalMaterialLocalizations.delegate.load(target);
  }

  @override
  bool shouldReload(_MaterialFallback old) => false;
}

// Fallback delegate that loads English CupertinoLocalizations for unsupported locales
class _CupertinoFallback extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoFallback();

  static const delegate = _CupertinoFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    final target = GlobalCupertinoLocalizations.delegate.isSupported(locale)
        ? locale
        : const Locale('en');
    return GlobalCupertinoLocalizations.delegate.load(target);
  }

  @override
  bool shouldReload(_CupertinoFallback old) => false;
}

class ETarabayApp extends StatelessWidget {
  const ETarabayApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the platform default font for all text (no custom font family).
    // Only the top header/app-bar text is emphasized in bold — handled where
    // headers are built (see CustomHeaderAppBar and screen headers).
    final baseText = ThemeData(useMaterial3: true).textTheme;
    final appTextTheme = baseText.apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    );

    return MaterialApp(
      title: 'E-Tarabay',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      navigatorObservers: [routeObserver],
      // Above every route, so a child whose account is deleted is told where
      // they are rather than only on the home screen.
      //
      // TabletScale outermost: on an iPad or tablet the phone layout is drawn
      // enlarged instead of stretched — see tablet_scale.dart.
      builder: (context, child) => TabletScale(
        child: AccountWatcher(
          navigatorKey: appNavigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      locale:
          Locale(Provider.of<LanguageProvider>(context).currentLanguageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        _MaterialFallback.delegate,
        _CupertinoFallback.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fil'),
        Locale('ilo'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: appTextTheme,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: Colors.white,
          background: AppColors.background,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
