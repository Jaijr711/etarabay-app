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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @totalProgress.
  ///
  /// In en, this message translates to:
  /// **'Total Progress'**
  String get totalProgress;

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

  /// No description provided for @timesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up!'**
  String get timesUp;

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
  /// **'Choose a number on the left first!'**
  String get chooseLeftFirst;

  /// No description provided for @dropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop here!'**
  String get dropHere;

  /// No description provided for @dragHere.
  ///
  /// In en, this message translates to:
  /// **'Drag here'**
  String get dragHere;

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
  /// **'Which side have more, left or right?'**
  String get whichIsMore;

  /// No description provided for @whichIsLess.
  ///
  /// In en, this message translates to:
  /// **'Which side have lesser, left or right?'**
  String get whichIsLess;

  /// No description provided for @isSameNumber.
  ///
  /// In en, this message translates to:
  /// **'Same number?'**
  String get isSameNumber;

  /// No description provided for @arrange.
  ///
  /// In en, this message translates to:
  /// **'Arrange the numbers in the correct order/Sequence: {sequence}'**
  String arrange(String sequence);

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
  /// **'Ang Aking Sarili'**
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

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @timeAgo.
  ///
  /// In en, this message translates to:
  /// **'{amount}m ago'**
  String timeAgo(int amount);

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

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @upper.
  ///
  /// In en, this message translates to:
  /// **'Upper'**
  String get upper;

  /// No description provided for @lower.
  ///
  /// In en, this message translates to:
  /// **'Lower'**
  String get lower;

  /// No description provided for @letterLabel.
  ///
  /// In en, this message translates to:
  /// **'Letter {letter}'**
  String letterLabel(String letter);

  /// No description provided for @numberLabel.
  ///
  /// In en, this message translates to:
  /// **'Number {number}'**
  String numberLabel(String number);

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsLabel;

  /// No description provided for @goodJob.
  ///
  /// In en, this message translates to:
  /// **'Good Job! 🌟'**
  String get goodJob;

  /// No description provided for @ulitin.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get ulitin;

  /// No description provided for @traceTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow Me, You Can Do It!'**
  String get traceTitle;

  /// No description provided for @uppercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase'**
  String get uppercase;

  /// No description provided for @lowercase.
  ///
  /// In en, this message translates to:
  /// **'Lowercase'**
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

  /// No description provided for @swipeToDeleteGuide.
  ///
  /// In en, this message translates to:
  /// **'Swipe left on a student to delete'**
  String get swipeToDeleteGuide;

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

  /// No description provided for @studentProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Progress'**
  String studentProgressTitle(String name);

  /// No description provided for @moduleBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Module Breakdown'**
  String get moduleBreakdown;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String scoreLabel(int score);

  /// No description provided for @loginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue your learning journey'**
  String get loginPrompt;

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

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get hello;

  /// No description provided for @kulaySayaProgress.
  ///
  /// In en, this message translates to:
  /// **'Kulay-Saya Progress'**
  String get kulaySayaProgress;

  /// No description provided for @totalSaved.
  ///
  /// In en, this message translates to:
  /// **'Total Saved'**
  String get totalSaved;

  /// No description provided for @magbasaProgress.
  ///
  /// In en, this message translates to:
  /// **'Magbasa Progress'**
  String get magbasaProgress;

  /// No description provided for @matematikaProgress.
  ///
  /// In en, this message translates to:
  /// **'Matematika Progress'**
  String get matematikaProgress;

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

  /// No description provided for @eraseColoringWarning.
  ///
  /// In en, this message translates to:
  /// **'This will erase all your coloring.'**
  String get eraseColoringWarning;

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

  /// No description provided for @readingFinishedHappy.
  ///
  /// In en, this message translates to:
  /// **'✓ Finished! Happy reading!'**
  String get readingFinishedHappy;

  /// No description provided for @doneAlready.
  ///
  /// In en, this message translates to:
  /// **'Done already!'**
  String get doneAlready;

  /// No description provided for @checkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkAnswer;

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

  /// No description provided for @whatIsMissingNumber.
  ///
  /// In en, this message translates to:
  /// **'What number is missing?'**
  String get whatIsMissingNumber;

  /// No description provided for @straightOrCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get straightOrCorrect;

  /// No description provided for @iKnowIt.
  ///
  /// In en, this message translates to:
  /// **'I learned it!'**
  String get iKnowIt;

  /// No description provided for @familyTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTreeTitle;

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

  /// No description provided for @ourHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Home'**
  String get ourHomeTitle;

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

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

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

  /// No description provided for @overviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// No description provided for @magbasaTab.
  ///
  /// In en, this message translates to:
  /// **'Magbasa'**
  String get magbasaTab;

  /// No description provided for @matematikaTab.
  ///
  /// In en, this message translates to:
  /// **'Matematika'**
  String get matematikaTab;

  /// No description provided for @artworksLabel.
  ///
  /// In en, this message translates to:
  /// **'Artworks'**
  String get artworksLabel;

  /// No description provided for @pagesLabel.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get pagesLabel;

  /// No description provided for @lettersLabel.
  ///
  /// In en, this message translates to:
  /// **'letters'**
  String get lettersLabel;

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

  /// No description provided for @activitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'activities'**
  String get activitiesLabel;

  /// No description provided for @gamesLabel.
  ///
  /// In en, this message translates to:
  /// **'games'**
  String get gamesLabel;

  /// No description provided for @savedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get savedCountLabel;

  /// No description provided for @uppercaseLettersTitle.
  ///
  /// In en, this message translates to:
  /// **'Uppercase Letters (A–Z)'**
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
  /// **'Flower Basket'**
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

  /// No description provided for @pageSodaPop.
  ///
  /// In en, this message translates to:
  /// **'Soda'**
  String get pageSodaPop;

  /// No description provided for @favoriteChosen.
  ///
  /// In en, this message translates to:
  /// **'Your Favorite is {choice}!'**
  String favoriteChosen(String choice);

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloName(String name);

  /// No description provided for @letsLearnAndPlay.
  ///
  /// In en, this message translates to:
  /// **'Let\'s learn and play!'**
  String get letsLearnAndPlay;

  /// No description provided for @myProgressToday.
  ///
  /// In en, this message translates to:
  /// **'My Progress Today'**
  String get myProgressToday;

  /// No description provided for @whatDoYouWantToLearn.
  ///
  /// In en, this message translates to:
  /// **'What do you want to learn?'**
  String get whatDoYouWantToLearn;

  /// No description provided for @rewardsCount.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get rewardsCount;

  /// No description provided for @activitiesCount.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesCount;

  /// No description provided for @lessonsCount.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessonsCount;

  /// No description provided for @familyRoleSentence.
  ///
  /// In en, this message translates to:
  /// **'{member} is {roles}.'**
  String familyRoleSentence(String member, String roles);

  /// No description provided for @resetAllStudents.
  ///
  /// In en, this message translates to:
  /// **'Reset All Students'**
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

  /// No description provided for @iReadThePoem.
  ///
  /// In en, this message translates to:
  /// **'I Read the Poem! ✓'**
  String get iReadThePoem;

  /// No description provided for @readFullStoryBeforeBack.
  ///
  /// In en, this message translates to:
  /// **'Read the entire story before going back.'**
  String get readFullStoryBeforeBack;

  /// No description provided for @iReadTheStory.
  ///
  /// In en, this message translates to:
  /// **'I Have Read It! ✓'**
  String get iReadTheStory;

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

  /// No description provided for @checkTracing.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkTracing;

  /// No description provided for @startAtDot.
  ///
  /// In en, this message translates to:
  /// **'Start at the dot!'**
  String get startAtDot;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Try again!'**
  String get almostThere;

  /// No description provided for @progressPages.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} pages'**
  String progressPages(int done, int total);

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String percentComplete(int percent);

  /// No description provided for @obraLabel.
  ///
  /// In en, this message translates to:
  /// **'Artworks'**
  String get obraLabel;

  /// No description provided for @strokesLabel.
  ///
  /// In en, this message translates to:
  /// **'Strokes'**
  String get strokesLabel;

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
  /// **'Kulay-Saya'**
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
  /// **'Magbasa'**
  String get tipMagbasaTitle;

  /// No description provided for @tipMagbasaBody.
  ///
  /// In en, this message translates to:
  /// **'Read the poem stories and songs aloud together with your child. Encourage your child to read along.'**
  String get tipMagbasaBody;

  /// No description provided for @tipMatematikaTitle.
  ///
  /// In en, this message translates to:
  /// **'Matematika'**
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

  /// No description provided for @progressCompleted.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} completed'**
  String progressCompleted(int done, int total);

  /// No description provided for @progressActivities.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} activities'**
  String progressActivities(int done, int total);

  /// No description provided for @progressGames.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} games'**
  String progressGames(int done, int total);

  /// No description provided for @pointsStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsStatLabel;

  /// No description provided for @starsStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get starsStatLabel;

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
  /// **'Collect all 9 stars in Kulay-Saya'**
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

  /// Button that opens an already-saved drawing
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewArtwork;

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

  /// Heading for the class-wide module breakdown
  ///
  /// In en, this message translates to:
  /// **'The class'**
  String get theClass;

  /// Note under the class breakdown explaining the order
  ///
  /// In en, this message translates to:
  /// **'Weakest module first'**
  String get weakestFirst;

  /// Heading for the class-wide feed of recently earned badges and certificates
  ///
  /// In en, this message translates to:
  /// **'Recent Achievements'**
  String get recentAchievements;

  /// One row of the recent-achievements feed, e.g. "Jay earned Alphabet Star"
  ///
  /// In en, this message translates to:
  /// **'{name} earned {achievement}'**
  String achievementEarnedBy(String name, String achievement);

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

  /// Shown when no child is inactive
  ///
  /// In en, this message translates to:
  /// **'Everyone has played this week'**
  String get everyoneActive;

  /// How long since a child last played, e.g. 12d ago
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// How long since something happened, in hours, e.g. 3h ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

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

  /// Confirmation that a new code was stored
  ///
  /// In en, this message translates to:
  /// **'Code saved'**
  String get pinSaved;

  /// Divider between two ways of signing in
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

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
  /// **'No fingerprint or face is set up on this phone,'**
  String get noBiometricOnDevice;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'No student session found. Please log in first.'**
  String get noSessionLogInFirst;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Reset Activity'**
  String get resetActivity;

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

  /// Header over a child’s saved drawings
  ///
  /// In en, this message translates to:
  /// **'Artworks ({count})'**
  String studentArtworks(int count);

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
  /// **'Student Number (Format: DC-2026-0001)'**
  String get studentIdFormat;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Make an ID for me'**
  String get autoGenerateId;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Account Preview'**
  String get accountPreview;

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

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Celebrate'**
  String get celebrate;

  /// Progress through the enrolment wizard
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total} · {label}'**
  String stepOf(int current, int total, String label);

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Made for you'**
  String get autoGenerated;

  /// Adult screen wording
  ///
  /// In en, this message translates to:
  /// **'Enter the ID above'**
  String get enterIdAbove;

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
  /// **'Daycare Teacher'**
  String get daycareTeacher;

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

  /// Parents summary wording
  ///
  /// In en, this message translates to:
  /// **'Going best'**
  String get strongest;

  /// Parents summary wording
  ///
  /// In en, this message translates to:
  /// **'All six modules'**
  String get modulesHeader;

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

  /// Parent account wording
  ///
  /// In en, this message translates to:
  /// **'That username is taken. Please pick another.'**
  String get usernameTaken;

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

  /// Collapsed class card: how many modules are hidden
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreModules(int count);

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

  /// Parent's field for the child's new password
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

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

  /// Second box when a parent changes the password
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// First box when a parent is creating their code
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get newParentPin;

  /// Sign-in screen greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcome;

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

  /// No description provided for @scoreWord.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreWord;

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
  /// **'Version {version} is ready to download.'**
  String updateAvailableBody(String version);

  /// No description provided for @updateDownloadNow.
  ///
  /// In en, this message translates to:
  /// **'Download Now'**
  String get updateDownloadNow;

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
