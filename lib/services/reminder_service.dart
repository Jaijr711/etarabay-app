import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The notifications the app raises while it is not open: a handful of
/// daily nudges spread across the evening, each about a different everyday
/// moment rather than one repeated "come back and play."
///
/// Everything else "notification"-shaped in this app — the birthday card,
/// the badge-earned banner — only ever fires while a screen is already on
/// screen, because they are widgets, not something the OS delivers. This is
/// the one path onto the phone's own lock screen.
///
/// **Web has no implementation of this at all** — `flutter_local_notifications`
/// is Android/iOS/desktop only. Every entry point here checks [kIsWeb] first
/// and does nothing on web, the same way [Sfx] swallows a missing platform
/// channel rather than let a game screen crash over a sound.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// The birthday greeting. Its own id, well clear of the daily reminders'
  /// ids below, so scheduling one never touches the other.
  static const int _birthdayId = 1002;

  /// One daily nudge, at one time, in one language, with the child's name
  /// worked into the title — the same touch [_birthdayText] already gives
  /// the birthday greeting, so a reminder on the lock screen reads as
  /// addressed to this child rather than to whoever happens to see it.
  ///
  /// [ilo], [fil] and [en] are each a plain (title, body) pair — see
  /// [_ReminderSlot] records below rather than a switch per slot, now that
  /// there is more than one of these to keep in step. The name is spliced in
  /// here, once, rather than duplicated into every slot's own text.
  (String, String) _textFor(
      _ReminderSlot slot, String languageCode, String childName) {
    final (title, body) = switch (languageCode) {
      'ilo' => slot.ilo,
      'fil' => slot.fil,
      _ => slot.en,
    };
    return (_withName(title, childName), body);
  }

  /// Inserts ", Name" just before a title's closing "!" or "?" — "Oras na
  /// para Mag-aral!" becomes "Oras na para Mag-aral, Juan!" — or leaves the
  /// title untouched when there is no name yet to use (the earliest, boot-time
  /// reschedule in main.dart can run before a profile has ever been saved).
  String _withName(String title, String childName) {
    if (childName.isEmpty) return title;
    if (title.isEmpty) return childName;
    final last = title[title.length - 1];
    if (last == '!' || last == '?') {
      return '${title.substring(0, title.length - 1)}, $childName$last';
    }
    return '$title, $childName';
  }

  /// Three of the four are scheduled outside 8am-6pm on purpose — that is
  /// when a Philippine daycare day actually runs, and a nudge to come play
  /// mid-lesson (the original single 5pm reminder's mistake) reminds a
  /// child of the app at the one time they cannot act on it. The
  /// study-time slot is the deliberate exception: set at 8am, right when
  /// the day starts, at the parent's own request. Each id is its own
  /// alarm, so re-running [schedule] replaces all four together rather
  /// than stacking up duplicates.
  static const List<_ReminderSlot> _slots = [
    _ReminderSlot(
      id: 1005,
      hour: 7,
      minute: 0,
      ilo: (
        'Naimbag a Bigat!',
        'Kitaen tayo no ania ti masursuroam ita nga aldaw iti E-Tarabay!'
      ),
      fil: (
        'Magandang Umaga!',
        'Tara, tingnan natin ang matututunan mo ngayon sa E-Tarabay!'
      ),
      en: ('Good Morning!', "Let's see what you'll learn today in E-Tarabay!"),
    ),
    _ReminderSlot(
      id: 1001,
      hour: 8,
      minute: 0,
      ilo: ('Oras ti Panagadal!', 'Agsubli ka ken agay-ayam iti E-Tarabay!'),
      fil: ('Oras na para Mag-aral!', 'Halika, maglaro tayo sa E-Tarabay!'),
      en: ("It's Learning Time!", 'Come back and play in E-Tarabay!'),
    ),
    _ReminderSlot(
      id: 1003,
      hour: 19,
      minute: 0,
      ilo: (
        'Oras ti Pannangan!',
        'Kalpasan ti pangrabii, agay-ayamtayo iti E-Tarabay!'
      ),
      fil: (
        'Kumain ka na ba?',
        'Pagkatapos kumain, maglaro tayo sa E-Tarabay!'
      ),
      en: ('Time to Eat!', 'After dinner, let\'s play in E-Tarabay!'),
    ),
    // Bedtime, not another "come play" nudge — an 8pm invitation to open
    // the app was pulling a child into more screen time right before sleep
    // instead of winding down for it.
    _ReminderSlot(
      id: 1004,
      hour: 20,
      minute: 0,
      ilo: (
        'Oras ti Pannaturog!',
        'Maturog a nasapa tapno agbalin a napigsa ken nasalun-at!'
      ),
      fil: (
        'Oras na para Matulog!',
        'Matulog ka na nang maaga para lumakas at lumaki ka!'
      ),
      en: ('Time for Bed!', 'Sleep early so you grow up strong and healthy!'),
    ),
  ];

  /// Sets up the plugin and the timezone database. Safe to call more than
  /// once — later calls are a no-op — and safe to call on web, where it does
  /// nothing.
  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      tzdata.initializeTimeZones();
      // Every child using this app is in the Philippines, so the location is
      // fixed rather than asked of the platform — that would need a second
      // plugin (`flutter_timezone`) purely to confirm a fact already true of
      // every install.
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        // Asked for at schedule time instead — see [requestPermission] — so
        // the prompt appears next to the Settings switch the parent just
        // touched, not silently the first time the app happens to launch.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      _ready = true;
    } catch (e) {
      debugPrint('ReminderService.init: $e');
    }
  }

  /// Asks the OS for permission to notify. Returns false on web, on a denial,
  /// or on any platform error — every one of those means "cannot schedule",
  /// which the caller treats the same way regardless of which it was.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // Android 13 (API 33) made this a runtime permission like camera or
        // location; below that the return is true without a prompt.
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      // Linux, macOS, Windows: local notifications need no separate grant.
      return true;
    } catch (e) {
      debugPrint('ReminderService.requestPermission: $e');
      return false;
    }
  }

  /// (Re)schedules the four daily reminders, in whatever language the app is
  /// set to, addressed to [childName] where one is already known. Calling
  /// this again — the app opening, the language changing, a child signing
  /// in — replaces the previous four rather than adding more, because each
  /// slot's id is fixed. [childName] defaults to empty for the one caller
  /// that can run before any profile has been saved yet (the boot-time
  /// reschedule in main.dart) — [_withName] then leaves the title as-is
  /// rather than addressing the notification to nobody.
  Future<void> schedule({
    required String languageCode,
    String childName = '',
  }) async {
    if (kIsWeb) return;
    await init();
    if (!_ready) return;

    for (final slot in _slots) {
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, slot.hour, slot.minute);
      if (when.isBefore(now)) {
        when = when.add(const Duration(days: 1));
      }

      final (title, body) = _textFor(slot, languageCode, childName);

      try {
        await _plugin.zonedSchedule(
          slot.id,
          title,
          body,
          when,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_reminder',
              _channelText(languageCode, 'daily').$1,
              channelDescription: _channelText(languageCode, 'daily').$2,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          // Battery-friendly: Android is free to fire this a few minutes
          // late, rather than waking the device precisely on the second —
          // which is also what keeps this off the exact-alarm permission
          // Android 12+ gates behind an extra grant.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          // Same hour and minute, every day — the recurrence is this one
          // line, not a loop that schedules 365 individual alarms.
          matchDateTimeComponents: DateTimeComponents.time,
          // iOS-only, and only consulted on very old iOS versions still
          // using UILocalNotification rather than UserNotifications —
          // wallClockTime is what makes the chosen hour mean that hour
          // wherever the phone's clock is set, rather than a fixed instant
          // in GMT.
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
      } catch (e) {
        debugPrint('ReminderService.schedule(${slot.id}): $e');
      }
    }
  }

  /// Turns the daily reminders off. Called when the child (or their parent)
  /// switches "Notifications" off in Settings.
  Future<void> cancel() async {
    if (kIsWeb) return;
    await init();
    if (!_ready) return;
    try {
      for (final slot in _slots) {
        await _plugin.cancel(slot.id);
      }
      await _plugin.cancel(_birthdayId);
    } catch (e) {
      debugPrint('ReminderService.cancel: $e');
    }
  }

  /// Books the greeting for [birthday]'s next occurrence — this year if it
  /// has not happened yet, next year if it has (or if today is the day: the
  /// in-app confetti already covers today, this is for a birthday that
  /// arrives with the app closed).
  ///
  /// There is no month-and-day recurrence in this plugin — [schedule]'s
  /// `DateTimeComponents.time` repeats daily, and the closest built-in,
  /// `dayOfMonthAndTime`, would fire every month rather than every year. So
  /// this books one specific date rather than a rule, and has to be called
  /// again to reach the year after that. [HomeScreen] does this on every
  /// visit, which is the same trade the daily reminder makes in `main.dart`
  /// for surviving a reboot: a family that never reopens the app for a full
  /// year past the last birthday will not get the one after it, but that
  /// family was not going to see anything else from the app either.
  Future<void> scheduleBirthday({
    required DateTime birthday,
    required String childName,
    required String languageCode,
  }) async {
    if (kIsWeb) return;
    await init();
    if (!_ready) return;

    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, birthday.month, birthday.day, 8, 0);
    // Strictly before today, or today but the 8am moment already passed —
    // both mean this year's greeting is spent, so it moves to next year.
    if (when.isBefore(now)) {
      when = tz.TZDateTime(
          tz.local, now.year + 1, birthday.month, birthday.day, 8, 0);
    }

    final (title, body) = _birthdayText(languageCode, childName);

    try {
      await _plugin.zonedSchedule(
        _birthdayId,
        title,
        body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'birthday',
            _channelText(languageCode, 'birthday').$1,
            channelDescription: _channelText(languageCode, 'birthday').$2,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // One specific date, not a rule — see the note above.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
    } catch (e) {
      debugPrint('ReminderService.scheduleBirthday: $e');
    }
  }

  /// The name and description Android shows for each kind of notification
  /// in the phone's settings. They were Tagalog whatever language was
  /// chosen; Android renames an existing channel when it is posted to again.
  (String, String) _channelText(String languageCode, String channel) {
    final daily = channel == 'daily';
    return switch (languageCode) {
      'fil' => daily
          ? ('Paalala', 'Araw-araw na paalala mula sa E-Tarabay')
          : ('Kaarawan', 'Bati sa kaarawan mula sa E-Tarabay'),
      'ilo' => daily
          ? ('Palagip', 'Inaldaw a palagip manipud E-Tarabay')
          : ('Kasangay', 'Pakablaaw iti kasangay aggapo iti E-Tarabay'),
      _ => daily
          ? ('Reminders', 'Daily reminders from E-Tarabay')
          : ('Birthday', 'Birthday greetings from E-Tarabay'),
    };
  }

  (String, String) _birthdayText(String languageCode, String name) {
    // The body is the exact wording the in-app confetti card already uses —
    // AppLocalizations.birthdayGreeting — so a greeting on the lock screen
    // and the one on the app's own screen never say it two different ways.
    // The title is separate, or a notification with the same sentence twice
    // in it reads as a glitch rather than a celebration.
    switch (languageCode) {
      case 'ilo':
        return ('E-Tarabay', 'Naragsak a Kasangay, $name!');
      case 'fil':
        return ('E-Tarabay', 'Maligayang Kaarawan, $name!');
      default:
        return ('E-Tarabay', 'Happy Birthday, $name!');
    }
  }
}

/// One entry in [ReminderService._slots]: a time of day and its message in
/// all three languages. A plain data holder — the scheduling logic that
/// reads these lives on [ReminderService] itself, not here.
class _ReminderSlot {
  final int id;
  final int hour;
  final int minute;
  final (String, String) ilo;
  final (String, String) fil;
  final (String, String) en;

  const _ReminderSlot({
    required this.id,
    required this.hour,
    required this.minute,
    required this.ilo,
    required this.fil,
    required this.en,
  });
}
