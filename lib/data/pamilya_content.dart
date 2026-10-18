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
        'title': 'Tungkol sa aking Sarili',
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
      {
        'title': 'Maipapan iti Bagik',
        'icon': LucideIcons.user,
        'color': Color(0xFFFF6B6B)
      },
      {
        'title': 'Ti Pamilak',
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
        'Pang-araw-araw na gawain',
        'Aking mga Paborito'
      ],
      [
        'Mga Miyembro ng Pamilya',
        'Tungkulin sa Pamilya',
        'Gawain ng Pamilya',
        'Talaan ng Pamilya',
        'Ang Ating Tahanan'
      ],
    ],
    'ilo': [
      [
        'Maipanggep Kaniak',
        'Toy kaririknak',
        'Inaldaw nga Ar-aramiden',
        'Dagiti Kaykayatko'
      ],
      [
        'Dagiti Miyembro ti Pamilya',
        'Dagiti akem iti pamilia',
        'Aramid ti Pamilia',
        'Puon ti Pamilya',
        'Ti Pagtaengan tayo'
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
        'icon': '👤',
        'description':
            'Your name is what your family and friends call you. It is important!',
      },
      {
        'id': 'about_age',
        'question': 'How old are you?',
        'type': 'age_input',
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
        'description': 'Celebrate your birthday with your family!',
      },
      {
        'id': 'about_home',
        'question': 'Where do you live?',
        'type': 'text_input',
        'icon': '🏠',
        'description':
            'Home is the place where you live with your family. Home sweet home!',
      },
    ],
    'fil': [
      {
        'id': 'about_name',
        'question': 'Ano ang pangalan mo?',
        'type': 'text_input',
        'icon': '👤',
        'description':
            'Ang iyong pangalan ay ang tawag sa iyo ng iyong pamilya at kaibigan. Mahalaga ito.',
      },
      {
        'id': 'about_age',
        'question': 'Ilang taon ka na?',
        'type': 'age_input',
        'icon': '🎂',
        'description':
            'Ang iyong edad ay bilang ng mga taon mula nang ikaw ay ipinanganak. Ipagdiwang ang bawat taon!',
      },
      {
        'id': 'about_gender',
        'question': 'Ikaw ba ay lalaki o babae?',
        'type': 'choice',
        'options': ['👧 Babae', '👦 Lalaki'],
        'values': [0, 1],
        'icon': '👤',
        'description':
            'Ang pag-alam kung ikaw ay lalaki o babae ay nakatutulong upang mas makilala ka namin!',
      },
      {
        'id': 'about_birthday',
        'question': 'Kailan ang iyong kaarawan?',
        'type': 'info',
        'icon': '🎉',
        'description': 'Ipagdiwang ang iyong kaarawan kasama ang pamilya!',
      },
      {
        'id': 'about_home',
        'question': 'Saan ka nakatira?',
        'type': 'text_input',
        'icon': '🏠',
        'description':
            'Ang iyong tahanan ay ang lugar kung saan ka nakatira kasama ang iyong pamilya. Kay sarap sa sariling tahanan!',
      },
    ],
    'ilo': [
      {
        'id': 'about_name',
        'question': 'Ania ti naganmo?',
        'type': 'text_input',
        'icon': '👤',
        'description':
            'Ti naganmo ket ti tawag kenka ti pamiliam ken gagayyemmo. Napateg dayta!',
      },
      {
        'id': 'about_age',
        'question': 'Mano ti tawenmo?',
        'type': 'age_input',
        'icon': '🎂',
        'description':
            'Ti tawenmo ket ti bilang dagiti tawen manipud idi nayanakka. Rambakan ti tunggal tawen!',
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
        'description': 'Rambakan ti pannakayanakmo kadua ti pamiliam.',
      },
      {
        'id': 'about_home',
        'question': 'Sadino ti pagtaengam?',
        'type': 'text_input',
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
        'question': 'When do you feel Happy?',
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
        'question': 'When do you feel Sad?',
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
        'question': 'When do you feel Angry?',
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
        'question': 'When do you feel Surprised?',
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
        'question': 'When do you feel Scared?',
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
        'question': 'Kailan ka nakakaramdam ng Saya?',
        'choices': [
          '🎁 Kapag may regalo o sorpresa',
          '😢 Kapag may taong masama ang pakikitungo',
          '😴 Kapag inaantok'
        ],
        'correct': 0,
        'explanation':
            'Tama! Masaya tayo kapag may magandang nangyayari tulad ng regalo o pagdiriwang.',
        'tip': 'Ngumiti at ibahagi ang iyong kasiyahan sa pamilya!',
      },
      {
        'id': 'emotion_sad',
        'question': 'Kailan ka nakararamdam ng Lungkot?',
        'choices': [
          '🎂 Kapag may masayang selebrasyon ng kaarawan',
          '🧸 Kapag nawala ang paborito mong laruan',
          '🍦 Kapag kumakain ng ice cream'
        ],
        'correct': 1,
        'explanation':
            'Tama! Normal ang malungkot kapag may nawala o may masamang nangyari.',
        'tip': 'Kapag malungkot ka, yakapin ang nanay o tatay mo.',
      },
      {
        'id': 'emotion_angry',
        'question': 'Kailan ka nakararamdam ng Galit?',
        'choices': [
          '🎮 Kapag nanalo sa laro',
          '🧸 Kapag mayroong bagong laruan',
          '👊 Kapag kinuha ang iyong laruan na hindi nagpaalam sa iyo'
        ],
        'correct': 2,
        'explanation':
            'Tama! Nagagalit tayo kapag may hindi patas o masamang nangyari.',
        'tip':
            'Kapag galit ka, huminga nang malalim at bumilang hanggang lima.',
      },
      {
        'id': 'emotion_surprised',
        'question': 'Kailan ka nakararamdam ng Gulat?',
        'choices': [
          '🎁 Kapag mayroong biglaang sorpresa',
          '🍚 Kapag kumakain',
          '😴 Kapag natutulog'
        ],
        'correct': 0,
        'explanation':
            'Tama! Nagugulat tayo kapag may nangyayaring hindi inaasahan.',
        'tip': 'Okay lang mabigla — ang pag-aaral ay isang pakikipagsapalaran!',
      },
      {
        'id': 'emotion_sleepy',
        'question': 'Kailan mo nararamdaman ang antok?',
        'choices': [
          '🌅 Pagkagising sa umaga',
          '🌙 Kapag sumapit na ang gabi',
          '☀️ Kapag naglalaro sa labas'
        ],
        'correct': 1,
        'explanation':
            'Tama! Nakakaramdam tayo ng antok sa gabi dahil oras na para matulog. Matulog nang maaga para ikaw ay lumaking malaki at malakas.',
        'tip':
            'Mahalaga ang pagtulog, nakakatulong upang maging masigla at malakas!',
      },
      {
        'id': 'emotion_scared',
        'question': 'Kailan ka nakakaramdam ng Takot?',
        'choices': [
          '🌈 Kapag nakakakita ng bahaghari',
          '⚡ Kapag may kulog at kidlat',
          '☀️ Kapag maganda ang panahon'
        ],
        'correct': 1,
        'explanation':
            'Tama! Natatakot tayo sa malakas na tunog tulad ng kulog. Kapag natatakot ka, yakapin mo ang iyong nanay o tatay.',
        'tip': 'Kapag takot ka, yakapin ang nanay o tatay mo.',
      },
    ],
    'ilo': [
      {
        'id': 'emotion_happy',
        'question': 'Kaano ka a makarikna ti Ragsak?',
        'choices': [
          '🎁 No adda sagut wenno pagsiddaaw.',
          '😢 No adda tao manatangken',
          '😴 No matmaturog'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Naragsak tayo no adda mapasamak a nasayaat a banag kas iti pannakaawat iti regalo wenno panag rambak.',
        'tip': 'Agisem ka ket ibingaymo ti ragsakmo ti pamiliam.',
      },
      {
        'id': 'emotion_sad',
        'question': 'Kaano ka a makarikna ti Ladingit?',
        'choices': [
          '🎂 No adda padaya iti panagkasangay',
          '🧸 No mapukaw ti kayatam nga ay-ayam',
          '🍦 No mangan ka iti sorbetes'
        ],
        'correct': 1,
        'explanation':
            'Kusto! Kadaywan a maladingitan tayo no adda mapukawtayo wenno no adda dakes a mapasamak.',
        'tip': 'No maladingitan ka, arakupem ni nanangmo wenno tatangmo.',
      },
      {
        'id': 'emotion_angry',
        'question': 'Kaano ka a makarikna ti Unget?',
        'choices': [
          '🎮 No mangabak ka iti ay-ayam',
          '🧸 No maaddaanka iti baro nga ay-ayam',
          '👊 No adda nangala iti ay-ayam mo nga awan to pakada na'
        ],
        'correct': 2,
        'explanation':
            'Kusto! Agpungtot tayo no adda saan a nainkalintegan wenno di umno a mapasamak.',
        'tip':
            'No agpungtot ka, aganges iti nauneg ken bilangen agingga ti lima.',
      },
      {
        'id': 'emotion_surprised',
        'question': 'Kaano ka a makarikna ti Nasdaaw?',
        'choices': [
          '🎁 No adda saan a namnamaen a sorpresa',
          '🍚 No mangmangan',
          '😴 No matmaturog'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Masdaaw tayo no adda saan a namnamaen a mapasamak.',
        'tip':
            'Nasayaat laeng ti masdaaw - ti panagadal ket maysa nga adbentura!',
      },
      {
        'id': 'emotion_sleepy',
        'question': 'Kaano ka a makaturog?',
        'choices': [
          '🌅 No ti bigbigat kalpasan ti panagriing',
          '🌙 No rabiin',
          '☀️ No agay-ayam iti ruar'
        ],
        'correct': 1,
        'explanation':
            'Kusto! Marikna tayo ti makaturog iti rabii gapu ta orasen ti panagturog.',
        'tip': 'Agidda ka a nasapa tapno dumakkel ka a napigsa!',
      },
      {
        'id': 'emotion_scared',
        'question': 'Kaano ka a makarikna ti Buteng?',
        'choices': [
          '🌈 No adda bullalayaw',
          '⚡ No adda kimat ken gurruud',
          '☀️ Iti aldaw a makasilaw ti init'
        ],
        'correct': 1,
        'explanation':
            'Kusto! Mabutengtayo kadagiti napigsa nga uni a kas ti gur-ruod.',
        'tip': 'No mabuteng ka, arakupem ni nanangmo wenno tatangmo.',
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
        'tip': 'A good morning routine helps you have a great day!',
      },
      {
        'id': 'routine_afternoon',
        'question': 'What do you do in the afternoon',
        'choices': [
          '📚 Study or play',
          '🍚 Eat lunch',
          '😴 Sleep the whole afternoon'
        ],
        'correct': 0,
        'explanation': 'Correct! In the afternoon, we study or play.',
        'tip': 'A good day has time for learning and fun',
      },
      {
        'id': 'routine_evening',
        'question': 'what do you do before Bedtime',
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
        'question': 'How can you stay healthy and avoid getting sick?',
        'choices': [
          '🧼 Wash your hands',
          '🪥 Just brush teeth',
          '💧 Drink water'
        ],
        'correct': 0,
        'explanation': 'Correct! Washing your hands prevents sickness.',
        'tip':
            'Remember to wash your hands before eating and after using the bathroom!',
      },
    ],
    'fil': [
      {
        'id': 'routine_morning',
        'question': 'Ano ang una mong ginagawa pagkagising sa umaga?',
        'choices': [
          '🛏️ Gumising at bumangon sa iyong higaan',
          '🍳 Kumain ng almusal',
          '📺 Manood ng TV'
        ],
        'correct': 0,
        'explanation':
            'Tama! Una tayong bumangon at tumayo sa kama bago gumawa ng iba.',
        'tip': 'Gumising nang maaga upang maging handa para sa buong araw!',
      },
      {
        'id': 'routine_afternoon',
        'question': 'Ano ang karaniwang ginagawa mo sa hapon?',
        'choices': [
          '📚 Nag-aaral o naglalaro',
          '🍚 Kumain ng tanghalian',
          '😴 Matulog buong hapon'
        ],
        'correct': 0,
        'explanation': 'Tama! Sa hapon, nag-aaral tayo o naglalaro.',
        'tip': 'Balansehin ang iyong oras sa pag-aaral at paglalaro!',
      },
      {
        'id': 'routine_evening',
        'question': 'Ano ang iyong ginagawa bago matulog?',
        'choices': [
          '🪥 Magsipilyo ng ngipin',
          '🍪 Magmeryenda',
          '📱 Maglaro sa cellphone'
        ],
        'correct': 0,
        'explanation':
            'Tama! Mahalaga ang magsepilyo bago matulog para maprotektahan ang ngipin.',
        'tip': 'Kapag malinis ang ngipin, walang sakit ng ngipin.',
      },
      {
        'id': 'routine_hygiene',
        'question': 'Ano ang ginagawa mo upang makaiwas sa sakit?',
        'choices': [
          '🧼 Ugaliing maghugas ng kamay',
          '🪥 Sapat na ang magsipilyo ng ngipin',
          '💧 Uminom ng tubig'
        ],
        'correct': 0,
        'explanation': 'Tama! Ang paghuhugas ng kamay ay iwas-sakit.',
        'tip':
            'Ugaliing hugasan ang iyong kamay bago kumain at pagkatapos gumamit ng banyo.',
      },
    ],
    'ilo': [
      {
        'id': 'routine_morning',
        'question':
            'Ania ti umuna nga aramidem no BIGBIGAT kalpasan ti panagtilmon?',
        'choices': [
          '🛏️ Bumangon ken pumanaw iti katre',
          '🍳 Mangan iti pammigat',
          '📺 Agbuya ti TV'
        ],
        'correct': 0,
        'explanation':
            'Nalinteg! Umuna nga agtilmon ken agbangon sakbay ti sabali nga gapuanan.',
        'tip':
            'Ti nasayaat a ar-aramiden iti agsapa ket makatulong tapno nasayaat ti aldawmo.',
      },
      {
        'id': 'routine_afternoon',
        'question': 'Ania ti aramidem iti malem',
        'choices': [
          '📚 Agadal wenno agay-ayam',
          '🍚 Mangan ti pangaldaw',
          '😴 Maturog iti intero a malem'
        ],
        'correct': 0,
        'explanation': 'Kusto! Iti malem, agadal tayo wenno agay-ayam.',
        'tip':
            'Ti nasayaat nga aldaw ket addaan iti panawen para iti panagadal ken panagragragsak',
      },
      {
        'id': 'routine_evening',
        'question': 'Ania ti ar-aramidem sakbay ti PANAGTUROG?',
        'choices': [
          '🪥 Agsepilio iti ngipen',
          '🍪 Mangan ti merienda',
          '📱 Agay-ayam iti cellphone'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Napateg ti panagsepilio sakbay ti panagturog tapno maprotektaran ti ngipen.',
        'tip': 'Ti nadalus a ngipen kayatna a sawen awan ti ut-ot ti ngipen.',
      },
      {
        'id': 'routine_hygiene',
        'question':
            'Kasano a mataginayonmo ti salun-atmo ken maliklikan ti panagsakit?',
        'choices': [
          '🧼 Ugasam dagiti imam',
          '🪥 Agsepilio laeng iti ngipen',
          '💧 Uminom iti danum'
        ],
        'correct': 0,
        'explanation': 'Nalinteg! Ti panaghugas iti ima ket iwas sakit.',
        'tip':
            'Ugasam dagiti imam sakbay a mangan ken kalpasan nga agusar iti banio!',
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
        'question': 'Which food do you like best?',
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
        'question': 'Which game do you like best?',
        'options': ['🪀 Hopscotch', '🏃 Tag', '🧩 Puzzle', '🎯 Ring Toss'],
        'emojis': ['🪀', '🏃', '🧩', '🎯'],
        'description': 'Fun games to play with friends!',
      },
      {
        'id': 'preference_animal',
        'question': 'Which animal is your favorite?',
        'options': ['🐶 Dog', '🐱 Cat', '🐓 Chicken', '🐃 Carabao'],
        'emojis': ['🐶', '🐱', '🐓', '🐃'],
        'description': 'Pick your favorite animal!',
      },
    ],
    'fil': [
      {
        'id': 'preference_food',
        'question': 'Ano ang iyong paboritong pagkain?',
        'options': ['🍚 Kanin', '🐟 Isda', '🍛 Ginisang Gulay', '🍖 Karne'],
        'emojis': ['🍚', '🐟', '🍛', '🍖'],
        'description': 'Piliin ang iyong paboritong pagkain!',
      },
      {
        'id': 'preference_color',
        'question': 'Ano ang iyong paboritong kulay?',
        'options': ['🔴 Pula', '🔵 Asul', '🟢 Berde', '🟡 Dilaw'],
        'emojis': ['🔴', '🔵', '🟢', '🟡'],
        'description': 'Piliin ang iyong paboritong kulay!',
      },
      {
        'id': 'preference_game',
        'question': 'Ano ang paborito mong laro?',
        'options': [
          '🪀 Piko',
          '🏃 Taguan',
          '🧩 Jigsaw puzzle',
          '🎯 Tumbang Preso'
        ],
        'emojis': ['🪀', '🏃', '🧩', '🎯'],
        'description': 'Mga masasayang laro kasama ang mga kaibigan!',
      },
      {
        'id': 'preference_animal',
        'question': 'Ano ang paborito mong hayop?',
        'options': ['🐶 Aso', '🐱 Pusa', '🐓 Manok', '🐃 Kalabaw'],
        'emojis': ['🐶', '🐱', '🐓', '🐃'],
        'description': 'Piliin ang iyong paboritong hayop!',
      },
    ],
    'ilo': [
      {
        'id': 'preference_food',
        'question': 'Ania ti makan a kayat mo unay?',
        'options': ['🍚 Innapoy', '🐟 Ikan', '🍛 Nilaga', '🍖 Karne'],
        'emojis': ['🍚', '🐟', '🍛', '🍖'],
        'description': 'Pilien ti kayatam a Taraon!',
      },
      {
        'id': 'preference_color',
        'question': 'Ania ti kayatam nga MARIS?',
        'options': ['🔴 Nalabbaga', '🔵 Asul', '🟢 Berde', '🟡 Duyaw'],
        'emojis': ['🔴', '🔵', '🟢', '🟡'],
        'description': 'Pumili ka iti kayatam nga maris!',
      },
      {
        'id': 'preference_game',
        'question': 'Ania ti ay-ayam a kayat mo unay?',
        'options': [
          '🪀 Piko',
          '🏃 Habulan',
          '🧩 Palaisipan',
          '🎯 Panag-ay-ayyam iti darts'
        ],
        'emojis': ['🪀', '🏃', '🧩', '🎯'],
        'description': 'Naragsak nga ay-ayam a maay-ayam kadagiti gagayyemmo!',
      },
      {
        'id': 'preference_animal',
        'question': 'Ania ti kayatam nga ayup?',
        'options': ['🐶 Aso', '🐱 Pusa', '🐓 Manok', '🐃 Nuang'],
        'emojis': ['🐶', '🐱', '🐓', '🐃'],
        'description': 'Pumili iti kayatam nga ayup!',
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
        'question': 'Who takes care of you and makes you feel loved?',
        'choices': ['👩 Mother', '👨 Father', '👧 Sister', '👦 Brother'],
        'correct': 0,
        'member': 'Mother',
        'emoji': '👩',
        'roles': 'cooking, caring, loving',
        'description': 'Mother takes care of us and cooks delicious food.',
        'note': 'In Filipino, we call mother "Nanay" or "Ina".',
        'popup':
            'A mother takes care of you, helps you and loves you everyday. in Filipino we call her "Nanay" or "Ina"',
        'audioPath': 'audio/family/ni_nanang.mp3'
      },
      {
        'id': 'family_father',
        'question': 'Who works to help your family and loves to play with you',
        'choices': ['👩 Mother', '👨 Father', '👧 Sister', '👦 Brother'],
        'correct': 1,
        'member': 'Father',
        'emoji': '👨',
        'roles': 'working, playing, protecting',
        'description': 'Father works for the family and is fun to play with.',
        'note': 'In Filipino, we call father "Tatay" or "Ama".',
        'popup':
            'A father works, cares for his family, keeps you safe and loves to spend tie with you. In Filipino, we call him"Tatay" or "Ama".',
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
        'popup':
            'An older Brother plays with you, helps you, and looks out for you. In Filipino, we call him "kuya"',
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
        'popup':
            'An older sister helps at home, plays with you and care for you. In Filipino, we call her "Ate".',
        'audioPath': 'audio/family/ni_manang.mp3'
      },
      {
        'id': 'family_youngest',
        'question': 'Who is the youngest in the family?',
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
        'popup':
            'The youngest sibling are loved and cared for by the family. In Filipino, we call them "Bunso".',
        'audioPath': 'audio/family/ni_bunsoy.mp3'
      },
      {
        'id': 'family_grandfather',
        'question': 'Who is the father of your mom or dad',
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
        'popup':
            'A Grandfather is a storyteller gives advice, and loves spending time with his Family. In Filipino, we call him "Lolo".',
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
        'popup':
            'A grandmother cooks delicious food, tells stories and loves spending time with her family. In Filipino, we call her "Lola".',
        'audioPath': 'audio/family/ni_leling.mp3'
      },
    ],
    'fil': [
      {
        'id': 'family_mother',
        'question':
            'Sino ang nag-aalaga sa iyo, nagluluto ng pagkain at nagpaparamdam ng pagmamahal?',
        'choices': ['👩 Ina', '👨 Ama', '👧 Ate', '👦 Kuya'],
        'correct': 0,
        'member': 'Ina',
        'emoji': '👩',
        'roles': 'nagluluto, nag-aalaga, nagmamahal',
        'description':
            'Si Nanay ang nag-aalaga sa atin at nagluluto ng masarap na pagkain.',
        'note': 'Sa Pilipinas, tinatawag natin ang ina na "Nanay" o "Ina".',
        'popup':
            'Ang Ina ay nagluluto, nag-aalaga at nagmamahal. Sa Filipino, ang tawag natin sa mother ay "Nanay" o "Ina".',
        'audioPath': 'audio/family/ni_nanang.mp3'
      },
      {
        'id': 'family_father',
        'question':
            'Sino ang nagtatrabaho para sa pamilya at masayang nakikipaglaro sa iyo?',
        'choices': ['👩 Ina', '👨 Ama', '👧 Ate', '👦 Kuya'],
        'correct': 1,
        'member': 'Ama',
        'emoji': '👨',
        'roles': 'nagtatrabaho, naglalaro, nagpoprotekta',
        'description':
            'Si Tatay ang nagtatrabaho para sa pamilya at masaya kasama.',
        'note': 'Sa Pilipinas, tinatawag natin ang ama na "Tatay" o "Ama".',
        'popup':
            'Ang Ama ang nagtatrabaho, nakikipaglaro at nagpoprotekta. Sa Filipino, ang tawag natin sa father ay "Tatay" o "Ama".',
        'audioPath': 'audio/family/si_amang.mp3'
      },
      {
        'id': 'family_brother',
        'question': 'Sino ang Kuya mo?',
        'choices': ['👩 Ina', '👨 Ama', '👧 Ate', '👦 Kuya'],
        'correct': 3,
        'member': 'Kuya',
        'emoji': '👦',
        'roles': 'nakatatandang kapatid, kasama, kalaro',
        'description': 'Ang Kuya ay ang nakatatandang kapatid na lalaki.',
        'note':
            'Sa Pilipinas, tinatawag natin ang nakatatandang kapatid na lalaki na "Kuya".',
        'popup':
            'Ang nakatatandang kapatid na lalaki ay kasama at kalaro mo. Sa Filipino, ang tawag natin sa older brother ay "Kuya".',
        'audioPath': 'audio/family/ni_manong.mp3'
      },
      {
        'id': 'family_sister',
        'question': 'Sino ang iyong nakakatandang kapatid na babae?',
        'choices': ['👩 Ina', '👨 Ama', '👧 Ate', '👦 Kuya'],
        'correct': 2,
        'member': 'Ate',
        'emoji': '👧',
        'roles': 'nakatatandang kapatid, tumutulong sa bahay, kalaro',
        'description': 'Ang Ate ay ang nakatatandang kapatid na babae.',
        'note':
            'Sa Pilipinas, tinatawag natin ang nakatatandang kapatid na babae na "Ate".',
        'popup':
            'Ang nakatatandang kapatid na babae ay tumutulong sa bahay at kalaro. Sa Filipino, ang tawag natin sa older sister ay "Ate".',
        'audioPath': 'audio/family/ni_manang.mp3'
      },
      {
        'id': 'family_youngest',
        'question': 'Sino ang pinakabatang kasapi ng pamilya?',
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
        'question': 'Sino ang ama ng iyong ina o ama?',
        'choices': ['👴 Lolo', '👵 Lola', '👨 Ama', '👩 Ina'],
        'correct': 0,
        'member': 'Lolo',
        'emoji': '👴',
        'roles': 'nagkukuwento, nagbibigay ng payo',
        'description': 'Ang Lolo ay ang ama ng iyong nanay o tatay.',
        'note': 'Sa Pilipinas, tinatawag natin ang lolo na "Lolo".',
        'popup':
            'Ang Lolo ay nagkukuwento at nagbibigay ng payo. Sa Filipino, ang tawag natin sa grandfather ay "Lolo".',
        'audioPath': 'audio/family/ni_lelong.mp3'
      },
      {
        'id': 'family_grandmother',
        'question': 'Sino ang ina ng iyong ina o ama?',
        'choices': ['👴 Lolo', '👵 Lola', '👨 Ama', '👩 Ina'],
        'correct': 1,
        'member': 'Lola',
        'emoji': '👵',
        'roles': 'nagluluto ng masarap, nagkukuwento',
        'description': 'Ang Lola ay ang ina ng iyong nanay o tatay.',
        'note': 'Sa Pilipinas, tinatawag natin ang lola na "Lola".',
        'popup':
            'Ang Lola ay nagluluto ng masarap na pagkain at nagkukuwento. Sa Filipino, ang tawag natin sa grandmother ay "Lola".',
        'audioPath': 'audio/family/ni_leling.mp3'
      },
    ],
    'ilo': [
      {
        'id': 'family_nanay',
        'question':
            'Siasino ti mangay-aywan kenka ken mangiparikna kenka nga ayat-ayatendaka?',
        'choices': [
          '👩 Nanang',
          '👨 Tatang',
          '👧 Kabsat a babai',
          '🧑 Kabsat a lalaki'
        ],
        'correct': 0,
        'member': 'Nanang',
        'emoji': '👩',
        'roles': 'agluto, panangaywan, panagayat',
        'description':
            'Aywanannakami ni Nanang ken agluto iti naimas a taraon.',
        'note': 'Iti Filipino, awagantayo ti nanang iti "Nanay" wenno "Ina".',
        'popup':
            'Ti nanang ket mangtaripato kenka, tumulong kenka, ken ay-ayatenna ka iti tunggal aldaw. Iti Filipino, awagantayo isuna iti “Nanay” wenno “Ina.”',
        'audioPath': 'audio/family/ni_nanang.mp3'
      },
      {
        'id': 'family_amang',
        'question':
            'Siasino ti agtartrabaho a tumulong iti pamiliam ken pagay-ayatna ti makiay-ayam kenka',
        'choices': [
          '👩 Nanang',
          '👨 Tatang',
          '👧 Kabsat a babai',
          '🧑 Kabsat a lalaki'
        ],
        'correct': 1,
        'member': 'Tatang',
        'emoji': '👨',
        'roles': 'agtrabaho, agpaspasnek, agtalinaed',
        'description':
            'Agtartrabaho ni Tatang para iti pamilia ken makaparagsak nga kaay-ayam.',
        'note': 'Iti Filipino, awagantayo ti tatang iti “Tatay” wenno “Ama.”',
        'popup':
            'Agtrabaho ti tatang, aywananna ti pamiliana, pagtalinaedennaka a natalged ken pagay-ayatna ti mangbusbos iti singgalut kenka. Iti Filipino, awagantayo isuna iti "Tatay" wenno "Ama".',
        'audioPath': 'audio/family/si_amang.mp3'
      },
      {
        'id': 'family_manong',
        'question': 'Sinno ti inauna nga kabsatmo a lalaki?',
        'choices': [
          '👩 Nanang',
          '👨 Tatang',
          '👧 Kabsat a babai',
          '🧑 Kabsat a lalaki'
        ],
        'correct': 3,
        'member': 'Manong',
        'emoji': '🧑',
        'roles': 'inauna nga kabsat, mangikuyog, kaduak nga agay-ayam',
        'description':
            'Ti inauna a kabsatmo a lalaki ket isu ti kabsatmo a lalaki a nataengan ngem sika.',
        'note':
            'Iti Filipino, awagantayo iti inauna a kabsat a lalaki iti “Kuya.”',
        'popup':
            'Ti inauna a kabsat a lalaki ket makiay-ayam kenka, tulongannaka, ken aywanannaka. Iti Filipino, awagantayo isuna iti "kuya".',
        'audioPath': 'audio/family/ni_manong.mp3'
      },
      {
        'id': 'family_manang',
        'question': 'Sinno ti inauna nga kabsatmo a babai?',
        'choices': [
          '👩 Nanang',
          '👨 Tatang',
          '👧 Kabsat a babai',
          '🧑 Kabsat a lalaki'
        ],
        'correct': 2,
        'member': 'Manang',
        'emoji': '👧',
        'roles':
            'inauna a kabsat, tumulong iti balay, ken kaduam nga agay-ayam.',
        'description': 'Ni Manang ti inauna nga kabsatmo a babai.',
        'note':
            'Iti Filipino, awagantayo iti inauna a kabsat a babai iti “Ate.”',
        'popup':
            'Ti inauna a kabsat a babai ket tumulong iti pagtaengan, makiay-ayam kenka, ken mangaywan kenka. Iti Filipino, awagantayo isuna iti “Ate.”',
        'audioPath': 'audio/family/ni_manang.mp3'
      },
      {
        'id': 'family_bunso',
        'question': 'Sinno ti kaudian nga anak iti pamilia?',
        'choices': [
          '👶 Inaudi',
          '🧑 Kabsat a lalaki',
          '👧 Kabsat a babai',
          '👴 Lilong'
        ],
        'correct': 0,
        'member': 'Inaudi',
        'emoji': '👶',
        'roles': 'Ti kaudian a kabsat, aywanan.',
        'description': 'Ti inaudi ti kaubingan a kameng ti pamilia.',
        'note':
            'Iti Filipino, awagantayo isuna ti inaudi a kabsat iti "Bunso".',
        'popup':
            'Ti inaudi a kabsat ket ay-ayaten ken ay-aywanan ti pamilia. Iti Filipino, awagantayo ida iti "Bunso".',
        'audioPath': 'audio/family/ni_bunsoy.mp3'
      },
      {
        'id': 'family_lelong',
        'question': 'Sinno ti tatang ni nanangmo wenno tatangmo?',
        'choices': ['👴 Lilong', '👵 Lilang', '👨 Tatang', '👩 Nanang'],
        'correct': 0,
        'member': 'Lilong',
        'emoji': '👴',
        'roles': 'agsarsarita ken mangted iti balakad',
        'description': 'Ti lilong ket tatang ti nanangmo wenno tatangmo.',
        'note': 'Iti Filipino, awagantayo iti lilong a “Lolo.”',
        'popup':
            'Ti Lilong ket agsarsarita, mangted iti balakad, ken ay-ayatenna ti makipaglaok kadagiti kameng ti pamiliana. Iti Filipino, awagantayo isuna iti “Lolo.”',
        'audioPath': 'audio/family/ni_lelong.mp3'
      },
      {
        'id': 'family_leling',
        'question': 'Sinno ti nanang ni nanangmo wenno tatangmo?',
        'choices': ['👴 Lilong', '👵 Lilang', '👨 Tatang', '👩 Nanang'],
        'correct': 1,
        'member': 'Lilang',
        'emoji': '👵',
        'roles': 'Agluto iti naimas a taraon ken agsarsarita.',
        'description': 'Ni Lilang ti Ina ni nanang wenno tatang tayo,',
        'note': 'Iti Filipino, awagantayo ni lilang iti "Lola".',
        'popup':
            'Ti Lilang ket agluto iti naimas a taraon, mangibaga kadagiti sarsarita. Iti Filipino, awagantayo isuna iti "Lola"',
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
          'Sister/Brother'
        ],
        'correct': 3,
        'explanation': 'Correct! Anyone in the family can cook.'
      },
      {
        'id': 'role_work',
        'question': 'Who works to help support the family?',
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
          'Ina lamang',
          'Ama lamang',
          'Lola lamang',
          'Kahit sino ay pwede'
        ],
        'correct': 3,
        'explanation': 'Tama! Kahit sino sa pamilya ay pwedeng magluto.'
      },
      {
        'id': 'role_work',
        'question': 'Sino ang nagtatrabaho para sa pamilya?',
        'choices': [
          'Ama lamang',
          'Ina lamang',
          'Lolo lamang',
          'Marami ang pwedeng magtrabaho.'
        ],
        'correct': 3,
        'explanation':
            'Tama! Maraming kasapi ng pamilya ang pwedeng magtrabaho.'
      },
      {
        'id': 'role_story',
        'question': 'Sino ang karaniwang nagkukwento?',
        'choices': ['Kuya', 'Ate', 'Mga ninuno (Mga Lolo at Lola)', 'Ama'],
        'correct': 2,
        'explanation':
            'Tama! Ang mga Lolo at Lola ang pinakamagaling magkuwento.'
      },
      {
        'id': 'role_care',
        'question': 'Sino ang nag-aalaga sa iyo sa tuwing nilalagnat ka?',
        'choices': ['Ina', 'Ama', 'Lola', 'Lahat ng nabanggit'],
        'correct': 3,
        'explanation':
            'Tama! Bawat kasapi ng pamilya ay nag-aalaga sa isa\'t isa.'
      },
      {
        'id': 'role_play',
        'question': 'Sino ang kalaro mo sa bahay?',
        'choices': ['Kuya', 'Ate', 'Bunso', 'Kahit sinong kapatid'],
        'correct': 3,
        'explanation': 'Tama! Maaari kang makipaglaro sa kahit kanino.'
      },
    ],
    'ilo': [
      {
        'id': 'role_cook',
        'question': 'Sinno ti kanayon nga agluto iti balay?',
        'choices': [
          'Nanang laeng',
          'Tatang laeng',
          'Lilang laeng',
          'Manang/Manong'
        ],
        'correct': 3,
        'explanation': 'Kusto! Siasinoman iti pamilia ket mabalin nga agluto'
      },
      {
        'id': 'role_work',
        'question':
            'Siasino ti agtartrabaho a tumulong a mangsuporta iti pamilia?',
        'choices': [
          'Tatang laeng',
          'Nanang laeng',
          'Lilong laeng',
          'Adu ti mabalin'
        ],
        'correct': 3,
        'explanation':
            'Kusto! Adu a kameng ti Pamilia ti mabalin nga agtrabaho.'
      },
      {
        'id': 'role_story',
        'question': 'Sinno ti kanayon nga agisal salaysay?',
        'choices': ['Manong', 'Manang', 'Lilong ken Lilang', 'Tatang'],
        'correct': 2,
        'explanation': 'Kusto! Dagiti apong ti kasasayaatan a mangisalsalaysay.'
      },
      {
        'id': 'role_care',
        'question': 'Sinno ti mangaywan kenka no masakit ka?',
        'choices': ['Nanang', 'Tatang', 'Lilang', 'Amin kadakuada'],
        'correct': 3,
        'explanation': 'Kusto! Amin a kameng ti pamilia ket ag iin-naywanda.'
      },
      {
        'id': 'role_play',
        'question': 'Sinno ti kaay-ayammo iti balay?',
        'choices': ['Manong', 'Manang', 'Inaudi', 'Aniaman a kabsat'],
        'correct': 3,
        'explanation': 'Kusto! Mabalinmo nga kaay-ayam ti siasinoman'
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
        'question': 'What can you do together during meals?',
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
        'question': 'Ano ang magandang gawin nang sama-sama habang kumakain?',
        'choices': [
          'Kumain at mag-usap nang sama-sama',
          'Manood ng TV',
          'Matulog',
          'Gumamit ng cellphone'
        ],
        'correct': 0,
        'explanation': 'Tama! Napakagandang kumain at mag-usap nang sama-sama.'
      },
      {
        'id': 'activity_weekend',
        'question': 'Ano ang pwedeng gawin ng pamilya tuwing Sabado at Linggo?',
        'choices': [
          'Magpahinga sa parke',
          'Mag-grocery sa pamilihan',
          'Maglinis nang sama-sama',
          'Lahat ng nabanggit'
        ],
        'correct': 3,
        'explanation': 'Tama! Napakasayang gawin ang lahat nang sama-sama.'
      },
      {
        'id': 'activity_celebration',
        'question': 'Ano ang ginagawa ng pamilya tuwing kaarawan?',
        'choices': [
          'Kumain ng keyk',
          'Magbigay ng regalo',
          'Magdiwang nang sama-sama',
          'Lahat ng nabanggit'
        ],
        'correct': 3,
        'explanation': 'Tama! Ang mga kaarawan ay pagdiriwang ng buong pamilya!'
      },
      {
        'id': 'activity_help',
        'question': 'Paano ka makakatulong sa iyong pamilya?',
        'choices': [
          'Ayusin ang mga laruan',
          'Magwalis ng sahig',
          'Maghugas ng pinggan',
          'Lahat ng nabanggit'
        ],
        'correct': 3,
        'explanation':
            'Tama! Ang pagtulong sa gawaing bahay ay tanda ng pagmamahal sa pamilya.'
      },
    ],
    'ilo': [
      {
        'id': 'activity_dinner',
        'question':
            'Ania ti mabalinyo nga aramiden a sangsangkamaysa bayat ti pannangan?',
        'choices': [
          'Mangan ken ag sarita a ag kakadwa',
          'Agbuya ti TV',
          'Maturog',
          'Agusar ti cellphone'
        ],
        'correct': 0,
        'explanation': 'Kusto! Nasayaat ti mangan ken ag sarita a ag kakadwa'
      },
      {
        'id': 'activity_weekend',
        'question':
            'Ania ti mabalin nga aramiden ti pamilia kadagiti Sabado ken Domingo?',
        'choices': [
          'Aginana iti parke',
          'Aggatang idiay tiendaan',
          'Agdalus a agkakadua',
          'Amin kadagitoy'
        ],
        'correct': 3,
        'explanation':
            'Kusto! Nagsayaat amin nga ar-aramiden a maaramid a ag kakadua'
      },
      {
        'id': 'activity_celebration',
        'question': 'Ania ti ar-aramiden ti pamilia kadagiti panagkasangay?',
        'choices': [
          'Mangan ti kek',
          'Mangted iti regalo',
          'Agrambak a agkakadua',
          'Amin kadagitoy'
        ],
        'correct': 3,
        'explanation':
            'Kusto! Dagiti panagkasangay ket rambak para iti intero a pamilia!'
      },
      {
        'id': 'activity_help',
        'question': 'Kasano a matulongam ti pamiliam?',
        'choices': [
          'Urnosen dagiti ay-ayam',
          'Agpunas iti datar',
          'Ugasan dagiti pinggan',
          'Amin kadagitoy'
        ],
        'correct': 3,
        'explanation':
            'Kusto! Ti panangtulong iti pagtaengan ket mangipakita iti ayatmo para iti pamiliam.'
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
          'title': 'Mga ninuno (Mga Lolo at Lola)',
          'color': Color(0xFF9B59B6),
          'members': [
            {'relation': 'Lolo (ama ng iyong ama)', 'emoji': '👴'},
            {'relation': 'Lola (ina ng iyong ama)', 'emoji': '👵'},
            {'relation': 'Lolo (ama ng iyong ina)', 'emoji': '👴'},
            {'relation': 'Lola (ina ng iyong ina)', 'emoji': '👵'},
          ]
        },
        {
          'title': 'Magulang',
          'color': Color(0xFF2980B9),
          'members': [
            {'relation': 'Ama', 'emoji': '👨'},
            {'relation': 'Ina', 'emoji': '👩'},
          ]
        },
        {
          'title': 'Mga kapatid',
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
          'title': 'Dagiti Apo (Lilong ken Lilang)',
          'color': Color(0xFF9B59B6),
          'members': [
            {'relation': 'Lilong (tatang ni tatang)', 'emoji': '👴'},
            {'relation': 'Lilang (nanang ni tatang)', 'emoji': '👵'},
            {'relation': 'Lilong (tatang ni nanang)', 'emoji': '👴'},
            {'relation': 'Lilang (nanang ni nanang)', 'emoji': '👵'},
          ]
        },
        {
          'title': 'Dagiti Nagannak',
          'color': Color(0xFF2980B9),
          'members': [
            {'relation': 'Tatang', 'emoji': '👨'},
            {'relation': 'Nanang', 'emoji': '👩'},
          ]
        },
        {
          'title': 'Kakabsat',
          'color': Color(0xFF27AE60),
          'members': [
            {'relation': 'Manong (panganay)', 'emoji': '🧑'},
            {'relation': 'Manang (maikadua)', 'emoji': '👧'},
            {'relation': 'Inaudi', 'emoji': '👶'},
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
        'popup':
            'The Living Room is where a family relaxes and watches TV together',
        'color': Color(0xFFE74C3C)
      },
      {
        'name': 'The Kitchen',
        'emoji': '🍳',
        'activity': 'family cooks and eats together',
        'popup': 'The Kitchen is where a family cooks and eats together',
        'color': Color(0xFFE67E22)
      },
      {
        'name': 'The Bedroom',
        'emoji': '🛏️',
        'activity': 'family rests and talks together',
        'popup': 'The Bedroom is where a family rests and talks together',
        'color': Color(0xFF3498DB)
      },
      {
        'name': 'Bathroom',
        'emoji': '🚿',
        'activity': 'family bathes and washes up',
        'popup': 'The Bathroom is where family bathes and washes up',
        'color': Color(0xFF1ABC9C)
      },
      {
        'name': 'Yard',
        'emoji': '🌿',
        'activity': 'family plays and spends time together',
        'popup': 'The Yard is where a family plays and spends time together',
        'color': Color(0xFF2ECC71)
      },
    ],
    'fil': [
      {
        'name': 'Sala',
        'emoji': '🛋️',
        'activity': 'dito nagpapahinga at nanonood ng telebisyon ang pamilya',
        'color': Color(0xFFE74C3C)
      },
      {
        'name': 'Kusina',
        'emoji': '🍳',
        'activity': 'dito nagluluto at sama-samang kumakain ang pamilya',
        'color': Color(0xFFE67E22)
      },
      {
        'name': 'Kuwarto',
        'emoji': '🛏️',
        'activity': 'dito nagpapahinga at nagkukuwentuhan ang pamilya',
        'color': Color(0xFF3498DB)
      },
      {
        'name': 'Banyo',
        'emoji': '🚿',
        'activity': 'dito naliligo at naghuhugas ng katawan ang pamilya',
        'color': Color(0xFF1ABC9C)
      },
      {
        'name': 'Bakuran',
        'emoji': '🌿',
        'activity': 'dito naglalaro at naglalaan ng oras ang pamilya',
        'color': Color(0xFF2ECC71)
      },
    ],
    'ilo': [
      {
        'name': 'Salas',
        'emoji': '🛋️',
        'activity': 'agmanmano ken mangar-ay iti TV ti pamilya',
        'color': Color(0xFFE74C3C)
      },
      {
        'name': 'Kusina',
        'emoji': '🍳',
        'activity': 'Ti pamilia ket agluto ken mangan a agkakadua',
        'color': Color(0xFFE67E22)
      },
      {
        'name': 'Kuarto',
        'emoji': '🛏️',
        'activity': 'Ti pamilia ket aginana ken agsasarita nga agkakadua',
        'color': Color(0xFF3498DB)
      },
      {
        'name': 'Banio',
        'emoji': '🚿',
        'activity': 'Ti pamilia ket agdigos ken agbuggo',
        'color': Color(0xFF1ABC9C)
      },
      {
        'name': 'Paraangan',
        'emoji': '🌿',
        'activity': 'Pagay-ayaman ken pagliliwaan ti oras ti pamilia.',
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
        'choices': [
          'Grandfather and Grandmother',
          'Uncles and Aunts',
          'Siblings',
          'Cousins'
        ],
        'correct': 0,
        'explanation': 'Correct! Grandparents are the parents of our parents.'
      },
      {
        'id': 'tree_2',
        'question': 'Who is the youngest sibling in the family?',
        'choices': [
          'Older Brother',
          'Older Sister',
          'Baby / Youngest',
          'Grandmother'
        ],
        'correct': 2,
        'explanation':
            'Correct! The baby or youngest is the youngest member among siblings.'
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
        'question': 'Who guides and takes care of children at home?',
        'choices': ['Father and Mother', 'Neighbors', 'Strangers', 'Only pets'],
        'correct': 0,
        'explanation':
            'Parents guide and care for you everyday. Show your love by listening , helping and saying "Thank you!"'
      },
      {
        'id': 'tree_6',
        'question':
            'What chart shows the relationships between family members across generations?',
        'choices': [
          'Family Tree',
          'Shopping List',
          'Calendar',
          'Weather Chart'
        ],
        'correct': 0,
        'explanation':
            'Correct! A Family Tree illustrates generations of a family.'
      },
      {
        'id': 'tree_7',
        'question': 'How should family members treat each other?',
        'choices': [
          'With love and respect',
          'With fighting',
          'By ignoring each other',
          'Shouting'
        ],
        'correct': 0,
        'explanation':
            'Correct! Loving and respecting each other makes a happy family.'
      },
    ],
    'fil': [
      {
        'id': 'tree_1',
        'question': 'Sino ang mga magulang ng iyong Ama o Ina?',
        'choices': [
          'Mga ninuno (Mga Lolo at Lola)',
          'Tiyo at Tiya',
          'Mga kapatid',
          'Mga Pinsan'
        ],
        'correct': 0,
        'explanation':
            'Tama! Ang Lolo at Lola ang mga magulang ng ating magulang.'
      },
      {
        'id': 'tree_2',
        'question': 'Sino ang pinakabata sa pamilya?',
        'choices': ['Kuya', 'Ate', 'Bunso', 'Lola'],
        'correct': 2,
        'explanation':
            'Tama! Ang bunso ang pinakabatang kasapi ng pamilya sa lahat ng magkakapatid.'
      },
      {
        'id': 'tree_3',
        'question':
            'Ano ang tawag sa nakakatandang kapatid na lalaki sa Filipino?',
        'choices': ['Ate', 'Kuya', 'Bunso', 'Lolo'],
        'correct': 1,
        'explanation':
            'Tama! Kuya ang tawag sa nakatatandang kapatid na lalaki.'
      },
      {
        'id': 'tree_4',
        'question':
            'Ano ang tawag sa nakakatandang kapatid na babae sa Filipino?',
        'choices': ['Kuya', 'Ate', 'Bunso', 'Lola'],
        'correct': 1,
        'explanation': 'Tama! Ate ang tawag sa nakatatandang kapatid na babae.'
      },
      {
        'id': 'tree_5',
        'question':
            'Sino ang gumagabay at nag-aalaga sa mga anak sa loob ng tahanan?',
        'choices': [
          'Ama at Ina',
          'Mga kapitbahay',
          'Mga hindi kakilala',
          'Mga Alagang Hayop lamang'
        ],
        'correct': 0,
        'explanation':
            'Tama! Ang Ama at Ina ang gumagabay at nagmamahal sa kanilang mga anak.'
      },
      {
        'id': 'tree_6',
        'question':
            'Anong tsart ang nagpapakita ng ugnayan ng pamilya sa iba\'t-ibang henerasyon?',
        'choices': [
          'Puno ng Pamilya (Family Tree)',
          'Listahan ng Bilihin',
          'Kalendaryo',
          'Talaan ng Panahon'
        ],
        'correct': 0,
        'explanation':
            'Tama! Ang talaan ng pamilya ay nagpapakita ng henerasyon ng pamilya.'
      },
      {
        'id': 'tree_7',
        'question': 'Paano dapat tratuhin ang bawat kasapi ng pamilya?',
        'choices': [
          'Magmahalan at magrespetuhan',
          'Mag-away araw-araw',
          'Magdedmahan',
          'Magsigawan'
        ],
        'correct': 0,
        'explanation':
            'Tama! Ang pagmamahalan at pagrespeto ang pundasyon ng pamilya.'
      },
    ],
    'ilo': [
      {
        'id': 'tree_1',
        'question': 'Sinno dagiti nagannak ni Tatang wenno ni Nanang mo?',
        'choices': [
          'Lilong ken Lilang',
          'Uliteg ken Ikit',
          'Kakabsat',
          'Kasinsin'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Dagiti apong ket dagiti nagannak dagiti nagannaktayo.'
      },
      {
        'id': 'tree_2',
        'question': 'Sinno ti kaudian a kabsat iti pamilia?',
        'choices': ['Manong', 'Manang', 'Ubing / Inudian', 'Lilang'],
        'correct': 2,
        'explanation':
            'Kusto! Ti maladaga wenno kaubingan a kameng kadagiti kakabsat.'
      },
      {
        'id': 'tree_3',
        'question':
            'Ania ti awagmo iti in-inauna a kabsat a lalaki iti Tagalog/Filipino?',
        'choices': ['Manang', 'Manong', 'Inaudi', 'Lilong'],
        'correct': 1,
        'explanation': 'Kusto! Kuya ket ti termino para ti manong'
      },
      {
        'id': 'tree_4',
        'question':
            'Ania ti awagmo iti in-inauna a kabsat a babai iti Tagalog/Filipino?',
        'choices': ['Manong', 'Manang', 'Inaudi', 'Lilang'],
        'correct': 1,
        'explanation': 'Kusto! Ate ket ti termino para ti manang'
      },
      {
        'id': 'tree_5',
        'question':
            'Sinno ti mangiturong ken mangaywan kadagiti annak iti balay?',
        'choices': [
          'Tatang ken Nanang',
          'Karruba',
          'Ganggannaet',
          'Ay-ayup laeng'
        ],
        'correct': 0,
        'explanation':
            'Inaldaw nga iwanwan ken aywanannaka dagiti nagannak. Ipakitam ti ayatmo babaen ti panagdengngeg, panangtulong ken panangibaga iti "Agyamanak!"'
      },
      {
        'id': 'tree_6',
        'question':
            'Ania ti tsart ti mangipakita iti relasion iti sumaganad a henerasion?',
        'choices': [
          'Puon ti Pamilya',
          'Listaan ti batangan',
          'Kalendario',
          'Tsart ti Panawen'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Ipakita ti Puon ti Pamilia dagiti henerasion ti maysa a pamilia'
      },
      {
        'id': 'tree_7',
        'question': 'Kasano koma ti panagtitinnulong dagiti kameng ti pamilia?',
        'choices': [
          'Ti ayat ken respeto',
          'Aga-apa',
          'Babaen ti saan a panag pipinnansin',
          'Agpukkaw'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Ti panagayat ken panagraem iti tunggal maysa ket mangaramid iti naragsak a pamilia.'
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
        'explanation':
            'Correct! The kitchen is where delicious meals are prepared.'
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
        'choices': [
          'Living Room (Sala)',
          'Bathroom',
          'Storage room',
          'Kitchen'
        ],
        'correct': 0,
        'explanation':
            'Correct! The living room is for family relaxation and gathering.'
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
        'choices': [
          'It protects and shelters our family with love',
          'It is just a store',
          'It is noisy',
          'No reason'
        ],
        'correct': 0,
        'explanation':
            'Correct! Home is our safe haven filled with family love.'
      },
      {
        'id': 'home_7',
        'question': 'How can we help keep our home clean and neat?',
        'choices': [
          'Help sweep and organize toys',
          'Throw trash anywhere',
          'Break things',
          'Make a mess'
        ],
        'correct': 0,
        'explanation':
            'Correct! Helping clean keeps our home comfortable for everyone.'
      },
    ],
    'fil': [
      {
        'id': 'home_1',
        'question':
            'Saang bahagi ng tahanan tayo nagluluto at naghahanda ng pagkain?',
        'choices': ['Kusina', 'Kuwarto', 'Banyo', 'Garahe'],
        'correct': 0,
        'explanation':
            'Tama! Sa Kusina tayo naghahanda ng mga masasarap na pagkain.'
      },
      {
        'id': 'home_2',
        'question': 'Saang bahagi ng tahanan tayo natutulog at nagpapahinga?',
        'choices': ['Kuwarto', 'Kusina', 'Bakuran', 'Silid-kainan'],
        'correct': 0,
        'explanation':
            'Tama! Sa Kuwarto tayo nakakapagpahinga at nakakatulog nang mahimbing.'
      },
      {
        'id': 'home_3',
        'question':
            'Saan nagtitipon ang pamilya upang magkuwentuhan at manood ng telebisyon?',
        'choices': ['Sala', 'Banyo', 'Silid-imbakan', 'Kusina'],
        'correct': 0,
        'explanation': 'Tama! Sa Sala nagpapahinga at nagtitipon ang pamilya.'
      },
      {
        'id': 'home_4',
        'question': 'Saan tayo naliligo at naghuhugas ng katawan?',
        'choices': ['Banyo', 'Sala', 'Hardin', 'Kuwarto'],
        'correct': 0,
        'explanation': 'Tama! Sa banyo tayo naliligo para maging malinis.'
      },
      {
        'id': 'home_5',
        'question':
            'Saan maaaring ligtas na maglaro ang mga bata sa labas ng bahay?',
        'choices': ['Bakuran', 'Mataong daan', 'Kalan sa kusina', 'Bubong'],
        'correct': 0,
        'explanation': 'Tama! Ligtas maglaro at magsaya sa bakuran o hardin.'
      },
      {
        'id': 'home_6',
        'question': 'Bakit napakahalaga sa atin ang ating tahanan?',
        'choices': [
          'Pinoprotektahan at inaalagaan nito ang aming pamilya nang may pagmamahal',
          'Isa lamang itong tindahan',
          'Maingay',
          'Walang dahilan'
        ],
        'correct': 0,
        'explanation':
            'Tama! Ligtas at punong-puno ng pagmamahal ang ating tahanan.'
      },
      {
        'id': 'home_7',
        'question': 'Paano natin mapapanatiling malinis at maayos ang tahanan?',
        'choices': [
          'Magtulong sa pag-aayos at pagwawalis',
          'Magkalat sa sahig',
          'Manira ng gamit',
          'Iwanan ang laruan sa daan'
        ],
        'correct': 0,
        'explanation':
            'Tama! Ang pagtulong sa paglilinis ay nagpapanatili ng ganda ng bahay.'
      },
    ],
    'ilo': [
      {
        'id': 'home_1',
        'question':
            'Iti ania paset ti balay ti paglutwan ken pangisaganaan iti taraon',
        'choices': ['Kusina', 'Kuarto', 'Banio', 'Garahe'],
        'correct': 0,
        'explanation':
            'Kusto! Ti kusina ti pangisaganaan kadagiti naimas a taraon.'
      },
      {
        'id': 'home_2',
        'question':
            'Iti ania a paset ti balay ti pagturogan ken paginanaan tayo?',
        'choices': ['Kuarto', 'Kusina', 'Paraangan', 'Panganan'],
        'correct': 0,
        'explanation':
            'Kusto! Ti kwarto ket mangmangted iti inana ken natalna a panag-turog'
      },
      {
        'id': 'home_3',
        'question':
            'Sadino ti pag-uumongnan ti pamilia tapno agsasarita ken agbuya iti TV?',
        'choices': ['Salas', 'Banio', 'Bodega', 'Kusina'],
        'correct': 0,
        'explanation':
            'Salas: Aginana ken agbuya iti TV a agkakadua ti pamilia.'
      },
      {
        'id': 'home_4',
        'question': 'Sadinno ti pag-digosantayo ken pagbuggaon tayo?',
        'choices': ['Banio', 'Salas', 'Hardin', 'Kuarto'],
        'correct': 0,
        'explanation':
            'Kusto! Iti Banio ti panagsalimet-mettayo iti kinadalus ti bagi.'
      },
      {
        'id': 'home_5',
        'question':
            'Sadinno a natalged a pagay-ayaman dagiti ubbing iti ruar nga asideg iti balay?',
        'choices': [
          'Paraangan',
          'Kalsada nga ado lumablabas',
          'Kalan ti kusina',
          'Atep'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Ti paraangan wenno minuyongan ket natalged a pagay-ayaman iti ruar.'
      },
      {
        'id': 'home_6',
        'question': 'Apay a napateg unay kadatayo ti balay tayo?',
        'choices': [
          'Sal-salaknibanna ken lin-linongan ti pamilia tayo babaen iti ayat.',
          'Maysa laeng a tiendaan',
          'Naariwawa daytoy',
          'Awan gapuna'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Ti balay ket natalged a paglin-linongan a napno ti ayat ti pamilia.'
      },
      {
        'id': 'home_7',
        'question':
            'Kasano tayo a makatulong tapno nadalus ken nasayaat ti pagtaengantayo?',
        'choices': [
          'Tumulong nga agsagad ken mangurnos kadagiti ay-ayam.',
          'Ibelleng ti basura iti sadinoman',
          'Buraken dagiti bambanag',
          'Baybay-an ti laruan'
        ],
        'correct': 0,
        'explanation':
            'Kusto! Ti panagtulong iti panagdalus ket mangpatalged ti balay tayo para kadagiti amin.'
      },
    ],
  };
}
