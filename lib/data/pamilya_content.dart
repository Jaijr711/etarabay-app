import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class PamilyaContent {
  // ── Main Categories ───────────────────────────────────────────────────
  static List<Map<String, dynamic>> getMainCategories(String lang) {
    return _mainCategories[lang] ?? _mainCategories['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _mainCategories = {
    'en': [
      {
        'title': 'About Myself',
        'icon': LucideIcons.user,
        'color': Color(0xFFFF6B6B)
      },
      {
        'title': 'My Family',
        'icon': LucideIcons.users,
        'color': Color(0xFF4ECDC4)
      },
    ],
    'fil': [
      {
        'title': 'Ang Aking Sarili',
        'icon': LucideIcons.user,
        'color': Color(0xFFFF6B6B)
      },
      {
        'title': 'Ang Aking Pamilya',
        'icon': LucideIcons.users,
        'color': Color(0xFF4ECDC4)
      },
    ],
    'ilo': [
      {'title': 'Ti Bagik', 'icon': LucideIcons.user, 'color': Color(0xFFFF6B6B)},
      {
        'title': 'Ti Pamilyak',
        'icon': LucideIcons.users,
        'color': Color(0xFF4ECDC4)
      },
    ],
  };

  // ── Category Level Titles ──────────────────────────────────────────────
  static List<List<String>> getCategoryLevelTitles(String lang) {
    return _categoryLevelTitles[lang] ?? _categoryLevelTitles['ilo']!;
  }

  static const Map<String, List<List<String>>> _categoryLevelTitles = {
    'en': [
      ['All About Me', 'My Emotions', 'Daily Routines', 'My Preferences'],
      [
        'Family Members',
        'Family Roles',
        'Family Activities',
        'Family Tree',
        'Our Home'
      ],
    ],
    'fil': [
      [
        'Tungkol sa Akin',
        'Aking Emosyon',
        'Araw-araw na Gawain',
        'Aking mga Paborito'
      ],
      [
        'Mga Miyembro ng Pamilya',
        'Tungkulin sa Pamilya',
        'Mga Gawain ng Pamilya',
        'Puno ng Pamilya',
        'Ang Aming Tahanan'
      ],
    ],
    'ilo': [
      ['Maipanggep Kaniak', 'Dagiti Riknak', 'Inaldaw nga Aramid', 'Paboritok'],
      [
        'Dagiti Miyembro ti Pamilya',
        'Trabaho iti Pamilya',
        'Aramid ti Pamilya',
        'Punuan ti Pamilya',
        'Ti Balaymi'
      ],
    ],
  };

  // ── Sarili Level 1: About Me ─────────────────────────────────────────
  static List<Map<String, dynamic>> getSariliLevel1Games(String lang) {
    return _sariliLevel1Games[lang] ?? _sariliLevel1Games['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _sariliLevel1Games = {
    'en': [
      {
        'id': 'about_name',
        'question': 'What is your name?',
        'type': 'text_input',
        'hint': 'Type your name here',
        'icon': '👤',
        'description':
            'Your name is what your family and friends call you. It is important!',
      },
      {
        'id': 'about_age',
        'question': 'How old are you?',
        'type': 'age_input',
        'hint': 'Example: 5, 7, 10',
        'icon': '🎂',
        'description':
            'Your age is the number of years since you were born. Celebrate every year!',
      },
      {
        'id': 'about_gender',
        'question': 'Are you a boy or a girl?',
        'type': 'choice',
        'options': ['👧 Girl', '👦 Boy'],
        'values': [0, 1],
        'icon': '👤',
        'description':
            'Knowing if you are a boy or a girl helps us know more about you!',
      },
      {
        'id': 'about_birthday',
        'question': 'When is your birthday?',
        'type': 'info',
        'icon': '🎉',
        'info': 'Your birthday is the day you were born.',
        'example': 'Example: January 15, 2018 — Happy Birthday!',
        'description': 'Celebrate your birthday with your family!',
      },
      {
        'id': 'about_home',
        'question': 'Where do you live?',
        'type': 'text_input',
        'hint': 'Name of city or town',
        'icon': '🏠',
        'description':
            'Your home is the place where you live with your family. Home sweet home!',
      },
    ],
    'fil': [
      {
        'id': 'about_name',
        'question': 'Ano ang pangalan mo?',
        'type': 'text_input',
        'hint': 'I-type ang pangalan mo dito',
        'icon': '👤',
        'description':
            'Ang pangalan mo ay ang tawag sa iyo ng pamilya at mga kaibigan. Mahalaga ito!',
      },
      {
        'id': 'about_age',
        'question': 'Ilang taon ka na?',
        'type': 'age_input',
        'hint': 'Halimbawa: 5, 7, 10',
        'icon': '🎂',
        'description':
            'Ang iyong edad ay ang bilang ng taon mula noong ipinanganak ka. Ipagdiwang bawat taon!',
      },
      {
        'id': 'about_gender',
        'question': 'Babae ka ba o lalaki?',
        'type': 'choice',
        'options': ['👧 Babae', '👦 Lalaki'],
        'values': [0, 1],
        'icon': '👤',
        'description':
            'Ang pag-alam kung babae o lalaki ka ay tumutulong sa amin na makilala ka!',
      },
      {
        'id': 'about_birthday',
        'question': 'Kailan ang kaarawan mo?',
        'type': 'info',
        'icon': '🎉',
        'info': 'Ang iyong kaarawan ay ang araw na ipinanganak ka.',
        'example': 'Halimbawa: Enero 15, 2018 — Maligayang Kaarawan!',
        'description': 'Ipagdiwang ang iyong kaarawan kasama ang pamilya!',
      },
      {
        'id': 'about_home',
        'question': 'Saan ka nakatira?',
        'type': 'text_input',
        'hint': 'Pangalan ng lungsod o bayan',
        'icon': '🏠',
        'description':
            'Ang iyong tahanan ay ang lugar na iyong tinitirhan kasama ang pamilya. Sarap sa tahanan!',
      },
    ],
    'ilo': [
      {
        'id': 'about_name',
        'question': 'Ania ti naganmo?',
        'type': 'text_input',
        'hint': 'I-type ti naganmo ditoy',
        'icon': '👤',
        'description':
            'Ti naganmo ket ti tawag kenka ti pamilyam ken gagayyemmo. Napateg dayta!',
      },
      {
        'id': 'about_age',
        'question': 'Mano ti tawenmo?',
        'type': 'age_input',
        'hint': 'Kas pagarigan: 5, 7, 10',
        'icon': '🎂',
        'description':
            'Ti tawenmo ket ti bilang dagiti tawen manipud idi nayanakka. Kapadas ti selebrar!',
      },
      {
        'id': 'about_gender',
        'question': 'Babai ka kadi wenno lalaki?',
        'type': 'choice',
        'options': ['👧 Babai', '👦 Lalaki'],
        'values': [0, 1],
        'icon': '👤',
        'description':
            'Ti kasarianmo ket paset ti kinataom. Napateg ken naan-anay.',
      },
      {
        'id': 'about_birthday',
        'question': 'Kaano ti pannakayanakmo?',
        'type': 'info',
        'icon': '🎉',
        'info': 'Ti pannakayanakmo ket ti aldaw idi nayanakka.',
        'example': 'Kas pagarigan: Enero 15, 2018 — Aldaw ti Pannakayanak!',
        'description': 'Selebrasyon ti pannakayanakmo kadua ti pamilyam.',
      },
      {
        'id': 'about_home',
        'question': 'Sadino ti pagtaengam?',
        'type': 'text_input',
        'hint': 'Nagan ti siudad wenno ili',
        'icon': '🏠',
        'description':
            'Ti pagtaengam ket ti lugar a pagyanam a kadua ti pamilyam. Naimbag ti balay!',
      },
    ],
  };

  // ── Sarili Level 2: Emotions ───────────────────────────────────────────
  static List<Map<String, dynamic>> getSariliLevel2Games(String lang) {
    return _sariliLevel2Games[lang] ?? _sariliLevel2Games['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _sariliLevel2Games = {
    'en': [
      {
        'id': 'emotion_happy',
        'question': 'When are you HAPPY?',
        'choices': [
          '🎁 When there is a gift or surprise',
          '😢 When someone is mean',
          '😴 When sleepy'
        ],
        'correct': 0,
        'explanation':
            'Correct! We are happy when good things happen like receiving gifts or celebrating.',
        'tip': 'Smile and share your happiness with your family!',
      },
      {
        'id': 'emotion_sad',
        'question': 'When are you SAD?',
        'choices': [
          '🎂 When there is a birthday party',
          '🧸 When your favorite toy is lost',
          '🍦 When eating ice cream'
        ],
        'correct': 1,
        'explanation':
            'Correct! It is normal to feel sad when we lose something or when something bad happens.',
        'tip': 'When you are sad, hug your mom or dad.',
      },
      {
        'id': 'emotion_angry',
        'question': 'When are you ANGRY?',
        'choices': [
          '🎮 When you win a game',
          '🧸 When you get a new toy',
          '👊 When someone takes your toy without asking'
        ],
        'correct': 2,
        'explanation':
            'Correct! We get angry when something unfair or wrong happens.',
        'tip': 'When you are angry, take a deep breath and count to five.',
      },
      {
        'id': 'emotion_surprised',
        'question': 'When are you SURPRISED?',
        'choices': [
          '🎁 When there is an unexpected surprise',
          '🍚 When eating',
          '😴 When sleeping'
        ],
        'correct': 0,
        'explanation':
            'Correct! We are surprised when something unexpected happens.',
        'tip': 'It is okay to be surprised — learning is an adventure!',
      },
      {
        'id': 'emotion_sleepy',
        'question': 'When are you SLEEPY?',
        'choices': [
          '🌅 In the morning after waking up',
          '🌙 When it is night time',
          '☀️ When playing outside'
        ],
        'correct': 1,
        'explanation':
            'Correct! We feel sleepy at night because it is time to sleep.',
        'tip': 'Go to bed early so you can grow big and strong!',
      },
      {
        'id': 'emotion_scared',
        'question': 'When are you SCARED?',
        'choices': [
          '🌈 When there is a rainbow',
          '⚡ When there is thunder and lightning',
          '☀️ On a sunny day'
        ],
        'correct': 1,
        'explanation': 'Correct! We are scared of loud sounds like thunder.',
        'tip': 'When you are scared, hug your mom or dad.',
      },
    ],
    'fil': [
      {
        'id': 'emotion_happy',
        'question': 'Kailan ka MASAYA?',
        'choices': [
          '🎁 Kapag may regalo o sorpresa',
          '😢 Kapag may masamaang ginawa',
          '😴 Kapag inaantok'
        ],
        'correct': 0,
        'explanation':
            'Tama! Masaya tayo kapag may magandang nangyayari tulad ng regalo o pagdiriwang.',
        'tip': 'Ngumiti at ibahagi ang iyong kasiyahan sa pamilya!',
      },
      {
        'id': 'emotion_sad',
        'question': 'Kailan ka MALUNGKOT?',
        'choices': [
          '🎂 Kapag may kaarawan',
          '🧸 Kapag nawala ang paboritong laruan',
          '🍦 Kapag kumakain ng ice cream'
        ],
        'correct': 1,
        'explanation':
            'Tama! Normal ang malungkot kapag may nawala o may masamang nangyari.',
        'tip': 'Kapag malungkot ka, yakapin ang nanay o tatay mo.',
      },
      {
        'id': 'emotion_angry',
        'question': 'Kailan ka GALIT?',
        'choices': [
          '🎮 Kapag nanalo sa laro',
          '🧸 Kapag may bagong laruan',
          '👊 Kapag may kumuha ng laruan mo nang hindi nagpaalam'
        ],
        'correct': 2,
        'explanation':
            'Tama! Nagagalit tayo kapag may hindi patas o masamang nangyari.',
        'tip':
            'Kapag galit ka, huminga nang malalim at bumilang hanggang lima.',
      },
      {
        'id': 'emotion_surprised',
        'question': 'Kailan ka NASURPRESA?',
        'choices': [
          '🎁 Kapag may di inaasahang sorpresa',
          '🍚 Kapag kumakain',
          '😴 Kapag natutulog'
        ],
        'correct': 0,
        'explanation':
            'Tama! Nasusurpresa tayo kapag may di inaasahang nangyayari.',
        'tip': 'Okay lang mabigla — ang pag-aaral ay isang pakikipagsapalaran!',
      },
      {
        'id': 'emotion_sleepy',
        'question': 'Kailan ka INAANTOK?',
        'choices': [
          '🌅 Sa umaga pagkagising',
          '🌙 Kapag gabi na',
          '☀️ Kapag naglalaro sa labas'
        ],
        'correct': 1,
        'explanation':
            'Tama! Inaantok tayo kapag gabi na dahil oras na matulog.',
        'tip': 'Matulog nang maaga para lumaki nang malakas!',
      },
      {
        'id': 'emotion_scared',
        'question': 'Kailan ka TAKOT?',
        'choices': [
          '🌈 Kapag may bahaghari',
          '⚡ Kapag may kulog at kidlat',
          '☀️ Sa araw na maliwanag'
        ],
        'correct': 1,
        'explanation':
            'Tama! Natatakot tayo sa malakas na tunog tulad ng kulog.',
        'tip': 'Kapag takot ka, yakapin ang nanay o tatay mo.',
      },
    ],
    'ilo': [
      {
        'id': 'emotion_happy',
        'question': 'Kaano ka NARAG-O?',
        'choices': [
          '🎁 No adda regalo wenno sorpresa',
          '😢 No mananatangken',
          '😴 No matuturog'
        ],
        'correct': 0,
        'explanation':
            'Nalinteg! Narag-o tayo no adda nasayaat a mapasamak kas ti regalo wenno pesta.',
        'tip': 'Ngumingiti ka ken ibagam ti ragsak mo iti pamilyam!',
      },
      {
        'id': 'emotion_sad',
        'question': 'Kaano ka NALUNLUNGOT?',
        'choices': [
          '🎂 No adda kasangay',
          '🧸 No mawanen ti paboritom a laruan',
          '🍦 No kumkumanen ti ice cream'
        ],
        'correct': 1,
        'explanation':
            'Nalinteg! Normal ti maglunglungot no adda mawanen wenno no adda di nasayaat a napasamak.',
        'tip': 'No nalunglungot ka, yakap ti nanangmo wenno amam.',
      },
      {
        'id': 'emotion_angry',
        'question': 'Kaano ka NAALIGUTGET?',
        'choices': [
          '🎮 No nanalo iti laro',
          '🧸 No adda baro a laruan',
          '👊 No inala ti laruanmo nga awan pannakaisuro'
        ],
        'correct': 2,
        'explanation':
            'Nalinteg! Naaligutgettayo no adda di umiso wenno di nalinteg a napasamak.',
        'tip': 'No naaligutget ka, sumrek ti angin ken bilangen iti lima.',
      },
      {
        'id': 'emotion_surprised',
        'question': 'Kaano ka NASDAAW?',
        'choices': [
          '🎁 No adda di inayan a sorpresa',
          '🍚 No mangan',
          '😴 No matulog'
        ],
        'correct': 0,
        'explanation': 'Nalinteg! Nasdaaw tayo no adda di inayan a napasamak.',
        'tip': 'Mabalin a mangsdaaw — simmuroten ti pannakaadal!',
      },
      {
        'id': 'emotion_sleepy',
        'question': 'Kaano ka MAUYONG?',
        'choices': [
          '🌅 No bigbigat kalpasan ti panagtilmon',
          '🌙 No rabii na',
          '☀️ No agalagad'
        ],
        'correct': 1,
        'explanation':
            'Nalinteg! Mauyong tayo no rabii na ta oras na ti matulog.',
        'tip': 'Agtugaw nang nasapa tapno lumaki nang naruay!',
      },
      {
        'id': 'emotion_scared',
        'question': 'Kaano ka NATAKOT?',
        'choices': [
          '🌈 No adda balangaw',
          '⚡ No adda kimat ken kulog',
          '☀️ No init ti aldaw'
        ],
        'correct': 1,
        'explanation':
            'Nalinteg! Natakot tayo iti nalaing a sirak kas ti kulog.',
        'tip': 'No natakot ka, yakap ti nanangmo wenno amam.',
      },
    ],
  };

  // ── Sarili Level 3: Daily Routines ───────────────────────────────────
  static List<Map<String, dynamic>> getSariliLevel3Games(String lang) {
    return _sariliLevel3Games[lang] ?? _sariliLevel3Games['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _sariliLevel3Games = {
    'en': [
      {
        'id': 'routine_morning',
        'question':
            'What is the first thing you do in the MORNING after waking up?',
        'choices': [
          '🛏️ Wake up and get out of bed',
          '🍳 Eat breakfast',
          '📺 Watch TV'
        ],
        'correct': 0,
        'explanation':
            'Correct! First we wake up and get out of bed before doing other things.',
        'tip': 'Wake up early to be ready for the whole day!',
      },
      {
        'id': 'routine_afternoon',
        'question': 'What do we usually do in the AFTERNOON?',
        'choices': [
          '📚 Study or play',
          '🍚 Eat lunch',
          '😴 Sleep the whole afternoon'
        ],
        'correct': 0,
        'explanation': 'Correct! In the afternoon, we study or play.',
        'tip': 'Balance your time for studying and playing!',
      },
      {
        'id': 'routine_evening',
        'question': 'What can you do before going to BED?',
        'choices': [
          '🪥 Brush your teeth',
          '🍪 Eat a snack',
          '📱 Play with a cellphone'
        ],
        'correct': 0,
        'explanation':
            'Correct! It is important to brush your teeth before sleeping to protect them.',
        'tip': 'Clean teeth mean no toothaches!',
      },
      {
        'id': 'routine_hygiene',
        'question': 'How can you protect yourself from getting sick?',
        'choices': [
          '🧼 Wash your hands',
          '🪥 Just brush teeth',
          '💧 Drink water'
        ],
        'correct': 0,
        'explanation': 'Correct! Washing your hands prevents sickness.',
        'tip': 'Wash your hands before eating and after using the bathroom!',
      },
    ],
    'fil': [
      {
        'id': 'routine_morning',
        'question': 'Ano ang unang ginagawa mo sa UMAGA pagkagising?',
        'choices': [
          '🛏️ Bumangon at tumayo sa kama',
          '🍳 Kumain ng agahan',
          '📺 Manood ng TV'
        ],
        'correct': 0,
        'explanation':
            'Tama! Una tayong bumangon at tumayo sa kama bago gumawa ng iba.',
        'tip': 'Magising nang maaga para maging handa sa buong araw!',
      },
      {
        'id': 'routine_afternoon',
        'question': 'Ano ang karaniwang ginagawa natin sa HAPON?',
        'choices': [
          '📚 Mag-aral o maglaro',
          '🍚 Kumain ng tanghalian',
          '😴 Matulog buong hapon'
        ],
        'correct': 0,
        'explanation': 'Tama! Sa hapon, nag-aaral tayo o naglalaro.',
        'tip': 'Pagbalansehin ang oras para sa pag-aaral at paglalaro!',
      },
      {
        'id': 'routine_evening',
        'question': 'Ano ang maaari mong gawin bago MATULOG?',
        'choices': [
          '🪥 Magsepilyo',
          '🍪 Kumain ng meryenda',
          '📱 Maglaro ng cellphone'
        ],
        'correct': 0,
        'explanation':
            'Tama! Mahalaga ang magsepilyo bago matulog para maprotektahan ang ngipin.',
        'tip': 'Malinis na ngipin ay walang sakit!',
      },
      {
        'id': 'routine_hygiene',
        'question': 'Paano ka makaiiwas sa pagkakasakit?',
        'choices': [
          '🧼 Maghugas ng kamay',
          '🪥 Magsepilyo lang',
          '💧 Uminom ng tubig'
        ],
        'correct': 0,
        'explanation': 'Tama! Ang paghuhugas ng kamay ay iwas-sakit.',
        'tip': 'Maghugas ng kamay bago kumain at pagkatapos gamitin ang banyo!',
      },
    ],
    'ilo': [
      {
        'id': 'routine_morning',
        'question':
            'Ania ti umuna nga aramidenmo no BIGBIGAT kalpasan ti panagtilmon?',
        'choices': [
          '🛏️ Agtilmon ken agbangon',
          '🍳 Kumanen ti agahon',
          '📺 Ag-TV'
        ],
        'correct': 0,
        'explanation':
            'Nalinteg! Umuna nga agtilmon ken agbangon sakbay ti sabali nga gapuanan.',
        'tip': 'Agbangon nang nasapa tapno naandam iti intero nga aldaw!',
      },
      {
        'id': 'routine_afternoon',
        'question': 'Ania ti kaslakami nga aramidenmo iti MALEM?',
        'choices': [
          '📚 Agadal wenno aglaro',
          '🍚 Kumanen ti pangaldaw',
          '😴 Matulog ti intero nga malem'
        ],
        'correct': 0,
        'explanation': 'Nalinteg! Iti malem, agadal tayo wenno aglaro.',
        'tip': 'Pagtalinaeden ti oras para iti panagadal ken panaglaro!',
      },
      {
        'id': 'routine_evening',
        'question': 'Ania ti mabalin nga aramidenmo sakbay ti PANAGTUROG?',
        'choices': [
          '🪥 Agsuplit',
          '🍪 Kumanen ti merienda',
          '📱 Aglaro iti cellphone'
        ],
        'correct': 0,
        'explanation':
            'Nalinteg! Napateg ti panagsuplit sakbay ti panagturog tapno maprotektaran ti ngipen.',
        'tip': 'Ti nasuyat nga ngipen ket iwas sakit!',
      },
      {
        'id': 'routine_hygiene',
        'question': 'Kasano ti maprotektaranmo ti bagim iti sakit?',
        'choices': [
          '🧼 Aghugas iti ima',
          '🪥 Agsuplit laeng',
          '💧 Uminom iti danum'
        ],
        'correct': 0,
        'explanation': 'Nalinteg! Ti panaghugas iti ima ket iwas sakit.',
        'tip': 'Aghugas iti ima sakbay ti panangan ken kalpasan ti banio!',
      },
    ],
  };

  // ── Sarili Level 4: Preferences ────────────────────────────────────────
  static List<Map<String, dynamic>> getSariliLevel4Games(String lang) {
    return _sariliLevel4Games[lang] ?? _sariliLevel4Games['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _sariliLevel4Games = {
    'en': [
      {
        'id': 'preference_food',
        'question': 'What is your favorite FOOD?',
        'options': ['🍚 Rice', '🐟 Fish', '🍛 Stew', '🍖 Meat'],
        'emojis': ['🍚', '🐟', '🍛', '🍖'],
        'description': 'Choose your favorite food!',
      },
      {
        'id': 'preference_color',
        'question': 'What is your favorite COLOR?',
        'options': ['🔴 Red', '🔵 Blue', '🟢 Green', '🟡 Yellow'],
        'emojis': ['🔴', '🔵', '🟢', '🟡'],
        'description': 'Pick your favorite color!',
      },
      {
        'id': 'preference_game',
        'question': 'What is your favorite GAME?',
        'options': ['🪀 Hopscotch', '🏃 Tag', '🧩 Puzzle', '🎯 Ring Toss'],
        'emojis': ['🪀', '🏃', '🧩', '🎯'],
        'description': 'Fun games to play with friends!',
      },
      {
        'id': 'preference_animal',
        'question': 'What is your favorite ANIMAL?',
        'options': ['🐶 Dog', '🐱 Cat', '🐓 Chicken', '🐃 Carabao'],
        'emojis': ['🐶', '🐱', '🐓', '🐃'],
        'description': 'Pick your favorite animal!',
      },
    ],
    'fil': [
      {
        'id': 'preference_food',
        'question': 'Ano ang paboritong PAGKAIN mo?',
        'options': ['🍚 Kanin', '🐟 Isda', '🍛 Ginisang Gulay', '🍖 Karne'],
        'emojis': ['🍚', '🐟', '🍛', '🍖'],
        'description': 'Pumili ng paboritong pagkain!',
      },
      {
        'id': 'preference_color',
        'question': 'Ano ang paboritong KULAY mo?',
        'options': ['🔴 Pula', '🔵 Asul', '🟢 Berde', '🟡 Dilaw'],
        'emojis': ['🔴', '🔵', '🟢', '🟡'],
        'description': 'Pumili ng paboritong kulay!',
      },
      {
        'id': 'preference_game',
        'question': 'Ano ang paboritong LARO mo?',
        'options': ['🪀 Piko', '🏃 Taguan', '🧩 Puzzle', '🎯 Tumbang Preso'],
        'emojis': ['🪀', '🏃', '🧩', '🎯'],
        'description': 'Masasayang laro kasama ang mga kaibigan!',
      },
      {
        'id': 'preference_animal',
        'question': 'Ano ang paboritong HAYOP mo?',
        'options': ['🐶 Aso', '🐱 Pusa', '🐓 Manok', '🐃 Kalabaw'],
        'emojis': ['🐶', '🐱', '🐓', '🐃'],
        'description': 'Pumili ng paboritong hayop!',
      },
    ],
    'ilo': [
      {
        'id': 'preference_food',
        'question': 'Ania ti paboritom nga MAKAN?',
        'options': [
          '🍚 Sinanglaw',
          '🐟 Pinakbet',
          '🍛 Dinengdeng',
          '🍖 Bagnet'
        ],
        'emojis': ['🍚', '🐟', '🍛', '🍖'],
        'description': 'Dagiti nailian nga makan ti Ilocos! Umili ka!',
      },
      {
        'id': 'preference_color',
        'question': 'Ania ti paboritom nga KULOR?',
        'options': [
          '🔴 Nalabbaga',
          '🔵 Natimgas',
          '🟢 Nalabbag-o',
          '🟡 Nadarang'
        ],
        'emojis': ['🔴', '🔵', '🟢', '🟡'],
        'description': 'Pumili ka iti paboritom nga kulor!',
      },
      {
        'id': 'preference_game',
        'question': 'Ania ti paboritom nga LARO?',
        'options': ['🪀 Piko', '🏃 Taguan', '🧩 Puzzle', '🎯 Tumbang Preso'],
        'emojis': ['🪀', '🏃', '🧩', '🎯'],
        'description': 'Dagiti nailian nga laro! Maymaysa a naraig!',
      },
      {
        'id': 'preference_animal',
        'question': 'Ania ti paboritom nga HAYOP?',
        'options': ['🐶 Aso', '🐱 Pusa', '🐓 Manok', '🐃 Nuang'],
        'emojis': ['🐶', '🐱', '🐓', '🐃'],
        'description': 'Pumili iti paboritom nga ayup!',
      },
    ],
  };

  // ── Pamilya Level 1: Family Members ────────────────────────────────────
  static List<Map<String, dynamic>> getPamilyaLevel1Games(String lang) {
    return _pamilyaLevel1Games[lang] ?? _pamilyaLevel1Games['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _pamilyaLevel1Games = {
    'en': [
      {
        'id': 'family_mother',
        'question': 'Who takes care of you, cooks food, and gives you love?',
        'choices': ['👩 Mother', '👨 Father', '👧 Sister', '👦 Brother'],
        'correct': 0,
        'member': 'Mother',
        'emoji': '👩',
        'roles': 'cooking, caring, loving',
        'description': 'Mother takes care of us and cooks delicious food.',
        'note': 'In Filipino, we call mother "Nanay" or "Ina".',
        'audioPath': 'audio/family/ni_nanang.mp3'
      },
      {
        'id': 'family_father',
        'question': 'Who works for the family and loves to play with you?',
        'choices': ['👩 Mother', '👨 Father', '👧 Sister', '👦 Brother'],
        'correct': 1,
        'member': 'Father',
        'emoji': '👨',
        'roles': 'working, playing, protecting',
        'description': 'Father works for the family and is fun to play with.',
        'note': 'In Filipino, we call father "Tatay" or "Ama".',
        'audioPath': 'audio/family/si_amang.mp3'
      },
      {
        'id': 'family_brother',
        'question': 'Who is your older brother?',
        'choices': [
          '👩 Mother',
          '👨 Father',
          '👧 Older Sister',
          '👦 Older Brother'
        ],
        'correct': 3,
        'member': 'Older Brother',
        'emoji': '👦',
        'roles': 'older sibling, companion, playmate',
        'description': 'Your older brother is your older male sibling.',
        'note': 'In Filipino, we call older brother "Kuya".',
        'audioPath': 'audio/family/ni_manong.mp3'
      },
      {
        'id': 'family_sister',
        'question': 'Who is your older sister?',
        'choices': [
          '👩 Mother',
          '👨 Father',
          '👧 Older Sister',
          '👦 Older Brother'
        ],
        'correct': 2,
        'member': 'Older Sister',
        'emoji': '👧',
        'roles': 'older sibling, helps at home, playmate',
        'description': 'Your older sister is your older female sibling.',
        'note': 'In Filipino, we call older sister "Ate".',
        'audioPath': 'audio/family/ni_manang.mp3'
      },
      {
        'id': 'family_youngest',
        'question': 'Who is the youngest member of the family?',
        'choices': [
          '👶 Youngest Sibling',
          '👦 Older Brother',
          '👧 Older Sister',
          '👴 Grandfather'
        ],
        'correct': 0,
        'member': 'Youngest Sibling',
        'emoji': '👶',
        'roles': 'youngest sibling, cared for',
        'description': 'The youngest is the youngest member of the family.',
        'note': 'In Filipino, we call the youngest sibling "Bunso".',
        'audioPath': 'audio/family/ni_bunsoy.mp3'
      },
      {
        'id': 'family_grandfather',
        'question': 'Who is the father of your mother or father?',
        'choices': [
          '👴 Grandfather',
          '👵 Grandmother',
          '👨 Father',
          '👩 Mother'
        ],
        'correct': 0,
        'member': 'Grandfather',
        'emoji': '👴',
        'roles': 'tells stories, gives advice',
        'description': 'Grandfather is the father of your mother or father.',
        'note': 'In Filipino, we call grandfather "Lolo".',
        'audioPath': 'audio/family/ni_lelong.mp3'
      },
      {
        'id': 'family_grandmother',
        'question': 'Who is the mother of your mother or father?',
        'choices': [
          '👴 Grandfather',
          '👵 Grandmother',
          '👨 Father',
          '👩 Mother'
        ],
        'correct': 1,
        'member': 'Grandmother',
        'emoji': '👵',
        'roles': 'cooks delicious food, tells stories',
        'description': 'Grandmother is the mother of your mother or father.',
        'note': 'In Filipino, we call grandmother "Lola".',
        'audioPath': 'audio/family/ni_leling.mp3'
      },
    ],
    'fil': [
      {
        'id': 'family_mother',
        'question': 'Sino ang nag-aalaga sa iyo, nagluluto, at nagmamahal?',
        'choices': ['👩 Nanay', '👨 Tatay', '👧 Ate', '👦 Kuya'],
        'correct': 0,
        'member': 'Nanay',
        'emoji': '👩',
        'roles': 'nagluluto, nag-aalaga, nagmamahal',
        'description':
            'Si Nanay ang nag-aalaga sa atin at nagluluto ng masarap na pagkain.',
        'note': 'Sa Pilipinas, tinatawag natin ang ina na "Nanay" o "Ina".',
        'audioPath': 'audio/family/ni_nanang.mp3'
      },
      {
        'id': 'family_father',
        'question':
            'Sino ang nagtatrabaho para sa pamilya at mahilig makipaglaro?',
        'choices': ['👩 Nanay', '👨 Tatay', '👧 Ate', '👦 Kuya'],
        'correct': 1,
        'member': 'Tatay',
        'emoji': '👨',
        'roles': 'nagtatrabaho, naglalaro, nagpoprotekta',
        'description':
            'Si Tatay ang nagtatrabaho para sa pamilya at masaya kasama.',
        'note': 'Sa Pilipinas, tinatawag natin ang ama na "Tatay" o "Ama".',
        'audioPath': 'audio/family/si_amang.mp3'
      },
      {
        'id': 'family_brother',
        'question': 'Sino ang Kuya mo?',
        'choices': ['👩 Nanay', '👨 Tatay', '👧 Ate', '👦 Kuya'],
        'correct': 3,
        'member': 'Kuya',
        'emoji': '👦',
        'roles': 'nakatatandang kapatid, kasama, kalaro',
        'description': 'Ang Kuya ay ang nakatatandang kapatid na lalaki.',
        'note':
            'Sa Pilipinas, tinatawag natin ang nakatatandang kapatid na lalaki na "Kuya".',
        'audioPath': 'audio/family/ni_manong.mp3'
      },
      {
        'id': 'family_sister',
        'question': 'Sino ang Ate mo?',
        'choices': ['👩 Nanay', '👨 Tatay', '👧 Ate', '👦 Kuya'],
        'correct': 2,
        'member': 'Ate',
        'emoji': '👧',
        'roles': 'nakatatandang kapatid, tumutulong sa bahay, kalaro',
        'description': 'Ang Ate ay ang nakatatandang kapatid na babae.',
        'note':
            'Sa Pilipinas, tinatawag natin ang nakatatandang kapatid na babae na "Ate".',
        'audioPath': 'audio/family/ni_manang.mp3'
      },
      {
        'id': 'family_youngest',
        'question': 'Sino ang pinakabata sa pamilya?',
        'choices': ['👶 Bunso', '👦 Kuya', '👧 Ate', '👴 Lolo'],
        'correct': 0,
        'member': 'Bunso',
        'emoji': '👶',
        'roles': 'pinakabata, inaalagaan',
        'description': 'Ang Bunso ay ang pinakabata sa pamilya.',
        'note': 'Sa Pilipinas, tinatawag natin ang pinakabata na "Bunso".',
        'audioPath': 'audio/family/ni_bunsoy.mp3'
      },
      {
        'id': 'family_grandfather',
        'question': 'Sino ang ama ng iyong nanay o tatay?',
        'choices': ['👴 Lolo', '👵 Lola', '👨 Tatay', '👩 Nanay'],
        'correct': 0,
        'member': 'Lolo',
        'emoji': '👴',
        'roles': 'nagkukuwento, nagbibigay ng payo',
        'description': 'Ang Lolo ay ang ama ng iyong nanay o tatay.',
        'note': 'Sa Pilipinas, tinatawag natin ang lolo na "Lolo".',
        'audioPath': 'audio/family/ni_lelong.mp3'
      },
      {
        'id': 'family_grandmother',
        'question': 'Sino ang ina ng iyong nanay o tatay?',
        'choices': ['👴 Lolo', '👵 Lola', '👨 Tatay', '👩 Nanay'],
        'correct': 1,
        'member': 'Lola',
        'emoji': '👵',
        'roles': 'nagluluto ng masarap, nagkukuwento',
        'description': 'Ang Lola ay ang ina ng iyong nanay o tatay.',
        'note': 'Sa Pilipinas, tinatawag natin ang lola na "Lola".',
        'audioPath': 'audio/family/ni_leling.mp3'
      },
    ],
    'ilo': [
      {
        'id': 'family_nanay',
        'question': 'Sino ti ag-alagad kenka no aggagar ken nagluto iti makan?',
        'choices': ['👩 Nanang', '👨 Amang', '👧 Manang', '🧑 Manong'],
        'correct': 0,
        'member': 'Nanang',
        'emoji': '👩',
        'roles': 'nagluluto, ag-alagad, naglalambing',
        'description':
            'Si Nanang ti ag-alagad kadatayo ken nagluto iti nasayaat nga makan.',
        'note': 'Iti Ilocos, awagentayo ti ina iti "Nanang" wenno "Inang".',
        'audioPath': 'audio/family/ni_nanang.mp3'
      },
      {
        'id': 'family_amang',
        'question': 'Sino ti nagtatrabaho para iti pamilya ken naimus aglaro?',
        'choices': ['👩 Nanang', '👨 Amang', '👧 Manang', '🧑 Manong'],
        'correct': 1,
        'member': 'Amang',
        'emoji': '👨',
        'roles': 'nagtatrabaho, naglalaro, nagpoprotekta',
        'description':
            'Si Amang ti nagtatrabaho para iti pamilya ken naimus aglaro.',
        'note': 'Iti Ilocos, awagentayo ti ama iti "Amang" wenno "Tatang".',
        'audioPath': 'audio/family/si_amang.mp3'
      },
      {
        'id': 'family_manong',
        'question': 'Sino ti nataengan nga kabsatmo a lalaki?',
        'choices': ['👩 Nanang', '👨 Amang', '👧 Manang', '🧑 Manong'],
        'correct': 3,
        'member': 'Manong',
        'emoji': '🧑',
        'roles': 'nataengan nga kabsat, mangikuyog, kalaro',
        'description': 'Si Manong ti nataengan nga kabsatmo a lalaki.',
        'note': 'Iti Ilocos, awagentayo iti napateg nga kabsat iti "Manong".',
        'audioPath': 'audio/family/ni_manong.mp3'
      },
      {
        'id': 'family_manang',
        'question': 'Sino ti nataengan nga kabsatmo a babai?',
        'choices': ['👩 Nanang', '👨 Amang', '👧 Manang', '🧑 Manong'],
        'correct': 2,
        'member': 'Manang',
        'emoji': '👧',
        'roles': 'nataengan nga kabsat, tumulong iti balay, kaobraobra',
        'description': 'Si Manang ti nataengan nga kabsatmo a babai.',
        'note':
            'Iti Ilocos, awagentayo iti napateg nga kabsat a babai iti "Manang".',
        'audioPath': 'audio/family/ni_manang.mp3'
      },
      {
        'id': 'family_bunso',
        'question': 'Sino ti kaungpus nga miyembro ti pamilya?',
        'choices': ['👶 Kaungpus', '🧑 Manong', '👧 Manang', '👴 Lelong'],
        'correct': 0,
        'member': 'Kaungpus',
        'emoji': '👶',
        'roles': 'kaungpus nga kabsat, inaalagaan',
        'description': 'Ti kaungpus ti kaungpus nga miyembro ti pamilya.',
        'note':
            'Iti Ilocos, awagentayo iti kaungpus nga kabsat iti "Kaungpus" wenno "Bunsoy".',
        'audioPath': 'audio/family/ni_bunsoy.mp3'
      },
      {
        'id': 'family_lelong',
        'question': 'Sino ti ama ni nanang wenno amang?',
        'choices': ['👴 Lelong', '👵 Leling', '👨 Amang', '👩 Nanang'],
        'correct': 0,
        'member': 'Lelong',
        'emoji': '👴',
        'roles': 'Lelong dagiti annaknak, nagkukuwento iti tao',
        'description': 'Si Lelong ti ama ti nanang wenno amang tayo.',
        'note': 'Iti Ilocos, awagentayo ti apo a lalaki iti "Lelong".',
        'audioPath': 'audio/family/ni_lelong.mp3'
      },
      {
        'id': 'family_leling',
        'question': 'Sino ti ina ni nanang wenno amang?',
        'choices': ['👴 Lelong', '👵 Leling', '👨 Amang', '👩 Nanang'],
        'correct': 1,
        'member': 'Leling',
        'emoji': '👵',
        'roles': 'Leling dagiti annaknak, nagluluto iti naimas',
        'description': 'Si Leling ti ina ti nanang wenno amang tayo.',
        'note': 'Iti Ilocos, awagentayo ti apo a babai iti "Leling".',
        'audioPath': 'audio/family/ni_leling.mp3'
      },
    ],
  };

  // ── Pamilya Level 2: Family Roles ────────────────────────────────────
  static List<Map<String, dynamic>> getPamilyaLevel2Games(String lang) {
    return _pamilyaLevel2Games[lang] ?? _pamilyaLevel2Games['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _pamilyaLevel2Games = {
    'en': [
      {
        'id': 'role_cook',
        'question': 'Who usually cooks at home?',
        'choices': [
          'Mother only',
          'Father only',
          'Grandmother only',
          'Anyone can'
        ],
        'correct': 3,
        'explanation': 'Correct! Anyone in the family can cook.'
      },
      {
        'id': 'role_work',
        'question': 'Who works for the family?',
        'choices': [
          'Father only',
          'Mother only',
          'Grandfather only',
          'Many can'
        ],
        'correct': 3,
        'explanation': 'Correct! Many family members can work.'
      },
      {
        'id': 'role_story',
        'question': 'Who usually tells stories?',
        'choices': ['Older Brother', 'Older Sister', 'Grandparents', 'Father'],
        'correct': 2,
        'explanation': 'Correct! Grandparents are the best storytellers.'
      },
      {
        'id': 'role_care',
        'question': 'Who takes care of you when you are sick?',
        'choices': ['Mother', 'Father', 'Grandmother', 'All of them'],
        'correct': 3,
        'explanation': 'Correct! All family members take care of each other.'
      },
      {
        'id': 'role_play',
        'question': 'Who do you play with at home?',
        'choices': [
          'Older Brother',
          'Older Sister',
          'Youngest Sibling',
          'Any sibling'
        ],
        'correct': 3,
        'explanation': 'Correct! You can play with anyone.'
      },
    ],
    'fil': [
      {
        'id': 'role_cook',
        'question': 'Sino ang karaniwang nagluluto sa bahay?',
        'choices': [
          'Nanay lang',
          'Tatay lang',
          'Lola lang',
          'Sinuman ay pwede'
        ],
        'correct': 3,
        'explanation': 'Tama! Sinuman sa pamilya ay pwedeng magluto.'
      },
      {
        'id': 'role_work',
        'question': 'Sino ang nagtatrabaho para sa pamilya?',
        'choices': [
          'Tatay lang',
          'Nanay lang',
          'Lolo lang',
          'Marami ang pwede'
        ],
        'correct': 3,
        'explanation':
            'Tama! Maraming miyembro ng pamilya ang pwedeng magtrabaho.'
      },
      {
        'id': 'role_story',
        'question': 'Sino ang karaniwang nagkukuwento ng mga kuwento?',
        'choices': ['Kuya', 'Ate', 'Lolo at Lola', 'Tatay'],
        'correct': 2,
        'explanation': 'Tama! Ang Lolo at Lola ang pinakamagaling magkuwento.'
      },
      {
        'id': 'role_care',
        'question': 'Sino ang nag-aalaga sa iyo kapag may sakit ka?',
        'choices': ['Nanay', 'Tatay', 'Lola', 'Lahat sila'],
        'correct': 3,
        'explanation':
            'Tama! Lahat ng miyembro ng pamilya ay nag-aalaga sa isa\'t isa.'
      },
      {
        'id': 'role_play',
        'question': 'Sino ang kalaro mo sa bahay?',
        'choices': ['Kuya', 'Ate', 'Bunso', 'Sinumang kapatid'],
        'correct': 3,
        'explanation': 'Tama! Puwede kang makipaglaro kaninuman.'
      },
    ],
    'ilo': [
      {
        'id': 'role_cook',
        'question': 'Sino ti kaslakami nga nagluluto iti balaymi?',
        'choices': [
          'Nanang laeng',
          'Amang laeng',
          'Leling laeng',
          'Mabalin ti aniaman'
        ],
        'correct': 3,
        'explanation': 'Nalinteg! Mabalin ti aniaman iti pamilya ti magluto.'
      },
      {
        'id': 'role_work',
        'question': 'Sino ti nagtatrabaho para iti pamilya?',
        'choices': [
          'Amang laeng',
          'Nanang laeng',
          'Lelong laeng',
          'Mabalin ti adu'
        ],
        'correct': 3,
        'explanation': 'Nalinteg! Mabalin ti adu iti pamilya ti nagtatrabaho.'
      },
      {
        'id': 'role_story',
        'question': 'Sino ti nalablabes a nagkukuwento iti daan?',
        'choices': ['Manong', 'Manang', 'Lelong ken Leling', 'Amang'],
        'correct': 2,
        'explanation':
            'Nalinteg! Dagiti Lelong ken Leling ti kaslakami nga nagkukuwento.'
      },
      {
        'id': 'role_care',
        'question': 'Sino ti ag-alagad kenka no aggagarika?',
        'choices': ['Nanang', 'Amang', 'Leling', 'Amin da'],
        'correct': 3,
        'explanation': 'Nalinteg! Amin nga miyembro ti pamilya ag-alagad.'
      },
      {
        'id': 'role_play',
        'question': 'Sino ti kalarom iti balay?',
        'choices': ['Manong', 'Manang', 'Kaungpus', 'Amin dagiti kabsat'],
        'correct': 3,
        'explanation': 'Nalinteg! Mabalin ka aglaro kadagiti aniaman.'
      },
    ],
  };

  // ── Pamilya Level 3: Family Activities ─────────────────────────────────
  static List<Map<String, dynamic>> getPamilyaLevel3Games(String lang) {
    return _pamilyaLevel3Games[lang] ?? _pamilyaLevel3Games['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _pamilyaLevel3Games = {
    'en': [
      {
        'id': 'activity_dinner',
        'question': 'What is a good thing to do together during meals?',
        'choices': [
          'Eat and talk together',
          'Watch TV',
          'Sleep',
          'Use cellphone'
        ],
        'correct': 0,
        'explanation': 'Correct! Eating together and talking is wonderful.'
      },
      {
        'id': 'activity_weekend',
        'question': 'What can the family do on weekends?',
        'choices': [
          'Relax at the park',
          'Shop at the grocery',
          'Clean together',
          'All of the above'
        ],
        'correct': 3,
        'explanation': 'Correct! All activities done together are wonderful.'
      },
      {
        'id': 'activity_celebration',
        'question': 'What does the family do during birthdays?',
        'choices': [
          'Eat cake',
          'Give gifts',
          'Celebrate together',
          'All of the above'
        ],
        'correct': 3,
        'explanation':
            'Correct! Birthdays are celebrations for the whole family!'
      },
      {
        'id': 'activity_help',
        'question': 'How can you help your family?',
        'choices': [
          'Organize toys',
          'Sweep the floor',
          'Wash dishes',
          'All of the above'
        ],
        'correct': 3,
        'explanation': 'Correct! Helping at home shows love for your family.'
      },
    ],
    'fil': [
      {
        'id': 'activity_dinner',
        'question': 'Ano ang magandang gawin kapag kumakain nang sama-sama?',
        'choices': [
          'Kumain at magkuwentuhan',
          'Manood ng TV',
          'Matulog',
          'Gumamit ng cellphone'
        ],
        'correct': 0,
        'explanation':
            'Tama! Ang pagkain at pagkukuwentuhan nang sama-sama ay masaya.'
      },
      {
        'id': 'activity_weekend',
        'question': 'Ano ang pwedeng gawin ng pamilya tuwing weekend?',
        'choices': [
          'Magpahinga sa parke',
          'Mamili sa grocery',
          'Maglinis nang sama-sama',
          'Lahat ng nabanggit'
        ],
        'correct': 3,
        'explanation': 'Tama! Lahat ng gawain nang sama-sama ay masaya.'
      },
      {
        'id': 'activity_celebration',
        'question': 'Ano ang ginagawa ng pamilya kapag may kaarawan?',
        'choices': [
          'Kumain ng keyk',
          'Magbigay ng regalo',
          'Magdiwang nang sama-sama',
          'Lahat ng nabanggit'
        ],
        'correct': 3,
        'explanation':
            'Tama! Ang kaarawan ay pagdiriwang para sa buong pamilya!'
      },
      {
        'id': 'activity_help',
        'question': 'Paano ka makakatulong sa iyong pamilya?',
        'choices': [
          'Ayusin ang mga laruan',
          'Magwalis',
          'Maghugas ng pinggan',
          'Lahat ng nabanggit'
        ],
        'correct': 3,
        'explanation':
            'Tama! Ang pagtulong sa bahay ay pagpapakita ng pagmamahal sa pamilya.'
      },
    ],
    'ilo': [
      {
        'id': 'activity_dinner',
        'question':
            'Ania ti nasayaat nga aramidem a sangsangkamaysa iti panagannak?',
        'choices': [
          'Kumanen ken agkukuwentuan',
          'Mangar-ay iti TV',
          'Matulog',
          'Ag-cellphone'
        ],
        'correct': 0,
        'explanation':
            'Nalinteg! Naraig ti kumanen a sangsangkamaysa ken magkukuwentuan.'
      },
      {
        'id': 'activity_weekend',
        'question': 'Ania ti mabalin nga aramiden ti pamilya iti weekend?',
        'choices': [
          'Agmanmano iti parke',
          'Agbilibilang iti grocery',
          'Aglinlinis a sangsangkamaysa',
          'Amin dagiti naibaga'
        ],
        'correct': 3,
        'explanation':
            'Nalinteg! Amin nga aramiden a sangsangkamaysa ket naraig.'
      },
      {
        'id': 'activity_celebration',
        'question': 'Ania ti aramidem ti pamilya no adda kasangay?',
        'choices': [
          'Kumanen ti kek',
          'Mangited iti regalo',
          'Selebrasyon a sangsangkamaysa',
          'Amin dagiti naibaga'
        ],
        'correct': 3,
        'explanation':
            'Nalinteg! Ti kasangay ket selebrasyon a sangsangkamaysa!'
      },
      {
        'id': 'activity_help',
        'question': 'Kasano ka makatutulongen iti pamilyam?',
        'choices': [
          'Agurnos iti laruan',
          'Agwaswas',
          'Agurnos iti pinggan',
          'Amin dagiti naibaga'
        ],
        'correct': 3,
        'explanation':
            'Nalinteg! Ti pangtulongen iti balay ket pannakaayat iti pamilya.'
      },
    ],
  };

  // ── Family Tree ────────────────────────────────────────────────────────
  static Map<String, dynamic> getFamilyTreeData(String lang) {
    return _familyTreeData[lang] ?? _familyTreeData['ilo']!;
  }

  static const Map<String, Map<String, dynamic>> _familyTreeData = {
    'en': {
      'generations': [
        {
          'title': 'Grandparents (Lolo and Lola)',
          'color': Color(0xFF9B59B6),
          'members': [
            {'relation': 'Grandfather (father of father)', 'emoji': '👴'},
            {'relation': 'Grandmother (mother of father)', 'emoji': '👵'},
            {'relation': 'Grandfather (father of mother)', 'emoji': '👴'},
            {'relation': 'Grandmother (mother of mother)', 'emoji': '👵'},
          ]
        },
        {
          'title': 'Parents',
          'color': Color(0xFF2980B9),
          'members': [
            {'relation': 'Father', 'emoji': '👨'},
            {'relation': 'Mother', 'emoji': '👩'},
          ]
        },
        {
          'title': 'Siblings',
          'color': Color(0xFF27AE60),
          'members': [
            {'relation': 'Older Brother', 'emoji': '🧑'},
            {'relation': 'Older Sister', 'emoji': '👧'},
            {'relation': 'Youngest Sibling', 'emoji': '👶'},
          ]
        },
      ]
    },
    'fil': {
      'generations': [
        {
          'title': 'Mga Lolo at Lola',
          'color': Color(0xFF9B59B6),
          'members': [
            {'relation': 'Lolo (ama ni Tatay)', 'emoji': '👴'},
            {'relation': 'Lola (ina ni Tatay)', 'emoji': '👵'},
            {'relation': 'Lolo (ama ni Nanay)', 'emoji': '👴'},
            {'relation': 'Lola (ina ni Nanay)', 'emoji': '👵'},
          ]
        },
        {
          'title': 'Mga Magulang',
          'color': Color(0xFF2980B9),
          'members': [
            {'relation': 'Tatay', 'emoji': '👨'},
            {'relation': 'Nanay', 'emoji': '👩'},
          ]
        },
        {
          'title': 'Mga Kapatid',
          'color': Color(0xFF27AE60),
          'members': [
            {'relation': 'Kuya (panganay)', 'emoji': '🧑'},
            {'relation': 'Ate (maikadua)', 'emoji': '👧'},
            {'relation': 'Bunso', 'emoji': '👶'},
          ]
        },
      ]
    },
    'ilo': {
      'generations': [
        {
          'title': 'Dagiti Apo (Lelong ken Leling)',
          'color': Color(0xFF9B59B6),
          'members': [
            {'relation': 'Lelong (ama ni Amang)', 'emoji': '👴'},
            {'relation': 'Leling (ina ni Amang)', 'emoji': '👵'},
            {'relation': 'Lelong (ama ni Nanang)', 'emoji': '👴'},
            {'relation': 'Leling (ina ni Nanang)', 'emoji': '👵'},
          ]
        },
        {
          'title': 'Dagiti Nagannak',
          'color': Color(0xFF2980B9),
          'members': [
            {'relation': 'Amang', 'emoji': '👨'},
            {'relation': 'Nanang', 'emoji': '👩'},
          ]
        },
        {
          'title': 'Dagiti Kabsat',
          'color': Color(0xFF27AE60),
          'members': [
            {'relation': 'Manong (panganay)', 'emoji': '🧑'},
            {'relation': 'Manang (maikadua)', 'emoji': '👧'},
            {'relation': 'Kaungpus', 'emoji': '👶'},
          ]
        },
      ]
    },
  };

  // ── My Home Rooms ──────────────────────────────────────────────────────
  static List<Map<String, dynamic>> getHomeRooms(String lang) {
    return _homeRooms[lang] ?? _homeRooms['ilo']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _homeRooms = {
    'en': [
      {
        'name': 'Living Room',
        'emoji': '🛋️',
        'activity': 'family relaxes and watches TV together',
        'color': Color(0xFFE74C3C)
      },
      {
        'name': 'Kitchen',
        'emoji': '🍳',
        'activity': 'family cooks and eats together',
        'color': Color(0xFFE67E22)
      },
      {
        'name': 'Bedroom',
        'emoji': '🛏️',
        'activity': 'family rests and talks together',
        'color': Color(0xFF3498DB)
      },
      {
        'name': 'Bathroom',
        'emoji': '🚿',
        'activity': 'family bathes and washes up',
        'color': Color(0xFF1ABC9C)
      },
      {
        'name': 'Yard',
        'emoji': '🌿',
        'activity': 'family plays and spends time together',
        'color': Color(0xFF2ECC71)
      },
    ],
    'fil': [
      {
        'name': 'Sala',
        'emoji': '🛋️',
        'activity': 'pamilya ay nagrerelaks at nanonood ng TV',
        'color': Color(0xFFE74C3C)
      },
      {
        'name': 'Kusina',
        'emoji': '🍳',
        'activity': 'pamilya ay nagluluto at kumakain',
        'color': Color(0xFFE67E22)
      },
      {
        'name': 'Kwarto',
        'emoji': '🛏️',
        'activity': 'pamilya ay nagpapahinga at nag-uusap',
        'color': Color(0xFF3498DB)
      },
      {
        'name': 'Banyo',
        'emoji': '🚿',
        'activity': 'pamilya ay naliligo at naghuhugas',
        'color': Color(0xFF1ABC9C)
      },
      {
        'name': 'Bakuran',
        'emoji': '🌿',
        'activity': 'pamilya ay naglalaro at naglilibang',
        'color': Color(0xFF2ECC71)
      },
    ],
    'ilo': [
      {
        'name': 'Sala',
        'emoji': '🛋️',
        'activity': 'agmanmano ken mangar-ay iti TV ti pamilya',
        'color': Color(0xFFE74C3C)
      },
      {
        'name': 'Kusina',
        'emoji': '🍳',
        'activity': 'nagluto ken kumanen ti pamilya',
        'color': Color(0xFFE67E22)
      },
      {
        'name': 'Kuarto',
        'emoji': '🛏️',
        'activity': 'nagatiddog ken nagsarsarita ti pamilya',
        'color': Color(0xFF3498DB)
      },
      {
        'name': 'Banio',
        'emoji': '🚿',
        'activity': 'naligo ken naglinabas ti pamilya',
        'color': Color(0xFF1ABC9C)
      },
      {
        'name': 'Bakir',
        'emoji': '🌿',
        'activity': 'naglalaruan ken nagannak iti pamilya',
        'color': Color(0xFF2ECC71)
      },
    ],
  };

  // ── Pamilya Level 4: Family Tree (Puno ng Pamilya) ────────────────────
  static List<Map<String, dynamic>> getPamilyaLevel4Games(String lang) {
    return _pamilyaLevel4Games[lang] ?? _pamilyaLevel4Games['fil']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _pamilyaLevel4Games = {
    'en': [
      {
        'id': 'tree_1',
        'question': 'Who are the parents of your Father or Mother?',
        'choices': ['Grandfather and Grandmother', 'Uncles and Aunts', 'Siblings', 'Cousins'],
        'correct': 0,
        'explanation': 'Correct! Grandparents are the parents of our parents.'
      },
      {
        'id': 'tree_2',
        'question': 'Who is the youngest sibling in the family?',
        'choices': ['Older Brother', 'Older Sister', 'Baby / Youngest', 'Grandmother'],
        'correct': 2,
        'explanation': 'Correct! The baby or youngest is the youngest member among siblings.'
      },
      {
        'id': 'tree_3',
        'question': 'What do you call an older brother in Tagalog/Filipino?',
        'choices': ['Ate', 'Kuya', 'Bunso', 'Lolo'],
        'correct': 1,
        'explanation': 'Correct! Kuya is the term for an older brother.'
      },
      {
        'id': 'tree_4',
        'question': 'What do you call an older sister in Tagalog/Filipino?',
        'choices': ['Kuya', 'Ate', 'Bunso', 'Lola'],
        'correct': 1,
        'explanation': 'Correct! Ate is the term for an older sister.'
      },
      {
        'id': 'tree_5',
        'question': 'Who guides and takes care of the children at home?',
        'choices': ['Father and Mother', 'Neighbors', 'Strangers', 'Only pets'],
        'correct': 0,
        'explanation': 'Correct! Father and Mother guide and love their children.'
      },
      {
        'id': 'tree_6',
        'question': 'What chart shows family relationships across generations?',
        'choices': ['Family Tree', 'Shopping List', 'Calendar', 'Weather Chart'],
        'correct': 0,
        'explanation': 'Correct! A Family Tree illustrates generations of a family.'
      },
      {
        'id': 'tree_7',
        'question': 'How should family members treat each other?',
        'choices': ['With love and respect', 'With fighting', 'By ignoring each other', 'Shouting'],
        'correct': 0,
        'explanation': 'Correct! Loving and respecting each other makes a happy family.'
      },
    ],
    'fil': [
      {
        'id': 'tree_1',
        'question': 'Sino ang mga magulang ni Tatay o Nanay?',
        'choices': ['Lolo at Lola', 'Tito at Tita', 'Mga Kapatid', 'Mga Pinsan'],
        'correct': 0,
        'explanation': 'Tama! Ang Lolo at Lola ang mga magulang ng ating magulang.'
      },
      {
        'id': 'tree_2',
        'question': 'Sino ang pinakabatang kapatid sa pamilya?',
        'choices': ['Kuya', 'Ate', 'Bunso', 'Lola'],
        'correct': 2,
        'explanation': 'Tama! Ang bunso ang pinakabata sa mga magkakapatid.'
      },
      {
        'id': 'tree_3',
        'question': 'Ano ang tawag sa nakatatandang kapatid na lalaki?',
        'choices': ['Ate', 'Kuya', 'Bunso', 'Lolo'],
        'correct': 1,
        'explanation': 'Tama! Kuya ang tawag sa nakatatandang kapatid na lalaki.'
      },
      {
        'id': 'tree_4',
        'question': 'Ano ang tawag sa nakatatandang kapatid na babae?',
        'choices': ['Kuya', 'Ate', 'Bunso', 'Lola'],
        'correct': 1,
        'explanation': 'Tama! Ate ang tawag sa nakatatandang kapatid na babae.'
      },
      {
        'id': 'tree_5',
        'question': 'Sino ang nag-aaruga at nagmamahal sa mga anak sa tahanan?',
        'choices': ['Tatay at Nanay', 'Mga kapitbahay', 'Mga estranghero', 'Alagang hayop'],
        'correct': 0,
        'explanation': 'Tama! Ang Tatay at Nanay ang nagmamahal at nag-aalaga sa anak.'
      },
      {
        'id': 'tree_6',
        'question': 'Ano ang tawag sa tsart na nagpapakita ng ugnayan ng pamilya?',
        'choices': ['Puno ng Pamilya (Family Tree)', 'Listahan ng Paninda', 'Kalendaryo', 'Orasan'],
        'correct': 0,
        'explanation': 'Tama! Ang Puno ng Pamilya ay nagpapakita ng salinlahi ng pamilya.'
      },
      {
        'id': 'tree_7',
        'question': 'Paano dapat tratuhin ang bawat kasapi ng pamilya?',
        'choices': ['Magmahalan at magrespetuhan', 'Mag-away araw-araw', 'Magdedmahan', 'Magsigawan'],
        'correct': 0,
        'explanation': 'Tama! Ang pagmamahalan at pagrespeto ang pundasyon ng pamilya.'
      },
    ],
    'ilo': [
      {
        'id': 'tree_1',
        'question': 'Sino dagiti nagannak ni Amang wenno Nanang?',
        'choices': ['Lelong ken Leling', 'Tito ken Tita', 'Dagiti Kabsat', 'Dagiti Pinsan'],
        'correct': 0,
        'explanation': 'Nalinteg! Ni Lelong ken Leling dagiti nagannak ti nagannaktayo.'
      },
      {
        'id': 'tree_2',
        'question': 'Sino ti kaungpusan a kabsat iti pamilya?',
        'choices': ['Manong', 'Manang', 'Kaungpus / Bunso', 'Leling'],
        'correct': 2,
        'explanation': 'Nalinteg! Ti kaungpus ket isu ti ubbing iti magkakabsat.'
      },
      {
        'id': 'tree_3',
        'question': 'Ania ti awag iti lakay a kabsat nga kabaatan?',
        'choices': ['Manang', 'Manong', 'Kaungpus', 'Lelong'],
        'correct': 1,
        'explanation': 'Nalinteg! Manong ti awag iti lakay nga kabsat.'
      },
      {
        'id': 'tree_4',
        'question': 'Ania ti awag iti babai a kabsat nga kabaatan?',
        'choices': ['Manong', 'Manang', 'Kaungpus', 'Leling'],
        'correct': 1,
        'explanation': 'Nalinteg! Manang ti awag iti babai nga kabsat.'
      },
      {
        'id': 'tree_5',
        'question': 'Sino ti mag-alagad ken mag-ayat kadagiti ubbing iti balay?',
        'choices': ['Amang ken Nanang', 'Dagiti kabsat ti balay', 'Dagiti ganggannaet', 'Awan'],
        'correct': 0,
        'explanation': 'Nalinteg! Ni Amang ken Nanang ti mag-ayat ken mag-alagad.'
      },
      {
        'id': 'tree_6',
        'question': 'Ania ti tsart a mag-pakita ti ugnayan ti pamilya?',
        'choices': ['Punuan ti Pamilya', 'Lista ti laklako', 'Kalendaryo', 'Orasan'],
        'correct': 0,
        'explanation': 'Nalinteg! Ti Punuan ti Pamilya ket isu ti tsart ti salinlahi.'
      },
      {
        'id': 'tree_7',
        'question': 'Kasano ti pangtrato kadagiti miyembro ti pamilya?',
        'choices': ['Ag-ayatan ken ag-respeto', 'Ag-apa inaldaw', 'Madi nga agsao', 'Ag-pawayway'],
        'correct': 0,
        'explanation': 'Nalinteg! Ti ag-ayatan ken ag-respeto ti mangpainget iti pamilya.'
      },
    ],
  };

  // ── Pamilya Level 5: Our Home (Ang Aming Tahanan) ───────────────────────
  static List<Map<String, dynamic>> getPamilyaLevel5Games(String lang) {
    return _pamilyaLevel5Games[lang] ?? _pamilyaLevel5Games['fil']!;
  }

  static const Map<String, List<Map<String, dynamic>>> _pamilyaLevel5Games = {
    'en': [
      {
        'id': 'home_1',
        'question': 'In which part of the house do we cook and prepare food?',
        'choices': ['Kitchen', 'Bedroom', 'Bathroom', 'Garage'],
        'correct': 0,
        'explanation': 'Correct! The kitchen is where delicious meals are prepared.'
      },
      {
        'id': 'home_2',
        'question': 'In which part of the house do we sleep and rest?',
        'choices': ['Bedroom', 'Kitchen', 'Yard', 'Dining room'],
        'correct': 0,
        'explanation': 'Correct! Bedrooms provide rest and peaceful sleep.'
      },
      {
        'id': 'home_3',
        'question': 'Where does the family gather to talk and watch TV?',
        'choices': ['Living Room (Sala)', 'Bathroom', 'Storage room', 'Kitchen'],
        'correct': 0,
        'explanation': 'Correct! The living room is for family relaxation and gathering.'
      },
      {
        'id': 'home_4',
        'question': 'Where do we take a bath and wash up?',
        'choices': ['Bathroom', 'Living Room', 'Garden', 'Bedroom'],
        'correct': 0,
        'explanation': 'Correct! We maintain hygiene in the bathroom.'
      },
      {
        'id': 'home_5',
        'question': 'Where can children safely play outdoors near home?',
        'choices': ['Yard / Garden', 'Busy road', 'Kitchen stove', 'Roof'],
        'correct': 0,
        'explanation': 'Correct! The yard or garden is safe for outdoor fun.'
      },
      {
        'id': 'home_6',
        'question': 'Why is our home very important to us?',
        'choices': ['It protects and shelters our family with love', 'It is just a store', 'It is noisy', 'No reason'],
        'correct': 0,
        'explanation': 'Correct! Home is our safe haven filled with family love.'
      },
      {
        'id': 'home_7',
        'question': 'How can we help keep our home clean and neat?',
        'choices': ['Help sweep and organize toys', 'Throw trash anywhere', 'Break things', 'Make a mess'],
        'correct': 0,
        'explanation': 'Correct! Helping clean keeps our home comfortable for everyone.'
      },
    ],
    'fil': [
      {
        'id': 'home_1',
        'question': 'Saang bahagi ng tahanan tayo nagluluto at naghahanda ng pagkain?',
        'choices': ['Kusina', 'Kwarto', 'Banyo', 'Garahi'],
        'correct': 0,
        'explanation': 'Tama! Sa kusina inihahanda ang masasarap na pagkain.'
      },
      {
        'id': 'home_2',
        'question': 'Saang bahagi ng tahanan tayo natutulog at nagpapahinga?',
        'choices': ['Kwarto', 'Kusina', 'Bakuran', 'Kainan'],
        'correct': 0,
        'explanation': 'Tama! Sa kwarto tayo nagpapahinga at natutulog.'
      },
      {
        'id': 'home_3',
        'question': 'Saang bahagi ng tahanan nagtitipon ang pamilya para magkuwentuhan at manood?',
        'choices': ['Sala', 'Banyo', 'Bagsakan', 'Kusina'],
        'correct': 0,
        'explanation': 'Tama! Ang sala ang lugar ng pagtitipon ng buong pamilya.'
      },
      {
        'id': 'home_4',
        'question': 'Saang bahagi ng tahanan tayo naliligo at naglilinis ng katawan?',
        'choices': ['Banyo', 'Sala', 'Halamanan', 'Kwarto'],
        'correct': 0,
        'explanation': 'Tama! Sa banyo tayo naliligo para maging malinis.'
      },
      {
        'id': 'home_5',
        'question': 'Saang bahagi ng tahanan pwedeng maglaro nang ligtas sa labas?',
        'choices': ['Bakuran', 'Kalsada', 'Kalan sa kusina', 'Bubong'],
        'correct': 0,
        'explanation': 'Tama! Sa bakuran pwedeng maglaro nang ligtas at presko.'
      },
      {
        'id': 'home_6',
        'question': 'Bakit mahalaga ang ating tahanan?',
        'choices': ['Nagtataguyod ng proteksyon at pagmamahal sa pamilya', 'Tindahan lamang', 'Maingay na lugar', 'Walang dahilan'],
        'correct': 0,
        'explanation': 'Tama! Ang tahanan ay kanlungan ng ating pamilya.'
      },
      {
        'id': 'home_7',
        'question': 'Paano natin mapapanatiling malinis at maayos ang tahanan?',
        'choices': ['Magtulong sa pag-aayos at pagwawalis', 'Magkalat sa sahig', 'Manira ng gamit', 'Iwanan ang laruan sa daan'],
        'correct': 0,
        'explanation': 'Tama! Ang pagtulong sa paglilinis ay nagpapanatili ng ganda ng bahay.'
      },
    ],
    'ilo': [
      {
        'id': 'home_1',
        'question': 'Sadino ti paglutoan ken pag-sagana iti kanen?',
        'choices': ['Kusina', 'Kuarto', 'Banio', 'Garahi'],
        'correct': 0,
        'explanation': 'Nalinteg! Iti kusina ti pagsagana iti kanen.'
      },
      {
        'id': 'home_2',
        'question': 'Sadino ti pag-atiddog ken pag-turog?',
        'choices': ['Kuarto', 'Kusina', 'Bakir', 'Pagan-kanan'],
        'correct': 0,
        'explanation': 'Nalinteg! Iti kuarto ti pagturog ken pagpahingaan.'
      },
      {
        'id': 'home_3',
        'question': 'Sadino ti pagtipunan ti pamilya nga agkukuwentuan ken mangar-ay iti TV?',
        'choices': ['Sala', 'Banio', 'Bodega', 'Kusina'],
        'correct': 0,
        'explanation': 'Nalinteg! Iti sala ti pagtipunan a sangsangkamaysa.'
      },
      {
        'id': 'home_4',
        'question': 'Sadino ti pag-ligoan ken pag-linabas ti bagyo?',
        'choices': ['Banio', 'Sala', 'Halamanan', 'Kuarto'],
        'correct': 0,
        'explanation': 'Nalinteg! Iti banio ti pagligoan tapno nadalus.'
      },
      {
        'id': 'home_5',
        'question': 'Sadino ti mabalin nga pag-laruan a natalged iti balay?',
        'choices': ['Bakir', 'Dalan ti sasakyan', 'Dapogan', 'Bubong'],
        'correct': 0,
        'explanation': 'Nalinteg! Iti bakir ti natalged a paglaruan.'
      },
      {
        'id': 'home_6',
        'question': 'Apay nga napateg ti balaymi?',
        'choices': ['Mangprotekta ken mangted iti ayat iti pamilya', 'Tiendaan laeng', 'Naringgor', 'Awan serserbi'],
        'correct': 0,
        'explanation': 'Nalinteg! Ti balay ket dalan ti proteksyon ken ayat.'
      },
      {
        'id': 'home_7',
        'question': 'Kasano ti pangalagad tapno nadalus ti balaymi?',
        'choices': ['Ag-tulong nga agwalis ken ag-urnos', 'Ag-kalat iti dalan', 'Mangringgor iti gamit', 'Baybay-an ti laruan'],
        'correct': 0,
        'explanation': 'Nalinteg! Ti agtulong nga aglinis ti mangpabaro iti balay.'
      },
    ],
  };
}
