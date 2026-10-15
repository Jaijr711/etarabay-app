// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get back => 'Ibalik';

  @override
  String get done => 'Tapos';

  @override
  String get save => 'I-save';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get next => 'Susunod';

  @override
  String levelCompleted(int level) {
    return 'Tapos na ang Antas $level!';
  }

  @override
  String get proudOfYou => 'Ipinagmamalaki kita!';

  @override
  String categoryCompleted(String cat) {
    return 'Natapos mo ang lahat ng antas sa $cat!';
  }

  @override
  String get finished => 'Tapos na';

  @override
  String get completed => 'Tapos na';

  @override
  String get earned => 'natamo';

  @override
  String get levels => 'Mga Antas';

  @override
  String get activities => 'Mga Gawain';

  @override
  String get parents => 'MAGULANG';

  @override
  String get lessons => 'Mga Aralin';

  @override
  String get stars => 'Puntos';

  @override
  String get awards => 'Gantimpala';

  @override
  String homeAge(int age) {
    return '$age Taon';
  }

  @override
  String get matematika => 'Bilang';

  @override
  String get angAkingSarili => 'Tungkol sa aking Sarili';

  @override
  String get atAkingPamilya => 'At ang Aking Pamilya';

  @override
  String get kulaySaya => 'Masayang Pagkukulay';

  @override
  String get magkulayTayo => 'Magkulay Tayo';

  @override
  String get magbasaTitle => 'Mga Kuwento at Awitin';

  @override
  String get alpabetoAtMgaSalita => 'Magbasa at Umawit!';

  @override
  String get home => 'Pangunahing Pahina';

  @override
  String get settingsTitle => 'Pag-aayos';

  @override
  String get totalProgress => 'Kabuuang Pag-unlad';

  @override
  String get poems => 'Mga Tula';

  @override
  String get stories => 'Mga Kuwento';

  @override
  String get songs => 'Mga Awit';

  @override
  String get tune => 'Tono';

  @override
  String get action => 'Aksyon';

  @override
  String get counting => 'Bilangin ang mga Bagay';

  @override
  String get dragNumber => 'Itapat ang tamang bilang';

  @override
  String get lineMatch => 'Itugma gamit ang Linya';

  @override
  String get popBalloon => 'Putukin ang lobo';

  @override
  String get moreOrLess => 'Higit o Kulang';

  @override
  String get numberPuzzle => 'Palaisipan sa Bilang';

  @override
  String get numberSequence => 'Pagkakasunod-sunod ng mga bilang';

  @override
  String get check => 'Suriin';

  @override
  String get correct => 'Tama!';

  @override
  String get wrong => 'Mali! Subukan muli!';

  @override
  String get wrongShort => 'Mali';

  @override
  String get replayReplacesStar =>
      'Ang muling paglalaro ang pumapalit sa bituing ito.';

  @override
  String get putNumbersInOrder => 'Itugma ang mga numero sa tamang kahon';

  @override
  String get timesUp => 'Tapos na ang oras!';

  @override
  String level(int level) {
    return 'Antas $level';
  }

  @override
  String streak(int streak) {
    return '$streak araw na streak!';
  }

  @override
  String get repeat => 'Ulitin';

  @override
  String get congratulations => 'Binabati kita!';

  @override
  String get chooseFirst => 'Pumili muna ng sagot!';

  @override
  String get chooseLeftFirst => 'Pumili muna ng bilang sa kaliwa!';

  @override
  String get dropHere => 'Ilagay dito!';

  @override
  String get dragHere => 'Itapat dito';

  @override
  String get popAllBalloonsWith => 'Putukin ang lahat ng lobo na may bilang na';

  @override
  String get left => 'Kaliwa';

  @override
  String get right => 'Kanan';

  @override
  String get selected => 'Napili';

  @override
  String howMany(String item) {
    return 'Ilan ang $item?';
  }

  @override
  String matchWithNumber(String category) {
    return 'Itugma ang $category sa tamang bilang nito.';
  }

  @override
  String get whichIsMore => 'Alin ang mas marami, kaliwa o kanan?';

  @override
  String get whichIsLess => 'Alin ang mas kaunti?';

  @override
  String get isSameNumber => 'Magkakaparehong bilang?';

  @override
  String arrange(String sequence) {
    return 'Iayos: $sequence';
  }

  @override
  String get selectCorrectAnswer => 'Piliin ang tamang sagot:';

  @override
  String get tapLeftTapRight =>
      'Pindutin ang mga grupo (kaliwa) → Pindutin ang bilang (kanan)';

  @override
  String get angAkingSariliTitle => 'Ang Aking Sarili';

  @override
  String get allAboutMe => 'Tungkol sa Akin';

  @override
  String get myEmotions => 'Ang Aking Damdamin';

  @override
  String get dailyRoutines => 'Pang-araw-araw na gawain';

  @override
  String get myPreferences => 'Aking Kagustuhan';

  @override
  String get familyMembers => 'Kasapi ng Pamilya';

  @override
  String get familyRoles => 'Tungkulin ng bawat kasapi ng Pamilya';

  @override
  String get familyActivities => 'Gawain ng Pamilya';

  @override
  String get familyTree => 'Talaan ng Pamilya';

  @override
  String get myHome => 'Ang Aking Tahanan';

  @override
  String get whatIsYourName => 'Ano ang pangalan  mo?';

  @override
  String get howOldAreYou => 'Ilang taon ka na?';

  @override
  String get areYouBoyOrGirl => 'Ikaw ba ay lalaki o babae?';

  @override
  String get whatIsYourNameDescription =>
      'Ang iyong pangalan ay ang tawag sa iyo ng iyong pamilya at kaibigan. Mahalaga ito dahil bahagi ito ng kung sino ka!';

  @override
  String get howOldAreYouDescription =>
      'Sinasabi ng edad mo kung ilang taon na ang lumipas mula nang ipinanganak ka.';

  @override
  String get genderDescription =>
      'Ang pag-alam kung ikaw ay lalaki o babae ay nakatutulong upang mas makilala ka namin!';

  @override
  String get typeNameHint => 'Ilagay ang iyong pangalan dito';

  @override
  String get ageHint => 'Halimbawa: 5,7,10';

  @override
  String get aboutMeSubtitle => 'Tungkol sa Akin';

  @override
  String get myEmotionsSubtitle => 'Ipaliwanag ang iyong nararamdaman';

  @override
  String get dailyRoutinesSubtitle => 'Matuto ng pang-araw-araw na gawain';

  @override
  String get myPreferencesSubtitle => 'Ano ang aking mga gusto?';

  @override
  String get familyMembersSubtitle => 'Sino ang mga miyembro ng iyong pamilya?';

  @override
  String get familyRolesSubtitle => 'Ano ang trabaho ng bawat isa?';

  @override
  String get familyActivitiesSubtitle =>
      'Ano ang ginagawa niyo nang sama-sama?';

  @override
  String get familyTreeSubtitle => 'Sino-sino ang iyong mga kamag-anak?';

  @override
  String get myHomeSubtitle => 'Saan ka nakatira?';

  @override
  String get colorSomethingFirst => 'Kulayan muna ang isang bagay!';

  @override
  String get justNow => 'Ngayon lang';

  @override
  String timeAgo(int amount) {
    return '${amount}m ang nakalipas';
  }

  @override
  String get saved => 'Nai-save!';

  @override
  String get coloringBook => 'Aklat Pangkulay';

  @override
  String get myCreations => 'Ang Aking mga Likha';

  @override
  String get color => 'Kulay';

  @override
  String get animals => 'Mga Hayop';

  @override
  String get red => 'Pula';

  @override
  String get blue => 'Asul';

  @override
  String get green => 'Berde';

  @override
  String get yellow => 'Dilaw';

  @override
  String get orange => 'Kahel';

  @override
  String get purple => 'Lila';

  @override
  String get pink => 'Rosas';

  @override
  String get brown => 'Kayumanggi';

  @override
  String get black => 'Itim';

  @override
  String get white => 'Puti';

  @override
  String get brush => 'Pinsel';

  @override
  String get eraser => 'Burahin';

  @override
  String get undo => 'Ibalik';

  @override
  String get redo => 'Ulitin';

  @override
  String get clear => 'Tanggalin';

  @override
  String get upper => 'Malaking Titik';

  @override
  String get lower => 'Maliit na Titik';

  @override
  String letterLabel(String letter) {
    return 'Titik $letter';
  }

  @override
  String numberLabel(String number) {
    return 'Numero $number';
  }

  @override
  String get pointsLabel => 'Puntos';

  @override
  String get goodJob => 'Magaling!';

  @override
  String get ulitin => 'Ulitin';

  @override
  String get traceTitle => 'Kaya mo iyan! Sundan ang linya!';

  @override
  String get uppercase => 'Malaking titik';

  @override
  String get lowercase => 'Maliit na titik';

  @override
  String get numbers => 'Bilang';

  @override
  String letter(String letter) {
    return 'Titik $letter';
  }

  @override
  String get reset => 'Ulitin';

  @override
  String get overallProgress => 'Kabuuang Pag-unlad';

  @override
  String get tula => 'Mga Tula';

  @override
  String get kwento => 'Mga Kwento';

  @override
  String get kanta => 'Mga Awit';

  @override
  String get badges => 'Mga Badge';

  @override
  String get myProfile => 'Aking Profile';

  @override
  String yearsOld(int age) {
    return '$age taong gulang';
  }

  @override
  String get male => 'Lalaki';

  @override
  String get female => 'Babae';

  @override
  String get birthday => 'Kaarawan';

  @override
  String get profileAge => 'Edad';

  @override
  String get gender => 'Kasarian';

  @override
  String get memberSince => 'Kasapi Mula Noong';

  @override
  String get editProfile => 'Baguhin ang Iyong Profile';

  @override
  String get noProfileData => 'Walang datos ng profile';

  @override
  String get settings => 'Pag-aayos';

  @override
  String get language => 'Wika';

  @override
  String get audio => 'Tunog at Musika';

  @override
  String get about => 'Tungkol Dito';

  @override
  String get sound => 'Tunog';

  @override
  String get music => 'Musika';

  @override
  String get notifications => 'Mga Notipikasyon';

  @override
  String get achievements => 'Mga Natamo';

  @override
  String get teacherDashboard => 'Talaan ng Guro';

  @override
  String get newCertificateBadge => 'Bagong Certificate!';

  @override
  String get enrollStudent => 'Magpatala ng Mag-aaral';

  @override
  String get firstName => 'Unang Pangalan';

  @override
  String get lastName => 'Apelyido';

  @override
  String get lRN => 'Numero ng mag-aaral';

  @override
  String get removeStudent => 'Tanggalin ang Mag-aaral?';

  @override
  String get logoutConfirm =>
      'Gusto mo bang lumabas sa account na ito? Kailangan mo ang Student Number para makapasok ulit.';

  @override
  String get logout => 'Mag-logout';

  @override
  String get confirmLogout => 'Sigurado ka bang gusto mong mag-logout?';

  @override
  String get verifyLRN => 'I-verify ang Student Number';

  @override
  String get enterLRN => 'Ilagay ang Student Number para makapasok';

  @override
  String get invalidLRN => 'Maling Student Number. Subukan muli.';

  @override
  String get password => 'Password';

  @override
  String get fillAllFields => 'Pakisuyong punan ang lahat ng fields.';

  @override
  String get parentNameLabel => 'Pangalan ng Magulang';

  @override
  String get parentContactLabel => 'Numero ng Magulang';

  @override
  String get contactLengthError =>
      'Ang numero ng contact ay dapat eksaktong 11 digits.';

  @override
  String birthdayGreeting(String name) {
    return 'Maligayang Kaarawan, $name!';
  }

  @override
  String get swipeToDeleteGuide =>
      'I-swipe pakaliwa upang alisin ang mag-aaral';

  @override
  String get enroll => 'Itala';

  @override
  String get studentEnrolled => 'Matagumpay na naitala ang mag-aaral';

  @override
  String studentEnrolledSuccessfully(String name) {
    return 'Matagumpay na naitala si $name.';
  }

  @override
  String get loginCredentials => 'Mga Detalye sa Pag-log in:';

  @override
  String get userLabel => 'Gumagamit:';

  @override
  String get usernameCopied => 'Username ay nakopya!';

  @override
  String get passwordLabel => 'Password:';

  @override
  String get passwordCopied => 'Password ay nakopya!';

  @override
  String get fullName => 'Buong Pangalan';

  @override
  String get lRNPassword => 'Numero ng mag-aaral';

  @override
  String get confirmRemoveStudent =>
      'Sigurado ka bang gusto mong tanggalin ang mag-aaral na ito? Hindi na ito mababawi.';

  @override
  String get remove => 'Alisin';

  @override
  String get update => 'I-update';

  @override
  String get copied => 'Nakopya!';

  @override
  String get noStudentsEnrolled => 'Wala pang nai-enroll na mag-aaral.';

  @override
  String get tapToEnroll =>
      'I-tap ang \"Magpatala ng Mag-aaral\" para magdagdag.';

  @override
  String studentProgressTitle(String name) {
    return 'Progress ni $name';
  }

  @override
  String get moduleBreakdown => 'Nilalaman ng Modyul';

  @override
  String scoreLabel(int score) {
    return 'Marka: $score';
  }

  @override
  String get loginPrompt => 'Mag-log in upang ipagpatuloy ang iyong pag-aaral.';

  @override
  String get loginButton => 'Mag-log in';

  @override
  String get teacherLoginButton => 'Ipagpatuloy bilang Guro';

  @override
  String get enterUsernamePassword =>
      'Pakilagay ang parehong pangalan ng gumagamit at password';

  @override
  String get loginError => 'Hindi matagumpay ang pag-log in. Subukan muli.';

  @override
  String get studentNumberField => 'Student Number';

  @override
  String certificateProgress(
      int badges, int badgeTotal, int modules, int moduleTotal) {
    return 'Gantimpala $badges/$badgeTotal · Aralin $modules/$moduleTotal';
  }

  @override
  String get username => 'Pangalan ng gumagamit';

  @override
  String get teacherLoginTitle => 'Pagpasok ng Guro';

  @override
  String get teacherLoginButtonLabel => 'Mag-login bilang Guro';

  @override
  String get invalidTeacherCredentials =>
      'Maling teacher credentials. Pakisubukang muli.';

  @override
  String monthName(int month) {
    return 'Buwan $month';
  }

  @override
  String get notSet => 'Wala pang itinakda';

  @override
  String get saveChanges => 'I-save ang mga pagbabago';

  @override
  String get enterName => 'Ilagay ang iyong pangalan';

  @override
  String get chooseLanguage => 'Pumili ng Wika';

  @override
  String get getStarted => 'Magsimula';

  @override
  String get nextLevelLearningTitle => 'Mas Mataas na Antas ng Pagkatuto';

  @override
  String get nextLevelLearningDesc =>
      'Masaya at interaktibong mga laro para sa pagkatuto at pag-unlad ng mga bata.';

  @override
  String get learnAnywhereTitle => 'Matuto kahit saan';

  @override
  String get learnAnywhereDesc =>
      'Gamitin ang mga aralin kahit walang internet at magpatuloy sa pag-aaral kahit saan.';

  @override
  String get trackProgressTitle => 'Subaybayan ang Pag-unlad';

  @override
  String get trackProgressDesc =>
      'Tingnan ang pag-unlad ng iyong anak sa pamamagitan ng pagsubaybay sa kaniyang pagkatuto.';

  @override
  String get continueText => 'Magpatuloy';

  @override
  String get forParents => 'Para sa mga Magulang';

  @override
  String get hello => 'Kumusta!';

  @override
  String get kulaySayaProgress => 'Kulay-Saya Progress';

  @override
  String get totalSaved => 'Kabuuang Nai-save';

  @override
  String get magbasaProgress => 'Magbasa Progress';

  @override
  String get matematikaProgress => 'Matematika Progress';

  @override
  String get noResults => 'Walang resulta';

  @override
  String get imageNotFound => 'Hindi makita ang larawan';

  @override
  String get clearCanvasQuestion => 'Tanggalin ang kinulayan?';

  @override
  String get eraseColoringWarning =>
      'Buburahin nito ang lahat ng iyong kinulayan.';

  @override
  String get noArtworksYet => 'Wala pang likhang-sining';

  @override
  String get colorPagePrompt =>
      'Kulayan ang isang pahina at i-save ang iyong likhang-sining!';

  @override
  String get startColoring => 'Simulan ang Pagkukulay';

  @override
  String get edit => 'Baguhin';

  @override
  String get lessonFinishedPrompt =>
      'Natapos mo na ang araling ito! Mahusay! Pumili ng isa pang laro.';

  @override
  String get okButton => 'Sige';

  @override
  String get readingFinishedGood => 'Tapos na! Magaling kang magbasa!';

  @override
  String get readingFinishedHappy => 'Tapos na! Maligayang pagbabasa!';

  @override
  String get doneAlready => 'Tapos na!';

  @override
  String get checkAnswer => 'Suriin';

  @override
  String get noGamesAvailable2 => 'Walang larong magagamit.';

  @override
  String get countAndDragCorrectNumber =>
      'Bilangin at itapat ang tamang numero!';

  @override
  String countThenDragToBasket(String items) {
    return 'Bilangin ang mga $items at itapat sa basket';
  }

  @override
  String get whatIsMissingNumber => 'Ano ang nawawalang bilang?';

  @override
  String get straightOrCorrect => 'Tama!';

  @override
  String get iKnowIt => 'Natutuhan ko na';

  @override
  String get familyTreeTitle => 'Talaan ng Pamilya';

  @override
  String get familyTreeTapHint =>
      'Pindutin ang bawat kasapi upang malaman ang kanilang relasyon!';

  @override
  String get iLearnedFamilyTree => 'Natutunan ko ang Talaan ng Pamilya!';

  @override
  String get ourHomeTitle => 'Ang Ating Tahanan';

  @override
  String get thatIsOurHome => 'Iyan ang ating tahanan!';

  @override
  String get forParentsSubtitle =>
      'Narito ang progreso ng inyong anak sa E-Tarabay.';

  @override
  String get artworks => 'mga likha';

  @override
  String get error => 'Error';

  @override
  String get recentActivity => 'Kamakailang Gawain';

  @override
  String get recentColor => 'Kamakailang Kulay';

  @override
  String get unknownStudent => 'Hindi Kilalang Mag-aaral';

  @override
  String get version => 'Bersyon';

  @override
  String get backgroundMusicPlaying => 'May musikang tumutugtog';

  @override
  String get errorSaveLocal => 'Hindi na-save ang artwork nang lokal.';

  @override
  String get finishedAlready => 'Nakumpleto';

  @override
  String get accessExpired =>
      'Tapos na ang iyong pag-access sa app na ito. Kumonsulta sa iyong guro para sa susunod na hakbang.';

  @override
  String get accountPaused =>
      'Pansamantalang naka-pause ang access sa app na ito para sa account na ito. Makipag-ugnayan sa suporta para sa karagdagang detalye.';

  @override
  String get forceLoggedOut =>
      'Na-sign out ka ng developer. Maaari ka nang mag-login muli.';

  @override
  String get moduleLocked =>
      'Pansamantalang hindi available ang aktibidad na ito. Bumalik ka na lang mamaya.';

  @override
  String get overviewTab => 'Buod';

  @override
  String get magbasaTab => 'Magbasa';

  @override
  String get matematikaTab => 'Matematika';

  @override
  String get artworksLabel => 'Mga Obra';

  @override
  String get pagesLabel => 'pahina';

  @override
  String get lettersLabel => 'Mga titik';

  @override
  String get diffEasy => 'Madali';

  @override
  String get diffMedium => 'Katamtaman';

  @override
  String get diffHard => 'Mahirap';

  @override
  String get catAnimals => 'Mga Hayop';

  @override
  String get catFlowers => 'Mga Bulaklak';

  @override
  String get catFruits => 'Mga Prutas';

  @override
  String get catToys => 'Mga Laruan';

  @override
  String get poemLabel => 'Tula';

  @override
  String get storyLabel => 'Kwento';

  @override
  String get songLabel => 'Kanta';

  @override
  String get activitiesLabel => 'aktibidad';

  @override
  String get gamesLabel => 'Mga Laro';

  @override
  String get savedCountLabel => 'na-save';

  @override
  String get uppercaseLettersTitle => 'Malalaking Titik (A–Z)';

  @override
  String get lowercaseLettersTitle => 'Maliliit na Titik (a–z)';

  @override
  String get numbersTitle => 'Mga Bilang (1–10)';

  @override
  String levelComplete(int level) {
    return 'Tapos na ang Antas $level!';
  }

  @override
  String get pagePuppy => 'Tuta';

  @override
  String get pageKuting => 'Pusa';

  @override
  String get pageElepante => 'Elepante';

  @override
  String get pageFlowerBasket => 'Bulaklak';

  @override
  String get pageRose => 'Rosas';

  @override
  String get pageMansanas => 'Mansanas';

  @override
  String get pageSaging => 'Saging';

  @override
  String get pageTeddyBear => 'Teddy Bear';

  @override
  String get pageSodaPop => 'Soft Drinks';

  @override
  String favoriteChosen(String choice) {
    return 'Ang paborito mo ay $choice!';
  }

  @override
  String helloName(String name) {
    return 'Kumusta, $name!';
  }

  @override
  String get letsLearnAndPlay => 'Matuto at maglaro tayo!';

  @override
  String get myProgressToday => 'Ang Aking Pag-unlad Ngayon';

  @override
  String get whatDoYouWantToLearn => 'Ano ang gusto mong matutunan?';

  @override
  String get rewardsCount => 'Gantimpala';

  @override
  String get activitiesCount => 'Gawain';

  @override
  String get lessonsCount => 'Mga Aralin';

  @override
  String familyRoleSentence(String member, String roles) {
    return 'Si $member ay $roles.';
  }

  @override
  String get resetAllStudents => 'Burahin lahat ng mag-aaral';

  @override
  String get confirmResetAllStudents =>
      'Sigurado ka bang gusto mong burahin ang lahat ng naka-enroll na mag-aaral? Hindi ito maa-undo.';

  @override
  String get confirm => 'Kumpirmahin';

  @override
  String get rateYourArtwork => 'Bigyan ng marka ang likhang-sining';

  @override
  String get howManyStars => 'Ilang butuin ang nararapat ditto?';

  @override
  String get tapToView => 'Pindutin upang makita';

  @override
  String get delete => 'Burahin';

  @override
  String get deleteArtwork => 'Burahin ang likhang-sining';

  @override
  String get confirmDeleteArtwork =>
      'Sigurado ka bang gusto mong burahin ang guhit na ito? Hindi na ito maibabalik.';

  @override
  String get artworkDeleted => 'Nabura na ang guhit.';

  @override
  String get fitPicture => 'Iangkop';

  @override
  String get greatSinging => 'Magaling kang kumanta!';

  @override
  String get readFullPoemBeforeBack => 'Basahin ang buong tula bago bumalik.';

  @override
  String get iReadThePoem => 'Nabasa Ko ang Tula!';

  @override
  String get readFullStoryBeforeBack =>
      'Basahin ang buong kwento bago bumalik.';

  @override
  String get iReadTheStory => 'Nabasa Ko Na Ito!';

  @override
  String get tandaanTitle => 'Tandaan!';

  @override
  String get tandaanSubtitle => 'Pag-ugnayin ang mga Pares';

  @override
  String get round => 'Bilog';

  @override
  String get matchThePairs => 'Hanapin at itugma ang magkapareha';

  @override
  String get flipCardsToMatch =>
      'Pindutin ang isang kard upang baligtarin ito. Maghanap ng dalawang magkapareho!';

  @override
  String get traceItTitle => 'Kaya mo iyan! Sundan ang guhit!';

  @override
  String get traceItSubtitle => 'Matuto ng iyong ABC!';

  @override
  String get checkTracing => 'Suriin';

  @override
  String get startAtDot => 'Magsimula sa tuldok!';

  @override
  String get almostThere => 'Malapit na! Subukan muli!';

  @override
  String progressPages(int done, int total) {
    return '$done / $total pahina';
  }

  @override
  String percentComplete(int percent) {
    return '$percent% kumpleto';
  }

  @override
  String get obraLabel => 'Obra';

  @override
  String get strokesLabel => 'Mga Pahid';

  @override
  String get categoryProgressHeader => 'Pag-unlad sa bawat Kategorya';

  @override
  String get savedArtworksHeader => 'Mga Nai-save na Obra';

  @override
  String get parentTipsHeader => 'Mga payo para sa mga Magulang';

  @override
  String get tipKulayTitle => 'Kulay-Saya';

  @override
  String get tipKulayBody =>
      'Hikayatin ang inyong anak na kulayin ang lahat ng pahina sa bawat kategorya.';

  @override
  String get tipTraceItTitle => 'Sundan Mo';

  @override
  String get tipTraceItBody =>
      'Gabayan ang inyong anak na sundan ang tamang direksyon ng bawat letra.';

  @override
  String get tipMagbasaTitle => 'Magbasa';

  @override
  String get tipMagbasaBody =>
      'Basahin nang malakas ang mga tula kasama ang bata para gumaling siya sa pagbigkas.';

  @override
  String get tipMatematikaTitle => 'Matematika';

  @override
  String get tipMatematikaBody =>
      'Hikayatin ang inyong anak na matapos ang bawat laro para mas lumago ang kakayahan sa bilang.';

  @override
  String get tipStudyTimeTitle => 'Oras ng Pag-aaral';

  @override
  String get tipStudyTimeBody =>
      'Mag-practice nang 15-20 minuto araw-araw para sa pinakamabuting resulta.';

  @override
  String progressCompleted(int done, int total) {
    return '$done / $total natatapos';
  }

  @override
  String progressActivities(int done, int total) {
    return '$done / $total aktibidad';
  }

  @override
  String progressGames(int done, int total) {
    return '$done / $total laro';
  }

  @override
  String get pointsStatLabel => 'Puntos';

  @override
  String get starsStatLabel => 'Bituin';

  @override
  String get gameProgressHeader => 'Progreso sa Bawat Laro';

  @override
  String get tipPencilGripTitle => 'Wastong Paghawak ng Lapis';

  @override
  String get tipPencilGripBody =>
      'Siguraduhing hawak nang tama ng iyong anak ang lapis o ginagamit ang daliri habang sinusundan ang mga linya.';

  @override
  String get tipRepeatTitle => 'Ulitin kung kailangan';

  @override
  String get tipRepeatBody =>
      'Hikayatin ang bata na ulitin ang mga letrang hindi pa niya natatapos.';

  @override
  String get tipPraiseTitle => 'Purihin ang Inyong Anak';

  @override
  String get tipPraiseBody =>
      'Purihin ang bawat tagumpay, malaki man o maliit, para mapalakas ang kanilang kumpiyansa.';

  @override
  String get tipTulaTitle => 'Mga Tula';

  @override
  String get tipTulaBody =>
      'Basahin nang malakas ang mga tula kasama ang inyong anak para mapabuti ang pagbigkas.';

  @override
  String get tipKwentoTitle => 'Kwento';

  @override
  String get tipKwentoBody =>
      'Tanungin ang bata tungkol sa kuwento pagkatapos magbasa para mas maintindihan niya ito.';

  @override
  String get tipKantaTitle => 'Mga Awit';

  @override
  String get tipKantaBody =>
      'Sabay na awitin ang mga kanta para maging masaya ang pag-aaral.';

  @override
  String get tipCountingTitle => 'Pagbibilang';

  @override
  String get tipCountingBody =>
      'Gumamit ng tunay na bagay tulad ng prutas o laruan para matutong magbilang ang bata.';

  @override
  String get tipPraiseMatTitle => 'Papuri';

  @override
  String get tipPraiseMatBody =>
      'Purihin ang inyong anak sa bawat tamang sagot para mapalakas ang kanilang kumpiyansa sa matematika.';

  @override
  String get tipGameFunTitle => 'Laro';

  @override
  String get tipGameFunBody =>
      'Ginagawa ang mga laro para maging masaya, kaya hayaang mag-enjoy ang bata sa pag-aaral.';

  @override
  String get badgeFirstStepsTitle => 'Unang Hakbang';

  @override
  String get badgeFirstStepsHint => 'Kunin ang iyong unang 3 bituin';

  @override
  String get badgeAlphabetTitle => 'Asahin ang Alphabeto';

  @override
  String get badgeAlphabetHint =>
      'Kolektahin ang lahat ng 19 na bituin sa Magbasa Tayo';

  @override
  String get badgeNumbersTitle => 'Kagalingan sa Numero';

  @override
  String get badgeNumbersHint => 'Sundan ang lahat ng 10 bilang.';

  @override
  String get badgeColorsTitle => 'Husayan sa Pagkulay';

  @override
  String get badgeColorsHint =>
      'Kolektahin ang lahat ng 9 na bituin sa Kulay-Saya.';

  @override
  String get badgeShapesTitle => 'Malalaking titik';

  @override
  String get badgeShapesHint => 'Sundan ang lahat ng 26 na malalaking titik.';

  @override
  String get badgeAnimalsTitle => 'Maliliit na titik';

  @override
  String get badgeAnimalsHint => 'Sundan ang lahat ng 26 na maliliit na titik.';

  @override
  String get badgeBookwormTitle => 'Munting Mambabasa';

  @override
  String get badgeBookwormHint =>
      'Kolektahin ang lahat ng 5 bituin sa mga Kuwento.';

  @override
  String get badgeStarStudentTitle => 'Tungkol sa Akin';

  @override
  String get badgeStarStudentHint =>
      'Makakuha ng 3 bituin sa lahat ng 4 na antas ng “Tungkol sa Akin.”';

  @override
  String get badgeMathWhizTitle => 'Dalubhasa sa Matematika';

  @override
  String get badgeMathWhizHint =>
      'Makakuha ng 3 bituin sa lahat ng 7 antas ng Matematika.';

  @override
  String get badgeFamilyHeroTitle => 'Bayani ng Pamilya';

  @override
  String get badgeFamilyHeroHint =>
      'Makakuha ng 3 bituin sa lahat ng 5 antas ng Pamilya.';

  @override
  String get badgeWritingStarTitle => 'Huwarang Manunulat';

  @override
  String get badgeWritingStarHint => 'Sundan ang bawat titik at bilang.';

  @override
  String get badgeSongbirdTitle => 'Biritera/Biritero';

  @override
  String get badgeSongbirdHint =>
      'Kolektahin ang lahat ng 9 bituin sa mga Awit.';

  @override
  String get badgeStreakFiveTitle => 'Araw-araw na bituin';

  @override
  String get badgeStreakFiveHint => 'Maglaro nang 5 araw na magkakasunod';

  @override
  String get claimBadgeButton => 'Kunin ang Badge';

  @override
  String get badgeClaimed => 'NAKUHA NA ANG BADGE';

  @override
  String get awesome => 'Ang galing!';

  @override
  String get claimBadgeBody =>
      'Napanalunan mo ang badge na ito! Kuhanin mo na para maidagdag sa iyong koleksyon.';

  @override
  String claimBadge(String title) {
    return 'Kunin ang $title';
  }

  @override
  String awardsWaiting(int earned, int remaining) {
    return '$earned nakuha, $remaining naghihintay na makuha!';
  }

  @override
  String get viewArtwork => 'Tingnan';

  @override
  String get brushSmall => 'Maliit';

  @override
  String get brushMedium => 'Katamtaman';

  @override
  String get brushLarge => 'Malaki';

  @override
  String get startOverYes => 'Oo, ulitin';

  @override
  String get keepColoring => 'Hindi, ituloy';

  @override
  String get loadingArtwork => 'Binubuksan ang iyong likha...';

  @override
  String get memoriseTheCards => 'Tandaan mo ang mga kard!';

  @override
  String get letsCount => 'Magbilang Tayo!';

  @override
  String get studentsLabel => 'Mga Mag-aaral';

  @override
  String get needsHelp => 'Nahuhuli';

  @override
  String get notSeenRecently => 'Di Naglalaro';

  @override
  String get theClass => 'Ang Klase';

  @override
  String get weakestFirst => 'Pinakakulang sa itaas';

  @override
  String get recentAchievements => 'Kamakailang Nakamit';

  @override
  String achievementEarnedBy(String name, String achievement) {
    return 'Nakuha ni $name ang $achievement';
  }

  @override
  String get searchStudents => 'Hanapin ang Mag-aaral';

  @override
  String get noStudentsMatch => 'Walang batang tumugma';

  @override
  String get everyoneActive => 'Lahat ay naglaro ngayong linggo';

  @override
  String daysAgo(int days) {
    return '${days}a nakalipas';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h nakalipas';
  }

  @override
  String get sariliProgress => 'Ang Aking Sarili at Aming Pamilya';

  @override
  String get tandaanProgress => 'Tandaan!';

  @override
  String starsOfPossible(int earned, int total) {
    return '$earned sa $total bituin';
  }

  @override
  String get notStartedYet => 'Hindi pa nasisimulan';

  @override
  String get memoryPairs => 'Magkaparehong pares';

  @override
  String get fruits => 'Mga Prutas';

  @override
  String get shapes => 'Mga Hugis';

  @override
  String get letters => 'Mga Titik';

  @override
  String get setParentPin => 'Gumawa ng 4-numerong code';

  @override
  String get setParentPinNote =>
      'Ikaw lang ang dapat nakakaalam nito. Hindi ito dapat mahulaan ng bata.';

  @override
  String get confirmParentPin => 'I-type itong muli';

  @override
  String get enterParentPin => 'Ilagay ang iyong code';

  @override
  String get pinMismatch => 'Magkaiba ang dalawang code';

  @override
  String get wrongPin => 'Maling code';

  @override
  String get forgotPin => 'Nakalimutan? Gamitin ang Student Number';

  @override
  String get pinSaved => 'Naitala ang code';

  @override
  String get or => 'o';

  @override
  String get openReport => 'Buksan';

  @override
  String get accountSecurity => 'Account at Seguridad';

  @override
  String get securityHeader => 'Seguridad';

  @override
  String get changeLogin => 'Palitan ang pag-login';

  @override
  String get changeLoginNote => 'Iupdate ang username at password';

  @override
  String get continueLabel => 'Magpatuloy';

  @override
  String get biometricLogin => 'Login gamit ang daliri o mukha';

  @override
  String get enableBiometric =>
      'Paganahin ang pag-log in gamit ang fingerprint';

  @override
  String get confirmYourPassword => 'Kumpirmahin ang iyong password';

  @override
  String get blankToKeepPassword =>
      'Iwanang blangko ang password kung ang username lang ang papalitan.';

  @override
  String get newPasswordStudentNumber => 'Bagong password (Student Number)';

  @override
  String get noBiometricOnDevice =>
      'Walang daliri o mukhang nakatakda sa teleponong ito,';

  @override
  String get noSessionLogInFirst =>
      'Walang bukas na account ng bata. Mag-log in muna.';

  @override
  String get resetActivity => 'I-reset ang Gawain';

  @override
  String get resetSpecificActivity => 'I-reset ang Piling Gawain';

  @override
  String get resetAllActivities => 'I-reset ang Lahat ng Gawain';

  @override
  String get resetAll => 'I-reset Lahat';

  @override
  String resetCount(int count) {
    return 'I-reset ($count)';
  }

  @override
  String pickActivitiesToReset(String name) {
    return 'Piliin ang mga gawaing nais i-reset para kay $name:';
  }

  @override
  String confirmResetAll(String name) {
    return 'I-reset ang LAHAT ng progreso ni $name? Hindi na ito maibabalik.';
  }

  @override
  String studentArtworks(int count) {
    return 'Mga Likha ($count)';
  }

  @override
  String get noArtworksSaved => 'Wala pang nai-save na likha.';

  @override
  String get middleName => 'Gitnang Pangalan';

  @override
  String get studentIdFormat =>
      'Pagkakakilanlan ng mag-aaral (Anyo: DC-2026-0001)';

  @override
  String get autoGenerateId => 'Gumawa ng ID para sa akin';

  @override
  String get accountPreview => 'Pribyu ng akawnt';

  @override
  String get studentInformation => 'Impormasyon ng Mag-aaral';

  @override
  String get parentInformation => 'Impormasyon ng Magulang';

  @override
  String get celebrate => 'Ipagdiwang';

  @override
  String stepOf(int current, int total, String label) {
    return 'Hakbang $current sa $total · $label';
  }

  @override
  String get autoGenerated => 'Gagawin para sa iyo';

  @override
  String get enterIdAbove => 'Ilagay ang ID sa itaas';

  @override
  String get couldNotLoad => 'Hindi ma-load. Subukan muli.';

  @override
  String get teacherSignInPrompt => 'Mag-sign in sa inyong akawnt bilang guro';

  @override
  String get daycareTeacher => 'Guro sa Daycare';

  @override
  String get useBiometric => 'Gamitin ang daliri o mukha';

  @override
  String get biometricUnavailable =>
      'Walang daliri o mukhang nakatakda sa teleponong ito, kaya hindi magagamit ang paraang ito.';

  @override
  String get strongest => 'Pinakamalakas';

  @override
  String get modulesHeader => 'Ang anim na modyul';

  @override
  String get credentialsUpdated => 'Na-update ang login.';

  @override
  String get biometricEnabled => 'Bukas na ang login gamit ang daliri.';

  @override
  String get biometricDisabled => 'Sarado na ang login gamit ang daliri.';

  @override
  String get biometricNotConfirmed => 'Hindi nakumpirma. Subukan muli.';

  @override
  String get passwordsDoNotMatch => 'Magkaiba ang dalawang password.';

  @override
  String get usernameEmpty => 'Maglagay ng username.';

  @override
  String get passwordIncorrect => 'Mali ang password na iyon.';

  @override
  String get studentNumberIncorrect => 'Mali ang Student Number na iyon.';

  @override
  String get confirmChildStudentNumber =>
      'Kumpirmahin ang Student Number ng bata';

  @override
  String get scanToEnableBiometric =>
      'Mag-scan para buksan ang login gamit ang daliri';

  @override
  String get certificateSaved => 'Nai-save ang sertipiko sa iyong mga larawan';

  @override
  String get certificateSaveFailed => 'Hindi na-save ang sertipiko.';

  @override
  String get howStarsEarned => 'Paano nakukuha ang bituin dito:';

  @override
  String get starOneTitle => 'Natapos mo';

  @override
  String get starOneBody => 'May isa sa bawat gawaing natapos mo.';

  @override
  String get starTwoTitle => 'Halos tama lahat';

  @override
  String get starTwoBody => 'Isang maling sagot lang sa buong laro.';

  @override
  String get starThreeTitle => 'Lahat tama sa unang subok';

  @override
  String get starThreeBody => 'Walang maling sagot kahit isa.';

  @override
  String get starTip => 'Ulitin at subukang tamaan lahat ng sagot.';

  @override
  String get gotIt => 'Naintindihan ko';

  @override
  String get yourCode => 'Ang code mo';

  @override
  String get yourCodeNote => 'Ang apat na numerong nagbubukas ng ulat na ito.';

  @override
  String get changeCode => 'Palitan ang code';

  @override
  String get currentCode => 'Kasalukuyang code';

  @override
  String get newCode => 'Bagong code';

  @override
  String get codeChanged => 'Napalitan ang code.';

  @override
  String get childLogin => 'Ang login ng anak mo';

  @override
  String get childLoginNote =>
      'Ang tinitipa ng anak mo para buksan ang app. Kayang palitan ito ng guro.';

  @override
  String get usernameTaken =>
      'May gumagamit na ng username na iyon. Pumili ng iba.';

  @override
  String get playedToday => 'Naglaro ngayon';

  @override
  String get playedYesterday => 'Naglaro kahapon';

  @override
  String playedDaysAgo(int days) {
    return 'Huling naglaro $days araw na ang nakalipas';
  }

  @override
  String get notPlayedYet => 'Hindi pa nagsisimula';

  @override
  String dayRun(int days) {
    return '$days araw na sunod-sunod';
  }

  @override
  String get removeFromDevice => 'Alisin sa teleponong ito';

  @override
  String removeFromDeviceNote(String name) {
    return 'Hindi na lalabas si $name dito o sa sign-in. Hindi nabubura ang account at ang mga nagawa niya — kayang ipasok siyang muli ng guro.';
  }

  @override
  String get childRemoved => 'Naalis sa teleponong ito.';

  @override
  String get chooseAvatar => 'Larawan';

  @override
  String get manageStudent => 'Pamahalaan ang mag-aaral';

  @override
  String get noStudentNumbersLeft =>
      'Wala nang natitirang student number para sa taong ito.';

  @override
  String moreModules(int count) {
    return '+$count pa';
  }

  @override
  String get filterBehindNote =>
      'Nagsimula na, pero malayo ang agwat sa klase.';

  @override
  String get filterQuietNote => 'Isang linggo o higit nang hindi nagbubukas.';

  @override
  String get authNothingToUpdate => 'Walang binago.';

  @override
  String get authSaveFailed =>
      'Hindi na-save ang pagbabago. Tingnan ang koneksyon.';

  @override
  String get authUsernameTaken =>
      'Gamit na ang username na iyan. Pumili ng iba.';

  @override
  String get authUseTeacherButton =>
      'Ito ang login ng bata. Gamitin ang \"Continue as Teacher\" sa ibaba ng screen.';

  @override
  String get authUsernameNotFound =>
      'Walang ganyang username. Tingnan ang baybay, o tanungin ang guro kung nakatala na ang bata.';

  @override
  String get authWrongStudentNumber =>
      'Mali ang Student Number na iyan. Subukan ulit.';

  @override
  String get authConnectionError =>
      'Hindi maabot ang server. Tingnan ang koneksyon.';

  @override
  String get authNumberEmpty =>
      'Hindi pwedeng walang laman ang Student Number.';

  @override
  String get authNumberFormat =>
      'Dapat ganito ang Student Number: DC-2026-0001.';

  @override
  String get authNumberRepeated =>
      'Hindi pwedeng apat na magkaparehong numero ang dulo.';

  @override
  String get authNumberTaken =>
      'May ibang bata nang may ganitong Student Number.';

  @override
  String get authEnrollFailed =>
      'Hindi naitala ang bata. Tingnan ang koneksyon.';

  @override
  String get authNoStudentsToDelete => 'Walang batang maaalis.';

  @override
  String get authAllStudentsDeleted => 'Naalis na ang lahat ng bata.';

  @override
  String get authDeleteFailed => 'Hindi naalis ang mga bata. Subukan ulit.';

  @override
  String get authNoStudentsToReset => 'Walang batang mare-reset.';

  @override
  String authResetDone(int count) {
    return 'Na-reset ang login ng $count bata.';
  }

  @override
  String get authResetFailed => 'Hindi na-reset ang login. Subukan ulit.';

  @override
  String get passwordNotSetYet => 'Wala pa.';

  @override
  String get passwordChangedByParent =>
      'Pinalitan ito ng magulang. Hindi na ito ang Student Number.';

  @override
  String get authPasswordTooShort =>
      'Kailangan ng hindi bababa sa 4 na karakter ang password.';

  @override
  String get newPasswordLabel => 'Bagong password';

  @override
  String get whatToPractise => 'Ano ang Sanayin';

  @override
  String get nothingToPractise =>
      'Wala. Nasasagot nang tama ng batang ito ang mga tanong.';

  @override
  String get pupilReport => 'Ang progreso ng mag-aaral na ito sa E-Tarabay.';

  @override
  String get editStudent => 'I-edit ang detalye';

  @override
  String get copyByHand =>
      'Hindi pinapayagan ng browser na kopyahin ito ng app. Piliin at kopyahin nang manu-mano.';

  @override
  String get confirmNewPassword => 'Ulitin ang bagong password';

  @override
  String get newParentPin => 'Bagong code';

  @override
  String get welcome => 'Maligayang pagbabalik!';

  @override
  String switchToChild(String name) {
    return 'Buksan ang account ni $name';
  }

  @override
  String switchToChildNote(String name) {
    return 'Magiging kay $name ang app. Walang kailangang mag-login ulit, at nananatili ang mga nagawa nila.';
  }

  @override
  String get switchAccount => 'Lumipat';

  @override
  String get switchNeedsConnection =>
      'Kumonekta muna sa internet — may nagawa ang batang ito na nasa teleponong ito lang.';

  @override
  String get scoreWord => 'Marka';

  @override
  String get streakWord => 'Sunod-sunod na tama';

  @override
  String get notifPermissionDenied =>
      'Payagan muna ang abiso sa settings ng iyong telepono.';

  @override
  String get greetMorning => 'Magandang Umaga!';

  @override
  String get greetAfternoon => 'Magandang Hapon!';

  @override
  String get greetEvening => 'Magandang Gabi!';

  @override
  String get updateAvailableTitle => 'May bagong bersyon!';

  @override
  String updateAvailableBody(String version) {
    return 'Handa nang i-download ang bersyon $version.';
  }

  @override
  String get updateDownloadNow => 'I-download Ngayon';

  @override
  String get updateLater => 'Mamaya na Lang';

  @override
  String get bgPermissionTitle => 'Sabihin Mo kay Mama o Papa!';

  @override
  String get bgPermissionBody =>
      'Para gumana ang mga paalala, dapat payagan nila ang E-Tarabay sa Battery at Autostart settings ng telepono.';

  @override
  String get roleAnyAnswer => 'Oo! Makatutulong ang bawat miyembro ng pamilya.';

  @override
  String get yesAnswer => 'Oo';

  @override
  String get noAnswer => 'Hindi';

  @override
  String get resetActivitiesDone =>
      'Matagumpay na na-reset ang napiling activities.';

  @override
  String get resetActivitiesFailed =>
      'Hindi na-reset ang activities. Subukan muli.';

  @override
  String get letterWord => 'Titik';

  @override
  String get numberWord => 'Numero';
}
