import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_ilo.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
    Locale('ilo')
  ];

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @levelCompleted.
  ///
  /// In en, this message translates to:
  /// **'Level {level} Completed!'**
  String levelCompleted(int level);

  /// No description provided for @proudOfYou.
  ///
  /// In en, this message translates to:
  /// **'I am proud of you!'**
  String get proudOfYou;

  /// No description provided for @categoryCompleted.
  ///
  /// In en, this message translates to:
  /// **'You completed all levels in {cat}!'**
  String categoryCompleted(String cat);

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished! 🏆'**
  String get finished;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'earned'**
  String get earned;

  /// No description provided for @levels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levels;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'activities'**
  String get activities;

  /// No description provided for @parents.
  ///
  /// In en, this message translates to:
  /// **'PARENTS'**
  String get parents;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// No description provided for @awards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get awards;

  /// No description provided for @homeAge.
  ///
  /// In en, this message translates to:
  /// **'Age {age}'**
  String homeAge(int age);

  /// Home card wording for a module
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get matematika;

  /// Home card wording for a module
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get angAkingSarili;

  /// Home card wording for a module
  ///
  /// In en, this message translates to:
  /// **'my family'**
  String get atAkingPamilya;

  /// No description provided for @kulaySaya.
  ///
  /// In en, this message translates to:
  /// **'Color Fun'**
  String get kulaySaya;

  /// No description provided for @magkulayTayo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Color!'**
  String get magkulayTayo;

  /// Home card wording for a module
  ///
  /// In en, this message translates to:
  /// **'Stories and Songs'**
  String get magbasaTitle;

  /// Home card wording for a module
  ///
  /// In en, this message translates to:
  /// **'Read & Sing!'**
  String get alpabetoAtMgaSalita;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Button in the teacher guide video player that lists its parts to jump to.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get videoParts;

  /// Over the whole app when the developers require a newer version than the one installed.
  ///
  /// In en, this message translates to:
  /// **'To use E-Tarabay, first update to version {version}.'**
  String updateRequiredBody(String version);

  /// Over a child's app while the developers have switched on maintenance mode.
  ///
  /// In en, this message translates to:
  /// **'Just a moment!'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceNote.
  ///
  /// In en, this message translates to:
  /// **'We\'re fixing the app. It will open again by itself when we\'re done.'**
  String get maintenanceNote;

  /// Label over the installed version on the update-required cover.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get updateThisPhone;

  /// No description provided for @updateNeeded.
  ///
  /// In en, this message translates to:
  /// **'Needed'**
  String get updateNeeded;

  /// Shown when a child's record was deleted while their report or edit form was open.
  ///
  /// In en, this message translates to:
  /// **'This child has been removed.'**
  String get childRemovedNotice;

  /// Tag on a student card the developer finished for testing.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testAccountTag;

  /// No description provided for @testAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Finished by the developer for testing. Not real progress.'**
  String get testAccountNote;

  /// Opens the silent video that walks a teacher through the app; the video itself is in Filipino for every language.
  ///
  /// In en, this message translates to:
  /// **'How to use the app'**
  String get teacherHowToUse;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @poems.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get poems;

  /// No description provided for @stories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get stories;

  /// No description provided for @songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// No description provided for @tune.
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get tune;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @counting.
  ///
  /// In en, this message translates to:
  /// **'Count the Objects'**
  String get counting;

  /// No description provided for @dragNumber.
  ///
  /// In en, this message translates to:
  /// **'Drag the Numbers'**
  String get dragNumber;

  /// No description provided for @lineMatch.
  ///
  /// In en, this message translates to:
  /// **'Match with Line'**
  String get lineMatch;

  /// No description provided for @popBalloon.
  ///
  /// In en, this message translates to:
  /// **'Pop the Balloons'**
  String get popBalloon;

  /// No description provided for @moreOrLess.
  ///
  /// In en, this message translates to:
  /// **'More or Less'**
  String get moreOrLess;

  /// No description provided for @numberPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Number Puzzle'**
  String get numberPuzzle;

  /// No description provided for @numberSequence.
  ///
  /// In en, this message translates to:
  /// **'Number Sequence'**
  String get numberSequence;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong! Try again!'**
  String get wrong;

  /// No description provided for @wrongShort.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrongShort;

  /// No description provided for @replayReplacesStar.
  ///
  /// In en, this message translates to:
  /// **'Playing again replaces this star.'**
  String get replayReplacesStar;

  /// No description provided for @putNumbersInOrder.
  ///
  /// In en, this message translates to:
  /// **'Drag the numbers into the boxes'**
  String get putNumbersInOrder;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'{streak} day streak!'**
  String streak(int streak);

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @chooseFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose an answer first!'**
  String get chooseFirst;

  /// No description provided for @chooseLeftFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap a group on the left first!'**
  String get chooseLeftFirst;

  /// No description provided for @popAllBalloonsWith.
  ///
  /// In en, this message translates to:
  /// **'Pop all the balloons with'**
  String get popAllBalloonsWith;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @howMany.
  ///
  /// In en, this message translates to:
  /// **'How many {item}?'**
  String howMany(String item);

  /// No description provided for @matchWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Match the {category} with the correct number'**
  String matchWithNumber(String category);

  /// No description provided for @whichIsMore.
  ///
  /// In en, this message translates to:
  /// **'Which side has more, left or right?'**
  String get whichIsMore;

  /// No description provided for @whichIsLess.
  ///
  /// In en, this message translates to:
  /// **'Which side has fewer, left or right?'**
  String get whichIsLess;

  /// No description provided for @isSameNumber.
  ///
  /// In en, this message translates to:
  /// **'Same number?'**
  String get isSameNumber;

  /// No description provided for @arrange.
  ///
  /// In en, this message translates to:
  /// **'Put the numbers in order, smallest first'**
  String get arrange;

  /// No description provided for @selectCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Select the correct answer:'**
  String get selectCorrectAnswer;

  /// No description provided for @tapLeftTapRight.
  ///
  /// In en, this message translates to:
  /// **'Tap the group (left) → tap the number (right)'**
  String get tapLeftTapRight;

  /// No description provided for @angAkingSariliTitle.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get angAkingSariliTitle;

  /// No description provided for @allAboutMe.
  ///
  /// In en, this message translates to:
  /// **'All About Me'**
  String get allAboutMe;

  /// No description provided for @myEmotions.
  ///
  /// In en, this message translates to:
  /// **'My Emotions'**
  String get myEmotions;

  /// No description provided for @dailyRoutines.
  ///
  /// In en, this message translates to:
  /// **'Daily Routines'**
  String get dailyRoutines;

  /// No description provided for @myPreferences.
  ///
  /// In en, this message translates to:
  /// **'My Preferences'**
  String get myPreferences;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembers;

  /// No description provided for @familyRoles.
  ///
  /// In en, this message translates to:
  /// **'Family Roles'**
  String get familyRoles;

  /// No description provided for @familyActivities.
  ///
  /// In en, this message translates to:
  /// **'Family Activities'**
  String get familyActivities;

  /// No description provided for @familyTree.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTree;

  /// No description provided for @myHome.
  ///
  /// In en, this message translates to:
  /// **'My Home'**
  String get myHome;

  /// No description provided for @whatIsYourName.
  ///
  /// In en, this message translates to:
  /// **'What is your name?'**
  String get whatIsYourName;

  /// No description provided for @howOldAreYou.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get howOldAreYou;

  /// No description provided for @areYouBoyOrGirl.
  ///
  /// In en, this message translates to:
  /// **'Are you a boy or a girl?'**
  String get areYouBoyOrGirl;

  /// No description provided for @whatIsYourNameDescription.
  ///
  /// In en, this message translates to:
  /// **'Your name is what your family and friends call you. It is important!'**
  String get whatIsYourNameDescription;

  /// No description provided for @howOldAreYouDescription.
  ///
  /// In en, this message translates to:
  /// **'Your age tells you how many years have passed since you were born.'**
  String get howOldAreYouDescription;

  /// No description provided for @genderDescription.
  ///
  /// In en, this message translates to:
  /// **'Knowing if you are a boy or a girl helps us know more about you!'**
  String get genderDescription;

  /// No description provided for @typeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Type your name here'**
  String get typeNameHint;

  /// No description provided for @ageHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 5, 7, 10'**
  String get ageHint;

  /// No description provided for @aboutMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All About Me'**
  String get aboutMeSubtitle;

  /// No description provided for @myEmotionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explain your feelings'**
  String get myEmotionsSubtitle;

  /// No description provided for @dailyRoutinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn daily activities'**
  String get dailyRoutinesSubtitle;

  /// No description provided for @myPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What do you like?'**
  String get myPreferencesSubtitle;

  /// No description provided for @familyMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who are your family members?'**
  String get familyMembersSubtitle;

  /// No description provided for @familyRolesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What is everyone\'s job?'**
  String get familyRolesSubtitle;

  /// No description provided for @familyActivitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What do you do together?'**
  String get familyActivitiesSubtitle;

  /// No description provided for @familyTreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who are your relatives?'**
  String get familyTreeSubtitle;

  /// No description provided for @myHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get myHomeSubtitle;

  /// No description provided for @colorSomethingFirst.
  ///
  /// In en, this message translates to:
  /// **'Color something first!'**
  String get colorSomethingFirst;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get saved;

  /// No description provided for @coloringBook.
  ///
  /// In en, this message translates to:
  /// **'Coloring Book'**
  String get coloringBook;

  /// No description provided for @myCreations.
  ///
  /// In en, this message translates to:
  /// **'My Creations'**
  String get myCreations;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @animals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get animals;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get yellow;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// No description provided for @pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get pink;

  /// No description provided for @brown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get brown;

  /// No description provided for @black.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get black;

  /// No description provided for @white.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get white;

  /// No description provided for @brush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get brush;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @upper.
  ///
  /// In en, this message translates to:
  /// **'Capital Letter'**
  String get upper;

  /// No description provided for @lower.
  ///
  /// In en, this message translates to:
  /// **'Small Letter'**
  String get lower;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsLabel;

  /// No description provided for @ulitin.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get ulitin;

  /// No description provided for @uppercase.
  ///
  /// In en, this message translates to:
  /// **'Capital Letter'**
  String get uppercase;

  /// No description provided for @lowercase.
  ///
  /// In en, this message translates to:
  /// **'Small Letter'**
  String get lowercase;

  /// No description provided for @numbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get numbers;

  /// No description provided for @letter.
  ///
  /// In en, this message translates to:
  /// **'Letter {letter}'**
  String letter(String letter);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @tula.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get tula;

  /// No description provided for @kwento.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get kwento;

  /// No description provided for @kanta.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get kanta;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'badges'**
  String get badges;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String yearsOld(int age);

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @profileAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profileAge;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @noProfileData.
  ///
  /// In en, this message translates to:
  /// **'No profile data'**
  String get noProfileData;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Sound and Music'**
  String get audio;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @teacherDashboard.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s Dashboard'**
  String get teacherDashboard;

  /// No description provided for @newCertificateBadge.
  ///
  /// In en, this message translates to:
  /// **'New Certificate!'**
  String get newCertificateBadge;

  /// No description provided for @enrollStudent.
  ///
  /// In en, this message translates to:
  /// **'Enroll Student'**
  String get enrollStudent;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @lRN.
  ///
  /// In en, this message translates to:
  /// **'Student Number (Password)'**
  String get lRN;

  /// No description provided for @removeStudent.
  ///
  /// In en, this message translates to:
  /// **'Remove Student?'**
  String get removeStudent;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out this account? You will need the Student Number to sign back in.'**
  String get logoutConfirm;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogout;

  /// No description provided for @verifyLRN.
  ///
  /// In en, this message translates to:
  /// **'Verify Student Number'**
  String get verifyLRN;

  /// No description provided for @enterLRN.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Student Number to proceed'**
  String get enterLRN;

  /// No description provided for @invalidLRN.
  ///
  /// In en, this message translates to:
  /// **'Invalid Student Number. Please try again.'**
  String get invalidLRN;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get fillAllFields;

  /// No description provided for @parentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s Name'**
  String get parentNameLabel;

  /// No description provided for @parentContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s Contact Number'**
  String get parentContactLabel;

  /// No description provided for @contactLengthError.
  ///
  /// In en, this message translates to:
  /// **'Contact number must be exactly 11 digits.'**
  String get contactLengthError;

  /// No description provided for @birthdayGreeting.
  ///
  /// In en, this message translates to:
  /// **'Happy Birthday, {name}!'**
  String birthdayGreeting(String name);

  /// No description provided for @enroll.
  ///
  /// In en, this message translates to:
  /// **'Enroll'**
  String get enroll;

  /// No description provided for @studentEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Student Enrolled!'**
  String get studentEnrolled;

  /// No description provided for @studentEnrolledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{name} has been enrolled successfully.'**
  String studentEnrolledSuccessfully(String name);

  /// No description provided for @loginCredentials.
  ///
  /// In en, this message translates to:
  /// **'Login Credentials:'**
  String get loginCredentials;

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User:'**
  String get userLabel;

  /// No description provided for @usernameCopied.
  ///
  /// In en, this message translates to:
  /// **'Username copied!'**
  String get usernameCopied;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Pass:'**
  String get passwordLabel;

  /// No description provided for @passwordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied!'**
  String get passwordCopied;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @lRNPassword.
  ///
  /// In en, this message translates to:
  /// **'Student Number (Password)'**
  String get lRNPassword;

  /// No description provided for @confirmRemoveStudent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this student? This cannot be undone.'**
  String get confirmRemoveStudent;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @noStudentsEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No students enrolled yet.'**
  String get noStudentsEnrolled;

  /// No description provided for @tapToEnroll.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Enroll Student\" to add one.'**
  String get tapToEnroll;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @teacherLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Continue as Teacher'**
  String get teacherLoginButton;

  /// No description provided for @enterUsernamePassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both username and password.'**
  String get enterUsernamePassword;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginError;

  /// No description provided for @studentNumberField.
  ///
  /// In en, this message translates to:
  /// **'Student Number'**
  String get studentNumberField;

  /// Shown on a locked certificate: how many of the twelve badges are claimed and how many of the six lessons are finished.
  ///
  /// In en, this message translates to:
  /// **'Awards {badges}/{badgeTotal} · Lessons {modules}/{moduleTotal}'**
  String certificateProgress(
      int badges, int badgeTotal, int modules, int moduleTotal);

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @teacherLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Login'**
  String get teacherLoginTitle;

  /// No description provided for @teacherLoginButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Log In as Teacher'**
  String get teacherLoginButtonLabel;

  /// No description provided for @invalidTeacherCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid teacher credentials. Please try again.'**
  String get invalidTeacherCredentials;

  /// No description provided for @monthName.
  ///
  /// In en, this message translates to:
  /// **'Month {month}'**
  String monthName(int month);

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @nextLevelLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'Next Level Learning'**
  String get nextLevelLearningTitle;

  /// No description provided for @nextLevelLearningDesc.
  ///
  /// In en, this message translates to:
  /// **'Fun and interactive games for kids to learn and grow.'**
  String get nextLevelLearningDesc;

  /// No description provided for @learnAnywhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn Anywhere'**
  String get learnAnywhereTitle;

  /// No description provided for @learnAnywhereDesc.
  ///
  /// In en, this message translates to:
  /// **'Access lessons offline and keep learning on the go.'**
  String get learnAnywhereDesc;

  /// No description provided for @trackProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Progress'**
  String get trackProgressTitle;

  /// No description provided for @trackProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'See how well your child is doing with smart progress tracking.'**
  String get trackProgressDesc;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @forParents.
  ///
  /// In en, this message translates to:
  /// **'For Parents'**
  String get forParents;

  /// No description provided for @kulaySayaProgress.
  ///
  /// In en, this message translates to:
  /// **'Color Fun Progress'**
  String get kulaySayaProgress;

  /// No description provided for @totalSaved.
  ///
  /// In en, this message translates to:
  /// **'Total Saved'**
  String get totalSaved;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @clearCanvasQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear Canvas?'**
  String get clearCanvasQuestion;

  /// No description provided for @noArtworksYet.
  ///
  /// In en, this message translates to:
  /// **'No artworks yet.'**
  String get noArtworksYet;

  /// No description provided for @colorPagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Color a page\nand save your artwork!'**
  String get colorPagePrompt;

  /// No description provided for @startColoring.
  ///
  /// In en, this message translates to:
  /// **'Start Coloring'**
  String get startColoring;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @lessonFinishedPrompt.
  ///
  /// In en, this message translates to:
  /// **'You finished this lesson! Great job! Choose another game.'**
  String get lessonFinishedPrompt;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @readingFinishedGood.
  ///
  /// In en, this message translates to:
  /// **'✓ Finished! Good reading!'**
  String get readingFinishedGood;

  /// No description provided for @doneAlready.
  ///
  /// In en, this message translates to:
  /// **'Done already!'**
  String get doneAlready;

  /// No description provided for @noGamesAvailable2.
  ///
  /// In en, this message translates to:
  /// **'No games available'**
  String get noGamesAvailable2;

  /// No description provided for @countAndDragCorrectNumber.
  ///
  /// In en, this message translates to:
  /// **'Count and drag the correct number!'**
  String get countAndDragCorrectNumber;

  /// No description provided for @countThenDragToBasket.
  ///
  /// In en, this message translates to:
  /// **'Count the {items}, then drag the right number to the basket'**
  String countThenDragToBasket(String items);

  /// No description provided for @whatIsMissingNumber.
  ///
  /// In en, this message translates to:
  /// **'What number is missing?'**
  String get whatIsMissingNumber;

  /// No description provided for @iKnowIt.
  ///
  /// In en, this message translates to:
  /// **'I learned it!'**
  String get iKnowIt;

  /// No description provided for @familyTreeTapHint.
  ///
  /// In en, this message translates to:
  /// **'💡 Tap the members to know their relationship!'**
  String get familyTreeTapHint;

  /// No description provided for @iLearnedFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'I learned the Family Tree!'**
  String get iLearnedFamilyTree;

  /// No description provided for @thatIsOurHome.
  ///
  /// In en, this message translates to:
  /// **'That is our home!'**
  String get thatIsOurHome;

  /// No description provided for @forParentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here is your child\'s progress on E-Tarabay.'**
  String get forParentsSubtitle;

  /// No description provided for @artworks.
  ///
  /// In en, this message translates to:
  /// **'artworks'**
  String get artworks;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @recentColor.
  ///
  /// In en, this message translates to:
  /// **'Recent Color'**
  String get recentColor;

  /// No description provided for @unknownStudent.
  ///
  /// In en, this message translates to:
  /// **'Unknown Student'**
  String get unknownStudent;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @backgroundMusicPlaying.
  ///
  /// In en, this message translates to:
  /// **'Background music playing'**
  String get backgroundMusicPlaying;

  /// No description provided for @errorSaveLocal.
  ///
  /// In en, this message translates to:
  /// **'Could not save artwork locally.'**
  String get errorSaveLocal;

  /// No description provided for @finishedAlready.
  ///
  /// In en, this message translates to:
  /// **'Finished already!'**
  String get finishedAlready;

  /// No description provided for @accessExpired.
  ///
  /// In en, this message translates to:
  /// **'Your access to this app has ended. Please consult your Teacher for the next steps.'**
  String get accessExpired;

  /// No description provided for @accountPaused.
  ///
  /// In en, this message translates to:
  /// **'Access to this app has been paused for this account. Please contact support for more details.'**
  String get accountPaused;

  /// No description provided for @forceLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'You were signed out by the developer. You can log in again right away.'**
  String get forceLoggedOut;

  /// No description provided for @moduleLocked.
  ///
  /// In en, this message translates to:
  /// **'This activity is temporarily unavailable. Please check back later.'**
  String get moduleLocked;

  /// No description provided for @diffEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get diffEasy;

  /// No description provided for @diffMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get diffMedium;

  /// No description provided for @diffHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get diffHard;

  /// No description provided for @catAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get catAnimals;

  /// No description provided for @catFlowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get catFlowers;

  /// No description provided for @catFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get catFruits;

  /// No description provided for @catToys.
  ///
  /// In en, this message translates to:
  /// **'Toys'**
  String get catToys;

  /// No description provided for @poemLabel.
  ///
  /// In en, this message translates to:
  /// **'Poem'**
  String get poemLabel;

  /// No description provided for @storyLabel.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get storyLabel;

  /// No description provided for @songLabel.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get songLabel;

  /// No description provided for @uppercaseLettersTitle.
  ///
  /// In en, this message translates to:
  /// **'Capital Letters (A–Z)'**
  String get uppercaseLettersTitle;

  /// No description provided for @lowercaseLettersTitle.
  ///
  /// In en, this message translates to:
  /// **'Lowercase Letters (a–z)'**
  String get lowercaseLettersTitle;

  /// No description provided for @numbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Numbers (1–10)'**
  String get numbersTitle;

  /// No description provided for @levelComplete.
  ///
  /// In en, this message translates to:
  /// **'Level {level} Complete!'**
  String levelComplete(int level);

  /// No description provided for @pagePuppy.
  ///
  /// In en, this message translates to:
  /// **'Puppy'**
  String get pagePuppy;

  /// No description provided for @pageKuting.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get pageKuting;

  /// No description provided for @pageElepante.
  ///
  /// In en, this message translates to:
  /// **'Elephant'**
  String get pageElepante;

  /// No description provided for @pageFlowerBasket.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get pageFlowerBasket;

  /// No description provided for @pageRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get pageRose;

  /// No description provided for @pageMansanas.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get pageMansanas;

  /// No description provided for @pageSaging.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get pageSaging;

  /// No description provided for @pageTeddyBear.
  ///
  /// In en, this message translates to:
  /// **'Teddy Bear'**
  String get pageTeddyBear;

  /// Coloring page: a race car
  ///
  /// In en, this message translates to:
  /// **'Race Car'**
  String get pageRaceCar;

  /// No description provided for @favoriteChosen.
  ///
  /// In en, this message translates to:
  /// **'Your Favorite is {choice}!'**
  String favoriteChosen(String choice);

  /// No description provided for @familyRoleSentence.
  ///
  /// In en, this message translates to:
  /// **'{member} is {roles}.'**
  String familyRoleSentence(String member, String roles);

  /// No description provided for @resetAllStudents.
  ///
  /// In en, this message translates to:
  /// **'Delete All Students'**
  String get resetAllStudents;

  /// No description provided for @confirmResetAllStudents.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all enrolled students? This cannot be undone.'**
  String get confirmResetAllStudents;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @rateYourArtwork.
  ///
  /// In en, this message translates to:
  /// **'Rate Artwork'**
  String get rateYourArtwork;

  /// No description provided for @howManyStars.
  ///
  /// In en, this message translates to:
  /// **'How many stars does it deserve?'**
  String get howManyStars;

  /// No description provided for @tapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToView;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteArtwork.
  ///
  /// In en, this message translates to:
  /// **'Delete Artwork'**
  String get deleteArtwork;

  /// No description provided for @confirmDeleteArtwork.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this artwork? This cannot be undone.'**
  String get confirmDeleteArtwork;

  /// No description provided for @artworkDeleted.
  ///
  /// In en, this message translates to:
  /// **'Artwork deleted.'**
  String get artworkDeleted;

  /// No description provided for @fitPicture.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fitPicture;

  /// No description provided for @greatSinging.
  ///
  /// In en, this message translates to:
  /// **'Great singing!'**
  String get greatSinging;

  /// No description provided for @readFullPoemBeforeBack.
  ///
  /// In en, this message translates to:
  /// **'Read the entire poem before going back.'**
  String get readFullPoemBeforeBack;

  /// No description provided for @tandaanTitle.
  ///
  /// In en, this message translates to:
  /// **'Remember It!'**
  String get tandaanTitle;

  /// No description provided for @tandaanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match the Pairs'**
  String get tandaanSubtitle;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get round;

  /// No description provided for @matchThePairs.
  ///
  /// In en, this message translates to:
  /// **'Find the Matching Pairs!'**
  String get matchThePairs;

  /// No description provided for @flipCardsToMatch.
  ///
  /// In en, this message translates to:
  /// **'Tap a card to flip it. Find two that match!'**
  String get flipCardsToMatch;

  /// Home card wording for a module
  ///
  /// In en, this message translates to:
  /// **'Trace It'**
  String get traceItTitle;

  /// Home card wording for a module
  ///
  /// In en, this message translates to:
  /// **'Learn Your ABC!'**
  String get traceItSubtitle;

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String percentComplete(int percent);

  /// No description provided for @categoryProgressHeader.
  ///
  /// In en, this message translates to:
  /// **'Progress Per Category'**
  String get categoryProgressHeader;

  /// No description provided for @savedArtworksHeader.
  ///
  /// In en, this message translates to:
  /// **'Saved Artworks'**
  String get savedArtworksHeader;

  /// No description provided for @parentTipsHeader.
  ///
  /// In en, this message translates to:
  /// **'Tips for Parents'**
  String get parentTipsHeader;

  /// No description provided for @tipKulayTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Fun'**
  String get tipKulayTitle;

  /// No description provided for @tipKulayBody.
  ///
  /// In en, this message translates to:
  /// **'Encourage your child to color all the pages in every category. This helps develop creativity and fine motor skills.'**
  String get tipKulayBody;

  /// No description provided for @tipTraceItTitle.
  ///
  /// In en, this message translates to:
  /// **'Trace It'**
  String get tipTraceItTitle;

  /// No description provided for @tipTraceItBody.
  ///
  /// In en, this message translates to:
  /// **'Guide your child in following the correct direction and strokes when tracing each other.'**
  String get tipTraceItBody;

  /// No description provided for @tipMagbasaTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories and Songs'**
  String get tipMagbasaTitle;

  /// No description provided for @tipMagbasaBody.
  ///
  /// In en, this message translates to:
  /// **'Read the poem stories and songs aloud together with your child. Encourage your child to read along.'**
  String get tipMagbasaBody;

  /// No description provided for @tipMatematikaTitle.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get tipMatematikaTitle;

  /// No description provided for @tipMatematikaBody.
  ///
  /// In en, this message translates to:
  /// **'Encourage your child to complete every game to build stronger number skills.'**
  String get tipMatematikaBody;

  /// No description provided for @tipStudyTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Time'**
  String get tipStudyTimeTitle;

  /// No description provided for @tipStudyTimeBody.
  ///
  /// In en, this message translates to:
  /// **'Set aside 15-20 minutes each day for learning and practice. Regular practice can help your child build confidence and improve their skills.'**
  String get tipStudyTimeBody;

  /// No description provided for @gameProgressHeader.
  ///
  /// In en, this message translates to:
  /// **'Progress Per Game'**
  String get gameProgressHeader;

  /// No description provided for @tipPencilGripTitle.
  ///
  /// In en, this message translates to:
  /// **'Proper Pencil Grip'**
  String get tipPencilGripTitle;

  /// No description provided for @tipPencilGripBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure your child holds the stylus or uses their fingers correctly when tracing each letter.'**
  String get tipPencilGripBody;

  /// No description provided for @tipRepeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat as needed'**
  String get tipRepeatTitle;

  /// No description provided for @tipRepeatBody.
  ///
  /// In en, this message translates to:
  /// **'Encourage your child to trace unfinished letters again and keep practicing.'**
  String get tipRepeatBody;

  /// No description provided for @tipPraiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Praise Your Child'**
  String get tipPraiseTitle;

  /// No description provided for @tipPraiseBody.
  ///
  /// In en, this message translates to:
  /// **'Praise every achievement, big or small, to build their confidence.'**
  String get tipPraiseBody;

  /// No description provided for @tipTulaTitle.
  ///
  /// In en, this message translates to:
  /// **'Poems'**
  String get tipTulaTitle;

  /// No description provided for @tipTulaBody.
  ///
  /// In en, this message translates to:
  /// **'Read the poems aloud with your child to practice pronunciation and reading fluency.'**
  String get tipTulaBody;

  /// No description provided for @tipKwentoTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get tipKwentoTitle;

  /// No description provided for @tipKwentoBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your child questions about the story after reading to strengthen comprehension.'**
  String get tipKwentoBody;

  /// No description provided for @tipKantaTitle.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get tipKantaTitle;

  /// No description provided for @tipKantaBody.
  ///
  /// In en, this message translates to:
  /// **'Sing the songs together with your child to make learning fun and enjoyable.'**
  String get tipKantaBody;

  /// No description provided for @tipCountingTitle.
  ///
  /// In en, this message translates to:
  /// **'Counting'**
  String get tipCountingTitle;

  /// No description provided for @tipCountingBody.
  ///
  /// In en, this message translates to:
  /// **'Use everyday objects like fruits or toys to help your child practice counting.'**
  String get tipCountingBody;

  /// No description provided for @tipPraiseMatTitle.
  ///
  /// In en, this message translates to:
  /// **'Praise'**
  String get tipPraiseMatTitle;

  /// No description provided for @tipPraiseMatBody.
  ///
  /// In en, this message translates to:
  /// **'Praise your child for every correct answer to build their confidence and interest in Math.'**
  String get tipPraiseMatBody;

  /// No description provided for @tipGameFunTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get tipGameFunTitle;

  /// No description provided for @tipGameFunBody.
  ///
  /// In en, this message translates to:
  /// **'The games are designed to make learning enjoyable. Let your child explore, play, and enjoy learning at their own pace.'**
  String get tipGameFunBody;

  /// No description provided for @badgeFirstStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'First Steps'**
  String get badgeFirstStepsTitle;

  /// No description provided for @badgeFirstStepsHint.
  ///
  /// In en, this message translates to:
  /// **'Earn your first 3 stars'**
  String get badgeFirstStepsHint;

  /// No description provided for @badgeAlphabetTitle.
  ///
  /// In en, this message translates to:
  /// **'Alphabet Master'**
  String get badgeAlphabetTitle;

  /// No description provided for @badgeAlphabetHint.
  ///
  /// In en, this message translates to:
  /// **'Collect all 19 stars in Let\'s Read'**
  String get badgeAlphabetHint;

  /// No description provided for @badgeNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Number Wizard'**
  String get badgeNumbersTitle;

  /// No description provided for @badgeNumbersHint.
  ///
  /// In en, this message translates to:
  /// **'Trace all 10 numbers'**
  String get badgeNumbersHint;

  /// No description provided for @badgeColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Artist'**
  String get badgeColorsTitle;

  /// No description provided for @badgeColorsHint.
  ///
  /// In en, this message translates to:
  /// **'Collect all 9 stars in Color Fun'**
  String get badgeColorsHint;

  /// No description provided for @badgeShapesTitle.
  ///
  /// In en, this message translates to:
  /// **'Big Letters'**
  String get badgeShapesTitle;

  /// No description provided for @badgeShapesHint.
  ///
  /// In en, this message translates to:
  /// **'Trace all 26 capital letters'**
  String get badgeShapesHint;

  /// No description provided for @badgeAnimalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Small Letters'**
  String get badgeAnimalsTitle;

  /// No description provided for @badgeAnimalsHint.
  ///
  /// In en, this message translates to:
  /// **'Trace all 26 small letters'**
  String get badgeAnimalsHint;

  /// No description provided for @badgeBookwormTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookworm'**
  String get badgeBookwormTitle;

  /// No description provided for @badgeBookwormHint.
  ///
  /// In en, this message translates to:
  /// **'Collect all 5 stars in Stories'**
  String get badgeBookwormHint;

  /// No description provided for @badgeStarStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'All About Me'**
  String get badgeStarStudentTitle;

  /// No description provided for @badgeStarStudentHint.
  ///
  /// In en, this message translates to:
  /// **'Get 3 stars on all 4 About Myself levels'**
  String get badgeStarStudentHint;

  /// No description provided for @badgeMathWhizTitle.
  ///
  /// In en, this message translates to:
  /// **'Math Expert'**
  String get badgeMathWhizTitle;

  /// No description provided for @badgeMathWhizHint.
  ///
  /// In en, this message translates to:
  /// **'Get 3 stars on all 7 math levels'**
  String get badgeMathWhizHint;

  /// No description provided for @badgeFamilyHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Hero'**
  String get badgeFamilyHeroTitle;

  /// No description provided for @badgeFamilyHeroHint.
  ///
  /// In en, this message translates to:
  /// **'Get 3 stars on all 5 family levels'**
  String get badgeFamilyHeroHint;

  /// No description provided for @badgeWritingStarTitle.
  ///
  /// In en, this message translates to:
  /// **'Writing Star'**
  String get badgeWritingStarTitle;

  /// No description provided for @badgeWritingStarHint.
  ///
  /// In en, this message translates to:
  /// **'Trace every letter and number'**
  String get badgeWritingStarHint;

  /// No description provided for @badgeSongbirdTitle.
  ///
  /// In en, this message translates to:
  /// **'Songbird'**
  String get badgeSongbirdTitle;

  /// No description provided for @badgeSongbirdHint.
  ///
  /// In en, this message translates to:
  /// **'Collect all 9 stars in Songs'**
  String get badgeSongbirdHint;

  /// No description provided for @badgeStreakFiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Every Day Star'**
  String get badgeStreakFiveTitle;

  /// No description provided for @badgeStreakFiveHint.
  ///
  /// In en, this message translates to:
  /// **'Play on 5 days in a row'**
  String get badgeStreakFiveHint;

  /// No description provided for @claimBadgeButton.
  ///
  /// In en, this message translates to:
  /// **'Claim Badge'**
  String get claimBadgeButton;

  /// No description provided for @badgeClaimed.
  ///
  /// In en, this message translates to:
  /// **'BADGE CLAIMED'**
  String get badgeClaimed;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @claimBadgeBody.
  ///
  /// In en, this message translates to:
  /// **'You earned this badge! Claim it to add it to your collection.'**
  String get claimBadgeBody;

  /// No description provided for @claimBadge.
  ///
  /// In en, this message translates to:
  /// **'Claim {title}'**
  String claimBadge(String title);

  /// No description provided for @awardsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{earned} earned, {remaining} waiting to be claimed!'**
  String awardsWaiting(int earned, int remaining);

  /// Smallest of the three brush sizes
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get brushSmall;

  /// Middle of the three brush sizes
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get brushMedium;

  /// Largest of the three brush sizes
  ///
  /// In en, this message translates to:
  /// **'Big'**
  String get brushLarge;

  /// Confirms wiping the drawing and starting again
  ///
  /// In en, this message translates to:
  /// **'Yes, start over'**
  String get startOverYes;

  /// Declines wiping the drawing
  ///
  /// In en, this message translates to:
  /// **'No, keep it'**
  String get keepColoring;

  /// Shown while a saved drawing is reopened
  ///
  /// In en, this message translates to:
  /// **'Loading your artwork...'**
  String get loadingArtwork;

  /// Shown while the memory cards are face up before a round
  ///
  /// In en, this message translates to:
  /// **'Remember the cards!'**
  String get memoriseTheCards;

  /// Home card wording for a module
  ///
  /// In en, this message translates to:
  /// **'Let\'s Count!'**
  String get letsCount;

  /// Count of enrolled children on the teacher dashboard
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsLabel;

  /// Children who have finished under a quarter of the app
  ///
  /// In en, this message translates to:
  /// **'Falling behind'**
  String get needsHelp;

  /// Children with no activity in the last seven days
  ///
  /// In en, this message translates to:
  /// **'Not playing'**
  String get notSeenRecently;

  /// Note under the class breakdown explaining the order
  ///
  /// In en, this message translates to:
  /// **'Weakest module first'**
  String get weakestFirst;

  /// Placeholder in the teacher search field
  ///
  /// In en, this message translates to:
  /// **'Search students'**
  String get searchStudents;

  /// Shown when a search matches nobody
  ///
  /// In en, this message translates to:
  /// **'No student found'**
  String get noStudentsMatch;

  /// Heading of the About Me parent report
  ///
  /// In en, this message translates to:
  /// **'About me and my family'**
  String get sariliProgress;

  /// Heading of the Remember It parent report
  ///
  /// In en, this message translates to:
  /// **'Remember It!'**
  String get tandaanProgress;

  /// Stars earned out of the stars available
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} stars'**
  String starsOfPossible(int earned, int total);

  /// Shown against a level the child has not opened
  ///
  /// In en, this message translates to:
  /// **'Not yet started'**
  String get notStartedYet;

  /// Subtitle of the Remember It parent report
  ///
  /// In en, this message translates to:
  /// **'Matching pairs'**
  String get memoryPairs;

  /// Remember It category
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get fruits;

  /// Remember It category
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get shapes;

  /// Remember It category
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get letters;

  /// Title when a parent first sets their access code
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit code'**
  String get setParentPin;

  /// Explains that the code must be secret from the child
  ///
  /// In en, this message translates to:
  /// **'Only you should know this. The child must not be able to guess it.'**
  String get setParentPinNote;

  /// Second field when setting the code
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get confirmParentPin;

  /// Title when a parent is asked for their existing code
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get enterParentPin;

  /// The two entries did not match
  ///
  /// In en, this message translates to:
  /// **'The two codes are different'**
  String get pinMismatch;

  /// The code entered was not correct
  ///
  /// In en, this message translates to:
  /// **'Wrong code'**
  String get wrongPin;

  /// Link back to the LRN as a recovery route
  ///
  /// In en, this message translates to:
  /// **'Forgot code? Use the Student Number'**
  String get forgotPin;

  /// Button that opens the parents report
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openReport;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountSecurity;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityHeader;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Change Login'**
  String get changeLogin;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Update username or password'**
  String get changeLoginNote;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Fingerprint / Face login'**
  String get biometricLogin;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Enable fingerprint login'**
  String get enableBiometric;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Leave the password blank to change only the username.'**
  String get blankToKeepPassword;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'New password (Student Number)'**
  String get newPasswordStudentNumber;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'No student session found. Please log in first.'**
  String get noSessionLogInFirst;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Reset Specific Activity'**
  String get resetSpecificActivity;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Reset All Activities'**
  String get resetAllActivities;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// Reset button with how many activities are selected
  ///
  /// In en, this message translates to:
  /// **'Reset ({count})'**
  String resetCount(int count);

  /// Title of the reset picker, with the child name
  ///
  /// In en, this message translates to:
  /// **'Choose which activities to reset for {name}:'**
  String pickActivitiesToReset(String name);

  /// Confirmation before wiping a child’s progress
  ///
  /// In en, this message translates to:
  /// **'Reset all of {name}’s progress? This cannot be undone.'**
  String confirmResetAll(String name);

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'No artwork saved yet.'**
  String get noArtworksSaved;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get middleName;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Student Information'**
  String get studentInformation;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Parent Information'**
  String get parentInformation;

  /// Progress through the enrolment wizard
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total} · {label}'**
  String stepOf(int current, int total, String label);

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Could not load. Please try again.'**
  String get couldNotLoad;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Sign in to your teacher account'**
  String get teacherSignInPrompt;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint / face'**
  String get useBiometric;

  /// Shown when the device has no biometrics
  ///
  /// In en, this message translates to:
  /// **'No fingerprint or face is set up on this phone, so this login is unavailable.'**
  String get biometricUnavailable;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'Login updated.'**
  String get credentialsUpdated;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'Fingerprint login is on.'**
  String get biometricEnabled;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'Fingerprint login is off.'**
  String get biometricDisabled;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'Not confirmed. Please try again.'**
  String get biometricNotConfirmed;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'The two passwords are different.'**
  String get passwordsDoNotMatch;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'Please enter a username.'**
  String get usernameEmpty;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'That password is not correct.'**
  String get passwordIncorrect;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'That Student Number is not correct.'**
  String get studentNumberIncorrect;

  /// Message shown to a teacher or parent
  ///
  /// In en, this message translates to:
  /// **'Confirm the child\'s Student Number'**
  String get confirmChildStudentNumber;

  /// Prompt shown by the fingerprint scanner
  ///
  /// In en, this message translates to:
  /// **'Scan to turn on fingerprint login'**
  String get scanToEnableBiometric;

  /// Result of saving a certificate
  ///
  /// In en, this message translates to:
  /// **'Certificate saved to your photos'**
  String get certificateSaved;

  /// Result of saving a certificate
  ///
  /// In en, this message translates to:
  /// **'Could not save the certificate.'**
  String get certificateSaveFailed;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'How you earn stars here:'**
  String get howStarsEarned;

  /// No description provided for @starRequirements.
  ///
  /// In en, this message translates to:
  /// **'Star Requirements'**
  String get starRequirements;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'You finished it'**
  String get starOneTitle;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'Every activity you finish earns one.'**
  String get starOneBody;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'Almost all right'**
  String get starTwoTitle;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'One wrong answer along the way.'**
  String get starTwoBody;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'You got them all right on your first try!'**
  String get starThreeTitle;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'No wrong answers at all.'**
  String get starThreeBody;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'Play it again and try to get every answer right.'**
  String get starTip;

  /// Explains the 1-to-3 star rating
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'Your code'**
  String get yourCode;

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'Enter the four digits to open this report.'**
  String get yourCodeNote;

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'Change code'**
  String get changeCode;

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'Current code'**
  String get currentCode;

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get newCode;

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'Code changed.'**
  String get codeChanged;

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'Your child\'s login'**
  String get childLogin;

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'What your child types to open the app. The teacher can change it too.'**
  String get childLoginNote;

  /// When the child last played
  ///
  /// In en, this message translates to:
  /// **'Played today'**
  String get playedToday;

  /// When the child last played
  ///
  /// In en, this message translates to:
  /// **'Played yesterday'**
  String get playedYesterday;

  /// When the child last played
  ///
  /// In en, this message translates to:
  /// **'Last played {days} days ago'**
  String playedDaysAgo(int days);

  /// When the child last played
  ///
  /// In en, this message translates to:
  /// **'Has not yet started'**
  String get notPlayedYet;

  /// When the child last played
  ///
  /// In en, this message translates to:
  /// **'{days} days in a row'**
  String dayRun(int days);

  /// Removing a child from this device
  ///
  /// In en, this message translates to:
  /// **'Remove from this phone'**
  String get removeFromDevice;

  /// Removing a child from this device
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer appear here or on the sign-in screen. Their account and their work are not deleted — a teacher can sign them in again.'**
  String removeFromDeviceNote(String name);

  /// Removing a child from this device
  ///
  /// In en, this message translates to:
  /// **'Removed from this phone.'**
  String get childRemoved;

  /// Teacher sheet section heading
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get chooseAvatar;

  /// No description provided for @chooseYourAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get chooseYourAvatar;

  /// Teacher sheet section heading
  ///
  /// In en, this message translates to:
  /// **'Manage this student'**
  String get manageStudent;

  /// Shown when enrolment cannot mint a free number
  ///
  /// In en, this message translates to:
  /// **'No student numbers are left for this year.'**
  String get noStudentNumbersLeft;

  /// Explains an active class filter
  ///
  /// In en, this message translates to:
  /// **'Started, but is progressing more slowly than the class.'**
  String get filterBehindNote;

  /// Explains an active class filter
  ///
  /// In en, this message translates to:
  /// **'Has not opened the app in a week or more.'**
  String get filterQuietNote;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'Nothing to update.'**
  String get authNothingToUpdate;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'Could not save the changes. Check your connection.'**
  String get authSaveFailed;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'That username is already taken. Please pick another.'**
  String get authUsernameTaken;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'This is the pupil sign-in. Use \"Continue as Teacher\" at the bottom of the screen.'**
  String get authUseTeacherButton;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'No such username. Check the spelling, or ask the teacher whether the child is enrolled.'**
  String get authUsernameNotFound;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'That Student Number is not right. Please try again.'**
  String get authWrongStudentNumber;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection.'**
  String get authConnectionError;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'The Student Number cannot be empty.'**
  String get authNumberEmpty;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'The Student Number must look like DC-2026-0001.'**
  String get authNumberFormat;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'The Student Number cannot end in four identical digits.'**
  String get authNumberRepeated;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'Another child already has this Student Number.'**
  String get authNumberTaken;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'Could not enrol the child. Check your connection.'**
  String get authEnrollFailed;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'There are no children to remove.'**
  String get authNoStudentsToDelete;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'All children removed.'**
  String get authAllStudentsDeleted;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'Could not remove the children. Please try again.'**
  String get authDeleteFailed;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'There are no children to reset.'**
  String get authNoStudentsToReset;

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'Reset the sign-in of {count} children.'**
  String authResetDone(int count);

  /// Result of a sign-in, enrolment or class action
  ///
  /// In en, this message translates to:
  /// **'Could not reset the sign-in. Please try again.'**
  String get authResetFailed;

  /// Student password, shown to the teacher
  ///
  /// In en, this message translates to:
  /// **'Not set yet.'**
  String get passwordNotSetYet;

  /// Student password, shown to the teacher
  ///
  /// In en, this message translates to:
  /// **'The parent has changed this. It is no longer the Student Number.'**
  String get passwordChangedByParent;

  /// Student password, shown to the teacher
  ///
  /// In en, this message translates to:
  /// **'The password needs at least 4 characters.'**
  String get authPasswordTooShort;

  /// Teacher's per-child practice list
  ///
  /// In en, this message translates to:
  /// **'What to practise'**
  String get whatToPractise;

  /// Teacher's per-child practice list
  ///
  /// In en, this message translates to:
  /// **'Nothing outstanding. This child is getting the questions right.'**
  String get nothingToPractise;

  /// Subtitle when a teacher opens the report
  ///
  /// In en, this message translates to:
  /// **'This pupil\'s progress on E-Tarabay.'**
  String get pupilReport;

  /// Opens the child's details form from their card
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editStudent;

  /// Shown when the browser refuses the clipboard
  ///
  /// In en, this message translates to:
  /// **'This browser will not let the app copy. Select it and copy by hand.'**
  String get copyByHand;

  /// First box when a parent is creating their code
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get newParentPin;

  /// Parent switches to their other child
  ///
  /// In en, this message translates to:
  /// **'Open {name}\'s account'**
  String switchToChild(String name);

  /// Parent switches to their other child
  ///
  /// In en, this message translates to:
  /// **'The app becomes {name}\'s. Nobody has to sign in again, and their work is kept.'**
  String switchToChildNote(String name);

  /// Parent switches to their other child
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchAccount;

  /// Parent switches to their other child
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet first — this child has work that is only on this phone.'**
  String get switchNeedsConnection;

  /// No description provided for @streakWord.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakWord;

  /// No description provided for @notifPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your phone settings first.'**
  String get notifPermissionDenied;

  /// No description provided for @greetMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning!'**
  String get greetMorning;

  /// No description provided for @greetAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon!'**
  String get greetAfternoon;

  /// No description provided for @greetEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening!'**
  String get greetEvening;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is available!'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready.'**
  String updateAvailableBody(String version);

  /// No description provided for @updateDownloadNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateDownloadNow;

  /// No description provided for @updateOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open in your browser: {url}'**
  String updateOpenWebsite(String url);

  /// No description provided for @watchHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watchHowToPlay;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @bgPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell Mom or Dad!'**
  String get bgPermissionTitle;

  /// Shown once after turning Notifications on, so a child can relay it to a parent on OEMs (Oppo/Vivo/Realme/Xiaomi) that kill background alarms unless the app is whitelisted
  ///
  /// In en, this message translates to:
  /// **'For the reminders to work, ask them to allow E-Tarabay in the phone\'s Battery and Autostart settings.'**
  String get bgPermissionBody;

  /// Family Roles: shown for any answer other than the listed one — there is no wrong answer in this game.
  ///
  /// In en, this message translates to:
  /// **'Yes! Every family member can help.'**
  String get roleAnyAnswer;

  /// No description provided for @yesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesAnswer;

  /// No description provided for @noAnswer.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noAnswer;

  /// No description provided for @resetActivitiesDone.
  ///
  /// In en, this message translates to:
  /// **'The selected activities were reset.'**
  String get resetActivitiesDone;

  /// No description provided for @resetActivitiesFailed.
  ///
  /// In en, this message translates to:
  /// **'The activities could not be reset. Please try again.'**
  String get resetActivitiesFailed;

  /// No description provided for @letterWord.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get letterWord;

  /// No description provided for @numberWord.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get numberWord;

  /// Title of the certificate screen
  ///
  /// In en, this message translates to:
  /// **'My Certificate'**
  String get myCertificate;

  /// Text sent along with a shared certificate
  ///
  /// In en, this message translates to:
  /// **'I just earned a new certificate on E-Tarabay!'**
  String get shareCertificateText;

  /// Under the score in the lesson result
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// Result pill for three stars; the part before • is the count
  ///
  /// In en, this message translates to:
  /// **'3/3 Stars • Perfect Score! Outstanding!'**
  String get starSummary3;

  /// Result pill for two stars
  ///
  /// In en, this message translates to:
  /// **'2/3 Stars • 1 empty star remaining.'**
  String get starSummary2;

  /// Result pill for one star
  ///
  /// In en, this message translates to:
  /// **'1/3 Star • 2 empty stars remaining.'**
  String get starSummary1;

  /// Result pill for no stars
  ///
  /// In en, this message translates to:
  /// **'0/3 Stars'**
  String get starSummary0;

  /// A star and what earns it, in the star breakdown
  ///
  /// In en, this message translates to:
  /// **'Star {starNumber}: {title}'**
  String starNumberTitle(String starNumber, String title);

  /// Tag on a star that was earned
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get starEarned;

  /// Tag on a star not earned yet
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get starEmpty;

  /// How many artworks the child has saved
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 artwork} other{{count} artworks}}'**
  String artworkCount(int count);

  /// Sort the saved artworks newest first
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortRecent;

  /// Overall grade, 90% and up
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get gradeOutstanding;

  /// Overall grade, 80% and up
  ///
  /// In en, this message translates to:
  /// **'Very Satisfactory'**
  String get gradeVerySatisfactory;

  /// Overall grade, 75% and up
  ///
  /// In en, this message translates to:
  /// **'Satisfactory'**
  String get gradeSatisfactory;

  /// Overall grade, under 75%
  ///
  /// In en, this message translates to:
  /// **'Developing'**
  String get gradeDeveloping;

  /// Shown by the phone while it reads the fingerprint
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get biometricPrompt;

  /// Fingerprint button with the saved child's name
  ///
  /// In en, this message translates to:
  /// **'Sign in as {name}'**
  String signInAs(String name);

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get enterCurrentPassword;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match.'**
  String get newPasswordsDoNotMatch;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Nothing to change.'**
  String get nothingToChange;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get currentPasswordIncorrect;

  /// Teacher settings section
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get sectionAudio;

  /// Teacher settings section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// Teacher settings section
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get sectionClassroom;

  /// Under the fingerprint switch in teacher settings
  ///
  /// In en, this message translates to:
  /// **'Skip typing your password next time'**
  String get skipPasswordNextTime;

  /// Teacher login error
  ///
  /// In en, this message translates to:
  /// **'Your password changed. Please sign in with your password once.'**
  String get teacherPasswordChanged;

  /// Teacher login error
  ///
  /// In en, this message translates to:
  /// **'Teacher account not set up yet. Please connect to the internet once to finish setup.'**
  String get teacherNotSetUp;

  /// Teacher login error
  ///
  /// In en, this message translates to:
  /// **'Could not verify credentials. If this is your first login, please connect to the internet once.'**
  String get teacherCannotVerify;

  /// Teacher dashboard banner
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Birthday today!} other{{count} birthdays today!}}'**
  String birthdayToday(int count);

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeTo;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// The tune of a song that is a recording, not a known melody
  ///
  /// In en, this message translates to:
  /// **'Audio Recording'**
  String get audioRecordingTune;

  /// Tag on a coloring page begun but not saved yet
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// Asked when leaving a picture with coloring not saved
  ///
  /// In en, this message translates to:
  /// **'Save your coloring?'**
  String get leaveColoringTitle;

  /// Under the save question when leaving a picture
  ///
  /// In en, this message translates to:
  /// **'Your coloring is kept even if you don\'t save it.'**
  String get leaveColoringBody;

  /// Leave without saving now
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @allStudentsTab.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allStudentsTab;

  /// No description provided for @protectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Protected: locks when you leave the app'**
  String get protectedBadge;

  /// No description provided for @showLabel.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showLabel;

  /// No description provided for @hideLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideLabel;

  /// No description provided for @newBadgeShort.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadgeShort;

  /// No description provided for @consentStep.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get consentStep;

  /// No description provided for @enrollStepChild.
  ///
  /// In en, this message translates to:
  /// **'Who is the child?'**
  String get enrollStepChild;

  /// No description provided for @enrollStepParent.
  ///
  /// In en, this message translates to:
  /// **'Who is the parent or guardian?'**
  String get enrollStepParent;

  /// No description provided for @enrollStepConsent.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s consent'**
  String get enrollStepConsent;

  /// Step counter in the enrol sheet
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepNumber(int current, int total);

  /// No description provided for @reviewBeforeEnroll.
  ///
  /// In en, this message translates to:
  /// **'Check before enrolling'**
  String get reviewBeforeEnroll;

  /// No description provided for @childLabel.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get childLabel;

  /// No description provided for @parentLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentLabelShort;

  /// No description provided for @numberLabel.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get numberLabel;

  /// No description provided for @parentConsentCheck.
  ///
  /// In en, this message translates to:
  /// **'The parent or guardian agreed to record this information only for the child\'s learning in E-Tarabay.'**
  String get parentConsentCheck;

  /// No description provided for @consentLawNote.
  ///
  /// In en, this message translates to:
  /// **'Under the Data Privacy Act of 2012 (RA 10173). The date of consent is recorded.'**
  String get consentLawNote;

  /// No description provided for @privacyAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Agreement'**
  String get privacyAgreementTitle;

  /// No description provided for @privacyAgreementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To keep the children\'s information safe.'**
  String get privacyAgreementSubtitle;

  /// No description provided for @privacyPromise1.
  ///
  /// In en, this message translates to:
  /// **'I will not share the children\'s names, birthdays or their parents\' numbers with anyone.'**
  String get privacyPromise1;

  /// No description provided for @privacyPromise2.
  ///
  /// In en, this message translates to:
  /// **'I will use the information only for the children\'s learning.'**
  String get privacyPromise2;

  /// No description provided for @privacyPromise3.
  ///
  /// In en, this message translates to:
  /// **'I will not leave the app open, and my phone has a lock.'**
  String get privacyPromise3;

  /// No description provided for @privacyPromise4.
  ///
  /// In en, this message translates to:
  /// **'I will tell the school at once if the phone is lost or someone else sees the information.'**
  String get privacyPromise4;

  /// No description provided for @signatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Your full name as your signature'**
  String get signatureLabel;

  /// No description provided for @signatureHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mrs. Maria Santos'**
  String get signatureHint;

  /// No description provided for @agreeCheck.
  ///
  /// In en, this message translates to:
  /// **'I agree to this agreement.'**
  String get agreeCheck;

  /// No description provided for @enterDashboard.
  ///
  /// In en, this message translates to:
  /// **'Continue to the dashboard'**
  String get enterDashboard;

  /// Who agreed to the privacy agreement and when
  ///
  /// In en, this message translates to:
  /// **'Agreed by {name} on {date}'**
  String agreedOn(String name, String date);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyNote.
  ///
  /// In en, this message translates to:
  /// **'The promise you agreed to'**
  String get privacyPolicyNote;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the password'**
  String get lockTitle;

  /// No description provided for @lockBody.
  ///
  /// In en, this message translates to:
  /// **'The children\'s information is protected.'**
  String get lockBody;

  /// No description provided for @teacherPasswordField.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s password'**
  String get teacherPasswordField;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get unlockButton;

  /// No description provided for @lockReason.
  ///
  /// In en, this message translates to:
  /// **'Open the teacher dashboard'**
  String get lockReason;

  /// No description provided for @pinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN'**
  String get pinTitle;

  /// Wrong PIN on the teacher lock
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =1{Wrong PIN. 1 try left.} other{Wrong PIN. {left} tries left.}}'**
  String pinWrong(int left);

  /// No description provided for @pinBlocked.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong tries. The password is needed now.'**
  String get pinBlocked;

  /// No description provided for @teacherForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot the PIN?'**
  String get teacherForgotPin;

  /// No description provided for @usePassword.
  ///
  /// In en, this message translates to:
  /// **'Use the password'**
  String get usePassword;

  /// No description provided for @createPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a PIN'**
  String get createPinTitle;

  /// No description provided for @createPinBody.
  ///
  /// In en, this message translates to:
  /// **'4 numbers that open the dashboard on this phone.'**
  String get createPinBody;

  /// No description provided for @confirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get confirmPinTitle;

  /// No description provided for @teacherPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs are not the same. Try again.'**
  String get teacherPinMismatch;

  /// No description provided for @currentPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get currentPinTitle;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change the PIN'**
  String get changePin;

  /// No description provided for @changePinNote.
  ///
  /// In en, this message translates to:
  /// **'4 numbers that open the dashboard'**
  String get changePinNote;

  /// No description provided for @pinSaved.
  ///
  /// In en, this message translates to:
  /// **'New PIN saved.'**
  String get pinSaved;

  /// No description provided for @deleteDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDigit;

  /// No description provided for @passwordToResetPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the teacher\'s password to make a new PIN.'**
  String get passwordToResetPin;

  /// No description provided for @privacyAgreementIntro.
  ///
  /// In en, this message translates to:
  /// **'You hold the children\'s personal information. Read and agree to these:'**
  String get privacyAgreementIntro;

  /// No description provided for @agreeToContinueHint.
  ///
  /// In en, this message translates to:
  /// **'Type your name and tick the agreement to continue.'**
  String get agreeToContinueHint;

  /// No description provided for @lawPill.
  ///
  /// In en, this message translates to:
  /// **'RA 10173'**
  String get lawPill;

  /// No description provided for @reportStarsTile.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get reportStarsTile;

  /// No description provided for @reportDoneTile.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reportDoneTile;

  /// No description provided for @reportLastPlayedTile.
  ///
  /// In en, this message translates to:
  /// **'Last played'**
  String get reportLastPlayedTile;

  /// No description provided for @lastPlayedToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get lastPlayedToday;

  /// No description provided for @lastPlayedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get lastPlayedYesterday;

  /// No description provided for @lastPlayedDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String lastPlayedDays(int days);

  /// No description provided for @practiceMisses.
  ///
  /// In en, this message translates to:
  /// **'{count} wrong'**
  String practiceMisses(int count);

  /// No description provided for @childWorksHeader.
  ///
  /// In en, this message translates to:
  /// **'Child\'s work'**
  String get childWorksHeader;

  /// No description provided for @teacherToolsHeader.
  ///
  /// In en, this message translates to:
  /// **'Teacher tools'**
  String get teacherToolsHeader;

  /// No description provided for @toolEditInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit info'**
  String get toolEditInfo;

  /// No description provided for @toolEditInfoNote.
  ///
  /// In en, this message translates to:
  /// **'Name, gender, parent'**
  String get toolEditInfoNote;

  /// No description provided for @toolLogin.
  ///
  /// In en, this message translates to:
  /// **'Child\'s login'**
  String get toolLogin;

  /// No description provided for @toolLoginNote.
  ///
  /// In en, this message translates to:
  /// **'Give it to the parent'**
  String get toolLoginNote;

  /// No description provided for @toolReset.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get toolReset;

  /// No description provided for @toolResetNote.
  ///
  /// In en, this message translates to:
  /// **'One module or all'**
  String get toolResetNote;

  /// No description provided for @percentDone.
  ///
  /// In en, this message translates to:
  /// **'{percent}% done'**
  String percentDone(int percent);

  /// No description provided for @ofStars.
  ///
  /// In en, this message translates to:
  /// **'of {count} stars'**
  String ofStars(int count);

  /// No description provided for @levelsHeader.
  ///
  /// In en, this message translates to:
  /// **'Each level'**
  String get levelsHeader;

  /// No description provided for @resetModule.
  ///
  /// In en, this message translates to:
  /// **'Reset {name}'**
  String resetModule(String name);

  /// No description provided for @resetSheetSub.
  ///
  /// In en, this message translates to:
  /// **'{name} · cannot be undone'**
  String resetSheetSub(String name);

  /// No description provided for @resetPickModules.
  ///
  /// In en, this message translates to:
  /// **'Chosen modules'**
  String get resetPickModules;

  /// No description provided for @resetPickModulesNote.
  ///
  /// In en, this message translates to:
  /// **'Only the chosen ones are cleared'**
  String get resetPickModulesNote;

  /// No description provided for @resetAllModules.
  ///
  /// In en, this message translates to:
  /// **'All modules'**
  String get resetAllModules;

  /// No description provided for @resetAllModulesNote.
  ///
  /// In en, this message translates to:
  /// **'All progress goes back to the start'**
  String get resetAllModulesNote;

  /// No description provided for @resetWarnKeepDrawings.
  ///
  /// In en, this message translates to:
  /// **'Stars and finished games in {count} module(s) will be cleared. The drawings are kept.'**
  String resetWarnKeepDrawings(int count);

  /// No description provided for @resetWarnDrawings.
  ///
  /// In en, this message translates to:
  /// **'Stars and finished games in {count} module(s) will be cleared, and the drawings too.'**
  String resetWarnDrawings(int count);

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand this cannot be undone.'**
  String get resetConfirm;

  /// No description provided for @tabLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get tabLogin;

  /// No description provided for @noChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get noChanges;

  /// No description provided for @childPicksPicture.
  ///
  /// In en, this message translates to:
  /// **'The child picks their own picture at their first sign-in.'**
  String get childPicksPicture;

  /// No description provided for @parentNumberUse.
  ///
  /// In en, this message translates to:
  /// **'Only for calling about the child\'s learning.'**
  String get parentNumberUse;

  /// No description provided for @showLoginCard.
  ///
  /// In en, this message translates to:
  /// **'Show the login card'**
  String get showLoginCard;

  /// No description provided for @removeStudentAction.
  ///
  /// In en, this message translates to:
  /// **'Remove student'**
  String get removeStudentAction;

  /// No description provided for @loginUser.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUser;

  /// No description provided for @loginCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Login card'**
  String get loginCardTitle;

  /// No description provided for @loginCardStudent.
  ///
  /// In en, this message translates to:
  /// **'Student at E-Tarabay'**
  String get loginCardStudent;

  /// No description provided for @loginCardKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep this card safe. Do not show it to other people.'**
  String get loginCardKeep;

  /// No description provided for @copyLogin.
  ///
  /// In en, this message translates to:
  /// **'Copy the login'**
  String get copyLogin;

  /// No description provided for @loginCardHint.
  ///
  /// In en, this message translates to:
  /// **'Show it to the parent or let them take a photo of it.'**
  String get loginCardHint;

  /// No description provided for @familySectionHeader.
  ///
  /// In en, this message translates to:
  /// **'My family'**
  String get familySectionHeader;

  /// No description provided for @levelStarsEarned.
  ///
  /// In en, this message translates to:
  /// **'{count} of 3 stars'**
  String levelStarsEarned(int count);

  /// No description provided for @levelsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String levelsDone(int done, int total);

  /// No description provided for @privacyNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get privacyNoticeTitle;

  /// No description provided for @privacyNoticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How E-Tarabay looks after your child\'s information.'**
  String get privacyNoticeSubtitle;

  /// No description provided for @pnCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'What we keep'**
  String get pnCollectTitle;

  /// No description provided for @pnCollectBody.
  ///
  /// In en, this message translates to:
  /// **'Your child\'s name, birthday, Student Number, gender and picture, their progress and drawings, and a parent\'s name and contact number.'**
  String get pnCollectBody;

  /// No description provided for @pnWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get pnWhyTitle;

  /// No description provided for @pnWhyBody.
  ///
  /// In en, this message translates to:
  /// **'Only for your child\'s learning: to save their progress and show it to you and to their teacher. It is never sold or used for ads.'**
  String get pnWhyBody;

  /// No description provided for @pnWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get pnWhoTitle;

  /// No description provided for @pnWhoBody.
  ///
  /// In en, this message translates to:
  /// **'Your child\'s teacher, who has promised to keep it private, and you on this phone with your code.'**
  String get pnWhoBody;

  /// No description provided for @pnKeepTitle.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get pnKeepTitle;

  /// No description provided for @pnKeepBody.
  ///
  /// In en, this message translates to:
  /// **'Until the teacher removes your child from the class. Then the record and the drawings are deleted.'**
  String get pnKeepBody;

  /// No description provided for @pnRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get pnRightsTitle;

  /// No description provided for @pnRightsBody.
  ///
  /// In en, this message translates to:
  /// **'You may ask the teacher or the school to show, correct or delete your child\'s information (Data Privacy Act of 2012, RA 10173).'**
  String get pnRightsBody;

  /// No description provided for @pnProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'If something is wrong'**
  String get pnProblemTitle;

  /// No description provided for @pnProblemBody.
  ///
  /// In en, this message translates to:
  /// **'If the phone is lost or someone else has seen your child\'s information, tell the teacher or the school at once.'**
  String get pnProblemBody;

  /// No description provided for @pnAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get pnAcknowledge;

  /// No description provided for @parentPinBubbleEnter.
  ///
  /// In en, this message translates to:
  /// **'Code first, Parent!'**
  String get parentPinBubbleEnter;

  /// No description provided for @parentPinBubbleSet.
  ///
  /// In en, this message translates to:
  /// **'Let\'s make a code!'**
  String get parentPinBubbleSet;

  /// No description provided for @parentPinBubbleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Once more!'**
  String get parentPinBubbleConfirm;

  /// No description provided for @parentPinBubbleForgot.
  ///
  /// In en, this message translates to:
  /// **'No problem!'**
  String get parentPinBubbleForgot;

  /// No description provided for @parentPinBubbleDone.
  ///
  /// In en, this message translates to:
  /// **'All set, Parent!'**
  String get parentPinBubbleDone;

  /// No description provided for @parentPinEnterSub.
  ///
  /// In en, this message translates to:
  /// **'To see {name}\'s report.'**
  String parentPinEnterSub(String name);

  /// No description provided for @parentPinEnterSubPlain.
  ///
  /// In en, this message translates to:
  /// **'To see your child\'s report.'**
  String get parentPinEnterSubPlain;

  /// No description provided for @parentPinConfirmSub.
  ///
  /// In en, this message translates to:
  /// **'To be sure, type the code you just made again.'**
  String get parentPinConfirmSub;

  /// No description provided for @parentPinForgotSub.
  ///
  /// In en, this message translates to:
  /// **'It is on the login card from the teacher. After that, you will make a new code.'**
  String get parentPinForgotSub;

  /// No description provided for @parentPinRemembered.
  ///
  /// In en, this message translates to:
  /// **'I remember the code'**
  String get parentPinRemembered;

  /// No description provided for @parentPinBubbleFirst.
  ///
  /// In en, this message translates to:
  /// **'For parents only!'**
  String get parentPinBubbleFirst;

  /// No description provided for @parentPinFirstSub.
  ///
  /// In en, this message translates to:
  /// **'Type your child\'s Student Number from the login card. Then you will make a code.'**
  String get parentPinFirstSub;

  /// No description provided for @parentPinBubbleLogout.
  ///
  /// In en, this message translates to:
  /// **'Code first, before leaving!'**
  String get parentPinBubbleLogout;

  /// No description provided for @parentPinLogoutSub.
  ///
  /// In en, this message translates to:
  /// **'To log out of {name}\'s account.'**
  String parentPinLogoutSub(String name);

  /// No description provided for @parentPinLogoutSubPlain.
  ///
  /// In en, this message translates to:
  /// **'To log out of this account.'**
  String get parentPinLogoutSubPlain;

  /// No description provided for @kidBubbleLessons.
  ///
  /// In en, this message translates to:
  /// **'Let\'s learn!'**
  String get kidBubbleLessons;

  /// No description provided for @kidBubbleAwards.
  ///
  /// In en, this message translates to:
  /// **'You\'re amazing!'**
  String get kidBubbleAwards;

  /// No description provided for @kidBubbleSettings.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set things up!'**
  String get kidBubbleSettings;

  /// No description provided for @kidBubbleProfile.
  ///
  /// In en, this message translates to:
  /// **'This is you, {name}!'**
  String kidBubbleProfile(String name);

  /// No description provided for @kidBubbleCertLocked.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get kidBubbleCertLocked;

  /// No description provided for @kidBubbleCertEarned.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get kidBubbleCertEarned;

  /// No description provided for @kidSubLessons.
  ///
  /// In en, this message translates to:
  /// **'Stars: {stars} of 5'**
  String kidSubLessons(int stars);

  /// No description provided for @kidSubAwards.
  ///
  /// In en, this message translates to:
  /// **'Collected: {count}'**
  String kidSubAwards(int count);

  /// No description provided for @kidSubCert.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total}'**
  String kidSubCert(int earned, int total);

  /// No description provided for @kidBubbleProfilePlain.
  ///
  /// In en, this message translates to:
  /// **'This is you!'**
  String get kidBubbleProfilePlain;

  /// No description provided for @kidSubSettings.
  ///
  /// In en, this message translates to:
  /// **'Language and sounds'**
  String get kidSubSettings;

  /// No description provided for @lessonStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get lessonStart;

  /// No description provided for @lessonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get lessonContinue;

  /// No description provided for @lessonDone.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get lessonDone;

  /// No description provided for @lessonLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lessonLocked;

  /// No description provided for @badgeSpecialShelf.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get badgeSpecialShelf;

  /// No description provided for @claimShort.
  ///
  /// In en, this message translates to:
  /// **'Claim!'**
  String get claimShort;

  /// No description provided for @lessonActivities.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} activities'**
  String lessonActivities(int done, int total);

  /// No description provided for @lessonLevels.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} levels'**
  String lessonLevels(int done, int total);

  /// Small label over each About Me lesson card
  ///
  /// In en, this message translates to:
  /// **'Lesson {n}'**
  String lessonNumber(int n);

  /// Heading over the About Me lessons
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get aboutMeShort;

  /// Trace It: letters finished in this set
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} letters'**
  String tallyLetters(int done, int total);

  /// Trace It: numbers finished in this set
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} numbers'**
  String tallyNumbers(int done, int total);

  /// Trace It: heading over the wall of letters
  ///
  /// In en, this message translates to:
  /// **'Pick a letter'**
  String get pickLetter;

  /// Trace It: heading over the wall of numbers
  ///
  /// In en, this message translates to:
  /// **'Pick a number'**
  String get pickNumber;

  /// Trace It: hint under the wall of letters
  ///
  /// In en, this message translates to:
  /// **'The shining one is the next to write!'**
  String get traceNextHint;

  /// Trace It: shown when a letter not reached yet is tapped
  ///
  /// In en, this message translates to:
  /// **'Write {letter} first.'**
  String traceLockedHint(String letter);

  /// Color Fun: the big button under the crayons that finishes a picture
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get finishColoring;

  /// Color Fun: title of the card shown when a picture is finished
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get coloringGreatJob;

  /// Color Fun: the button that opens the next picture not colored yet
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextPicture;

  /// Color Fun: closes the finished card and goes back to the same picture
  ///
  /// In en, this message translates to:
  /// **'Color more'**
  String get colorMore;

  /// Color Fun: shown instead of Next when every picture is finished
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get allPicturesDone;

  /// Color Fun: warning in the Clear question when the picture is saved
  ///
  /// In en, this message translates to:
  /// **'It leaves {place} too'**
  String clearAlsoRemoves(String place);

  /// Color Fun: note after clearing a saved picture, with Undo beside it
  ///
  /// In en, this message translates to:
  /// **'Removed from {place}'**
  String removedFrom(String place);

  /// Color Fun: note after clearing a picture, with Undo beside it
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get cleared;

  /// Certificate pop-up title, the moment the child earns it
  ///
  /// In en, this message translates to:
  /// **'Congratulations,\n{name}!'**
  String certEarnedTitle(String name);

  /// No description provided for @certEarnedBody.
  ///
  /// In en, this message translates to:
  /// **'You earned your\nCertificate of Completion!'**
  String get certEarnedBody;

  /// No description provided for @certEarnedView.
  ///
  /// In en, this message translates to:
  /// **'See my Certificate'**
  String get certEarnedView;

  /// Numbers, Match with Line: after "2 / 3", how many pairs are matched
  ///
  /// In en, this message translates to:
  /// **'matched'**
  String get lineMatched;

  /// Shown in place of the child's name when the profile has none
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentFallback;

  /// A removal or reset was not sent because the phone is offline
  ///
  /// In en, this message translates to:
  /// **'No internet. Nothing was changed — try again once you are online.'**
  String get authNeedsInternet;

  /// A removal or reset was sent but the server has not confirmed it yet
  ///
  /// In en, this message translates to:
  /// **'The connection dropped. It will finish on its own once the internet is back.'**
  String get authFinishesOnline;

  /// Removing one child failed
  ///
  /// In en, this message translates to:
  /// **'Could not remove the child. Please try again.'**
  String get authRemoveFailed;

  /// Shown after the teacher removes a child
  ///
  /// In en, this message translates to:
  /// **'Child removed.'**
  String get studentRemoved;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Try this:'**
  String get loginProblemTryThis;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get loginProblemRetry;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get loginProblemOk;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String loginProblemCode(String code);

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect'**
  String get loginProblemConnectionTitle;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'The phone can\'t reach E-Tarabay right now. It is not because of what you typed.'**
  String get loginProblemConnectionBody;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Check that the phone has WiFi or mobile data.'**
  String get loginProblemConnectionStep1;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'In the phone\'s Settings, set the date and time to \"Automatic\".'**
  String get loginProblemConnectionStep2;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Try a different WiFi, or mobile data.'**
  String get loginProblemConnectionStep3;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Update \"Google Play services\" in the Play Store.'**
  String get loginProblemConnectionStep4;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Username not found'**
  String get loginProblemUsernameTitle;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'No child has this username. The username is not the child\'s name.'**
  String get loginProblemUsernameBody;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Copy the Username on the login card from the teacher, e.g. ana1234.'**
  String get loginProblemUsernameStep1;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'No login card yet? Ask the teacher for one. The teacher makes the account.'**
  String get loginProblemUsernameStep2;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Wrong Student Number'**
  String get loginProblemNumberTitle;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'The username is right, but the Student Number doesn\'t match.'**
  String get loginProblemNumberBody;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'It is the Password on the login card, e.g. DC-2026-0001, dashes (-) included.'**
  String get loginProblemNumberStep1;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'If a parent changed the password, use the new one.'**
  String get loginProblemNumberStep2;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Forgot it? Ask the teacher.'**
  String get loginProblemNumberStep3;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'This is the child\'s login'**
  String get loginProblemTeacherHereTitle;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'\"Daycare Teacher\" is the teacher\'s. Each child has their own username, on their login card.'**
  String get loginProblemTeacherHereBody;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Tap \"{button}\" at the bottom of the screen.'**
  String loginProblemTeacherHereStep1(String button);

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Something is missing'**
  String get loginProblemEmptyTitle;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Both are needed: the Username and the Student Number.'**
  String get loginProblemEmptyBody;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Both are on the login card from the teacher. Type them in, then tap \"{button}\".'**
  String loginProblemEmptyStep1(String button);

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get loginProblemTeacherWrongTitle;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'The teacher\'s username or password doesn\'t match.'**
  String get loginProblemTeacherWrongBody;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Mind the capital and small letters.'**
  String get loginProblemTeacherWrongStep1;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Tap the eye to see what you typed.'**
  String get loginProblemTeacherWrongStep2;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Needs the internet'**
  String get loginProblemNeedsInternetTitle;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'The first login on this phone has to be online.'**
  String get loginProblemNeedsInternetBody;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Connect to WiFi or mobile data, then try again.'**
  String get loginProblemNeedsInternetStep1;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'The password changed'**
  String get loginProblemPasswordChangedTitle;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'The teacher password was changed on another phone.'**
  String get loginProblemPasswordChangedBody;

  /// Login problem sheet
  ///
  /// In en, this message translates to:
  /// **'Log in with the new password. The fingerprint can be set up again after.'**
  String get loginProblemPasswordChangedStep1;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'e.g. ana1234'**
  String get loginUsernameHint;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'e.g. DC-2026-0001'**
  String get loginNumberHint;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'New here? How to log in'**
  String get loginHelpLink;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'How to log in'**
  String get loginProblemHowToTitle;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'The teacher makes each child\'s account. There is nothing to sign up for here.'**
  String get loginProblemHowToBody;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'Ask the teacher for the child\'s login card.'**
  String get loginProblemHowToStep1;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'Type what is on the card into the two boxes, as shown above.'**
  String get loginProblemHowToStep2;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'Tap \"{button}\".'**
  String loginProblemHowToStep3(String button);

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'first box'**
  String get loginHowToFirstBox;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'second box'**
  String get loginHowToSecondBox;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'No login card yet? Ask the teacher for one. The teacher makes the account.'**
  String get loginProblemEmptyStep2;

  /// Login help
  ///
  /// In en, this message translates to:
  /// **'Here\'s how:'**
  String get loginProblemSteps;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'{size} · Best on WiFi.'**
  String updateSizeNote(String size);

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Downloading the update'**
  String get updateDownloadingTitle;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Keep the app open for now.'**
  String get updateDownloadingBody;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'{percent}% · {done} of {total}'**
  String updateProgress(String percent, String done, String total);

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get updateCancel;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'One more step'**
  String get updatePermissionTitle;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Allow E-Tarabay to install its update. On the next screen, turn on \"Allow from this source\", then come back here.'**
  String get updatePermissionBody;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get updateOpenSettings;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get updateReadyTitle;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Tap \"Update\" on the next screen.'**
  String get updateReadyBody;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get updateInstallAgain;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'The download did not finish'**
  String get updateFailedTitle;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Check the internet, then try again.'**
  String get updateFailedBody;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get updateRetry;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Open the website'**
  String get updateWebsite;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get updateClose;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Getting the update ready'**
  String get updatePreparingTitle;

  /// In-app update
  ///
  /// In en, this message translates to:
  /// **'Just a moment. Keep the app open.'**
  String get updatePreparingBody;

  /// Shown as a medal is claimed
  ///
  /// In en, this message translates to:
  /// **'You got it!'**
  String get claimYouGotIt;

  /// Awards strip when nothing is waiting
  ///
  /// In en, this message translates to:
  /// **'Keep playing for the next medal!'**
  String get awardsKeepPlaying;

  /// Awards strip when nothing is waiting
  ///
  /// In en, this message translates to:
  /// **'Well done! You have every medal!'**
  String get awardsAllClaimed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil', 'ilo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
    case 'ilo':
      return AppLocalizationsIlo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
