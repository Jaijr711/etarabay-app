class MagbasaContent {
  /// The language the poems, stories and songs are actually in.
  ///
  /// Let's Read is a mother-tongue module: these pieces exist to be read and
  /// sung in Ilokano, so the words do not follow the app's language setting
  /// the way a button label does. Switching the app to English changes the
  /// buttons and headings around the poem; it does not translate the poem.
  ///
  /// The English and Filipino readings have been deleted rather than left
  /// unreachable. Each of them pointed at the same Ilokano recording, so a
  /// child who picked English read English words while an Ilokano voice sang
  /// over them; and while they sat here, every timing had to be written into
  /// three copies of the same verse to keep them agreeing.
  static const String motherTongue = 'ilo';

  // ── Category Progress Activities ──────────────────────────────────────
  static List<Map<String, dynamic>> getPoemActivities() {
    return _poemActivities;
  }

  static List<Map<String, dynamic>> getStoryActivities() {
    return _storyActivities;
  }

  static List<Map<String, dynamic>> getSongActivities() {
    return _songActivities;
  }

  static const List<Map<String, dynamic>> _poemActivities = [
    {
      'id': 'sipsipat',
      'title': 'Sipsipat',
      'completed': false,
      'type': 'poem',
      'image': 'assets/images/poem1.png'
    },
    {
      'id': 'adda_asok',
      'title': 'Adda Asok',
      'completed': false,
      'type': 'poem',
      'image': 'assets/images/poem2.png'
    },
    {
      'id': 'ti_pusak',
      'title': 'Ti Pusak',
      'completed': false,
      'type': 'poem',
      'image': 'assets/images/poem3.png'
    },
    {
      'id': 'ni_tatang',
      'title': 'Ni Tatang',
      'completed': false,
      'type': 'poem',
      'image': 'assets/images/poem4.png'
    },
    {
      'id': 'panagsepilio',
      'title': 'Panagsepilio',
      'completed': false,
      'type': 'poem',
      'image': 'assets/images/poem5.png'
    },
  ];

  static const List<Map<String, dynamic>> _storyActivities = [
    {
      'id': 'ni_marti',
      'title': 'Ni Marti ken Kalapati',
      'completed': false,
      'type': 'story',
      'image': 'assets/images/kwento1.png'
    },
    {
      'id': 'ni_didi',
      'title': 'Ni Didi a Naayat iti Kendi',
      'completed': false,
      'type': 'story',
      // The four kwento2-5 files were each shot one story ahead of the
      // title they were filed under (kwento2 shows tooth-brushing, which
      // is ni_milio's story) — the ids below now point at the file that
      // actually matches the title.
      'image': 'assets/images/kwento4.png'
    },
    {
      'id': 'ni_milio',
      'title': 'Ni Milio a Managsepilio',
      'completed': false,
      'type': 'story',
      'image': 'assets/images/kwento2.png'
    },
    {
      'id': 'ni_neneng',
      'title': 'Ni Neneng a Dina Kayat ti Nateng',
      'completed': false,
      'type': 'story',
      'image': 'assets/images/kwento5.png'
    },
    {
      'id': 'ni_kikay',
      'title': 'Ni Kikay a di Agsagaysay',
      'completed': false,
      'type': 'story',
      'image': 'assets/images/kwento3.png'
    },
  ];

  static const List<Map<String, dynamic>> _songActivities = [
    {
      'id': 'ania_ti_naganmo_full',
      'title': 'Ania ti Nagan Mo',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_nagan.png'
    },
    {
      'id': 'uppat_a_pato',
      'title': 'Uppat a Pato',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_pato.png'
    },
    {
      'id': 'duat_imak',
      'title': 'Duat\' Imak',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_imak.png'
    },
    {
      'id': 'bassit_a_lawwalawwa',
      'title': 'Bassit a Lawwalawwa',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_lawwa.png'
    },
    {
      'id': 'maysa_dua_baduya',
      'title': 'Maysa, Dua, Baduya',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_baduya.png'
    },
    {
      'id': 'ni_nanangko',
      'title': 'Ni Nanangko',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_nanang.png'
    },
    {
      'id': 'da_tarong',
      'title': 'Da Tarong, Kamatis ken Paria',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_tarong.png'
    },
    {
      'id': 'nagmulaak_iti_katuday',
      'title': 'Nagmulaak iti Katuday',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_katuday.png'
    },
    {
      'id': 'lima_a_tinapay',
      'title': 'Lima a Tinapay ken dua nga Ikan',
      'completed': false,
      'type': 'song',
      'image': 'assets/images/song_tinapay.png'
    },
  ];

  // ── Poem Data ──────────────────────────────────────────────────────────
  static Map<String, Map<String, dynamic>> getPoemData() {
    return _poemData;
  }

  static const Map<String, Map<String, dynamic>> _poemData = {
    'sipsipat': {
      'title': 'Sipsipat',
      'content': [
        'Sipsipat, sipsipat',
        'Addaanak patupat',
        'Kanek ti agpatpatnag',
        'Bayat ti panagbasak',
      ],
      'image': 'assets/images/poem1.png',
      // _v2: cleaned up 2026-09-02, see the note on the ni_marti story's
      // audioPath in _storyData.
      'audioPath': 'audio/poems/Sipsipat_v2.mp3',
      'lineTimestampsMs': [0, 2350, 4263, 6249],
    },
    'adda_asok': {
      'title': 'Adda Asok',
      'content': [
        'Adda asok',
        'Puraw a burbor',
        'No agtaul',
        'Gog-gog-gog-gog',
        'Titit, asok, gog-gog-gog',
        'Titit, asok, gog-gog-gog-gog!',
      ],
      'image': 'assets/images/poem2.png',
      // _v2: cleaned up 2026-09-02, see the note on Sipsipat's audioPath.
      'audioPath': 'audio/poems/adda_asok__v2.mp3',
      'lineTimestampsMs': [0, 1459, 3291, 4059, 6036, 8942],
    },
    'ti_pusak': {
      'title': 'Ti Pusak',
      'content': [
        'Adda pusak a bassit',
        'Kolornat nangisit',
        'Dina kayat ti pansit',
        'Ngem kayatnat ikan a babassit.',
        '',
        'Tunggal makitanak ti pusak',
        'Dagus nga asitgannak',
        'Miaw-miaw-miaw kunana',
        'Ikkak metten iti kanenna',
      ],
      'image': 'assets/images/poem3.png',
      // _v2: cleaned up 2026-09-02, see the note on Sipsipat's audioPath.
      'audioPath': 'audio/poems/Ti_Pusak_v2.mp3',
      'lineTimestampsMs': [
        0,
        2659,
        4749,
        6656,
        9338,
        9583,
        11866,
        14028,
        16158
      ],
    },
    'ni_tatang': {
      'title': 'Ni Tatang',
      'content': [
        'Ni Tatang naanus unay',
        'No tiempo ti tudtudo',
        'Isu pay ti nangted balay',
        'Isu pay ti mangituray',
        'Kadakami nga agkakabbalay.',
        '',
        'Mapan latta agarado',
        'Agmulmulat nadumaduma',
        'A taraon ti pamiliana.',
      ],
      'image': 'assets/images/poem4.png',
      // _v2: cleaned up 2026-09-02, see the note on Sipsipat's audioPath.
      'audioPath': 'audio/poems/Ni_Tatang_v2.mp3',
      'lineTimestampsMs': [
        0,
        2665,
        4909,
        7256,
        9258,
        11380,
        11602,
        13959,
        15745
      ],
    },
    'panagsepilio': {
      'title': 'Panagsepilio',
      'content': [
        'Panagsepilio',
        'Agmalem, mamitlo',
        'Sang-aw, nabanglo',
        'Nakaprespresko',
      ],
      'image': 'assets/images/poem5.png',
      // _v2: cleaned up 2026-09-02, see the note on Sipsipat's audioPath.
      'audioPath': 'audio/poems/Panagsepelio_v2.mp3',
      'lineTimestampsMs': [0, 1895, 3672, 5428],
    },
  };

  // ── Story Data ─────────────────────────────────────────────────────────
  static Map<String, Map<String, dynamic>> getStoryData() {
    return _storyData;
  }

  static const Map<String, Map<String, dynamic>> _storyData = {
    'ni_marti': {
      'title': 'Ni Marti ken Kalapati',
      'content': [
        'Maysa nga aldaw, nagpasiar ni Marti idiay igid ti kali.',
        'Nakakita ni Marti iti kalapati idiay igid ti kali.',
        'Nakita ni Marti a tukkol gayam ti payyak ti kalapati.',
        'Pinidut ni Marti ti kalapati ket inyawidna idiay balayda.',
        'Impupok ni Marti ti kalapati sana inagasan.',
        'Pinakan ken pinainum ni Marti ti kalapati.',
        'Idi immimbagen, pinalsutan ni Marti ti kalapati.',
        'Makaay-ayat ni Marti ta natulonganna ti kalapati.',
      ],
      'image': 'assets/images/kwento1.png',
      // _v2: cleaned up 2026-09-02 — highpass + FFT denoise cut background
      // hiss, loudnorm brought the narration up to a consistent, clearer
      // level. Renamed rather than overwritten in place: the offline
      // service worker's asset cache treats a path as the file forever
      // once it has fetched it once (see web/sw.js), so a device that had
      // already cached the old recording would never have picked up the
      // new one at the same filename.
      'audioPath': 'audio/stories/Ni_marti_ken_kallapati_v2.mp3',
      'lineTimestampsMs': [0, 6903, 11551, 15916, 20765, 24606, 28323, 32706],
      // One panel per line, in order. The story screen shows the picture for
      // the line being read, so a child who cannot read follows the story in
      // pictures while the voice reads it to them.
      'linePictures': [
        'assets/images/story_marti_1.png',
        'assets/images/story_marti_2.png',
        'assets/images/story_marti_3.png',
        'assets/images/story_marti_4.png',
        'assets/images/story_marti_5.png',
        'assets/images/story_marti_6.png',
        'assets/images/story_marti_7.png',
        'assets/images/story_marti_8.png',
      ],
    },
    'ni_didi': {
      'title': 'Ni Didi a Naayat iti Kendi',
      'content': [
        'Naayat ni Didi iti kendi.',
        'Tunggal ikkan ni Nanangna iti balonna a kuarta iti inaldaw, igatang amin ni Didi iti kendi.',
        'Inaldaw latta a mangmangan ni Didi iti kendi.',
        'Uray idiay balayda, adda latta kendi a kankanen ni Didi.',
        'Kasta unay sakit ti ngipenna.',
        'Maysa nga aldaw, nangliwat ni Didi idiay eskuelada.',
        'Impakita ni Nanangna iti dentista.',
        'Naduktalan ti dentista nga adu ti naperdi a ngipen ni Didi.',
        'Nanipud idin, saanen a mangmangan ni Didi iti kendi.',
      ],
      'image': 'assets/images/kwento2.png',
      // _v2: cleaned up 2026-09-02, see the note on ni_marti's audioPath.
      'audioPath': 'audio/stories/Ni_didi_a_naayat_iti_kendi_v2.mp3',
      'lineTimestampsMs': [
        0,
        4116,
        11604,
        15292,
        19778,
        22455,
        25977,
        29316,
        33716
      ],
      'linePictures': [
        'assets/images/story_didi_1.png',
        'assets/images/story_didi_2.png',
        'assets/images/story_didi_3.png',
        'assets/images/story_didi_4.png',
        'assets/images/story_didi_5.png',
        'assets/images/story_didi_6.png',
        'assets/images/story_didi_7.png',
        'assets/images/story_didi_8.png',
        'assets/images/story_didi_9.png',
      ],
    },
    'ni_milio': {
      'title': 'Ni Milio a Managsepilio',
      'content': [
        'Managsepilio ni Milio.',
        'Tunggal malpas a mangan, agsepilio a kanayon ni Milio.',
        'Maysa nga aldaw, nagtsek ni Maestrana iti ngipen dagiti adalanna.',
        'Nadlaw ni Maestrana a nadalus dagiti ngipen ni Milio.',
        'Pinalakpakanda ni Milio.',
        'Naragsak a nagawid ni Milio.',
        'Intultuloy ni Milio ti kanayon nga inna panagsepilio.',
      ],
      'image': 'assets/images/kwento3.png',
      // _v2: cleaned up 2026-09-02, see the note on ni_marti's audioPath.
      'audioPath': 'audio/stories/Ni_milio_a_manag_sepelio_v2.mp3',
      'lineTimestampsMs': [0, 4366, 7853, 13053, 17104, 19703, 22128],
      // One panel per line, in order, cut from docs/source-art/milio_sheet.png
      // by tool/cut_story_panels.py. The story screen shows the picture for
      // the line being read, so a child who cannot read follows the story in
      // pictures while the voice reads it to them.
      'linePictures': [
        'assets/images/story_milio_1.png',
        'assets/images/story_milio_2.png',
        'assets/images/story_milio_3.png',
        'assets/images/story_milio_4.png',
        'assets/images/story_milio_5.png',
        'assets/images/story_milio_6.png',
        'assets/images/story_milio_7.png',
      ],
    },
    'ni_neneng': {
      'title': 'Ni Neneng a Dina Kayat ti Nateng',
      'content': [
        'Di pulos kayat ni Neneng ti agsida iti nateng.',
        'Uray no ibaga ni Nanangna nga agsida iti nateng, di latta kayat ni Neneng.',
        'Maysa nga aldaw, nagkapsut ni Neneng idiay eskuelada.',
        'Impan ti Maestrana ni Neneng iti klinika.',
        'Naammuan ti doktor a saan nga agsidsida ni Neneng iti nateng.',
        'Imbaga ti doktor nga agsida ni Neneng iti nateng.',
        'Manipud idin, kanayonen nga agsidsida ni Neneng iti nateng.',
      ],
      'image': 'assets/images/kwento4.png',
      // _v2: cleaned up 2026-09-02, see the note on ni_marti's audioPath.
      'audioPath':
          'audio/stories/Ni_Neneng_a_dina_kayat_ag_sida_iti_nateng_v2.mp3',
      'lineTimestampsMs': [0, 6196, 11771, 15908, 19358, 24083, 27146],
      // One panel per line, in order, cut from docs/source-art/neneng_sheet.png
      // by tool/cut_story_panels.py. This sheet keeps its caption in a box
      // *under* the picture, on a fill so close to the sheet background that
      // the box reads as gutter — the cutter grows each row down to the box's
      // own gold border so no caption loses its last line.
      'linePictures': [
        'assets/images/story_neneng_1.png',
        'assets/images/story_neneng_2.png',
        'assets/images/story_neneng_3.png',
        'assets/images/story_neneng_4.png',
        'assets/images/story_neneng_5.png',
        'assets/images/story_neneng_6.png',
        'assets/images/story_neneng_7.png',
      ],
    },
    'ni_kikay': {
      'title': 'Ni Kikay a di Agsagaysay',
      'content': [
        'Di pulos kayat ni Kikay ti agsagaysay.',
        'Uray ayaban ni Nanangna, di latta pulos kayat ni Kikay ti agsagaysay.',
        'Idiay eskuelada, awan manggayat a makikatugaw kenni Kikay.',
        'Rugpaw ti buokna ken adu pay ti kutona.',
        'Nagsangsangit ni Kikay ta awan mayat a makiay-ayam kenkuana.',
        'Idi agawid idiay balayda kalpasan ti klaseda, nakasabat iti baket.',
        'Rugpaw ti buok ti baket.',
        'Nagbuteng ni Kikay ket nagtartaray a nagawid balayda.',
        'Manipud idin, kanayonen nga agsagsagaysay ni Kikay.',
        'Immadu dagiti gagayyemna ket kanayon payen a naragsak ni Kikay.',
      ],
      'image': 'assets/images/kwento5.png',
      // _v2: cleaned up 2026-09-02, see the note on ni_marti's audioPath.
      'audioPath': 'audio/stories/Ni_kikay_a_di_ag_sagaysay_v2.mp3',
      'lineTimestampsMs': [
        0,
        5193,
        10830,
        15954,
        19218,
        23855,
        29317,
        31355,
        35193,
        39168
      ],
      // One panel per line, in order, cut from docs/source-art/kikay_sheet.png
      // by tool/cut_story_panels.py. Panel 5 is cut 17 pixels in from its left
      // edge: the magnifying glass drawn in panel 4 overhangs the seam, so a
      // cut on the seam itself left a black arc sitting in panel 5.
      'linePictures': [
        'assets/images/story_kikay_1.png',
        'assets/images/story_kikay_2.png',
        'assets/images/story_kikay_3.png',
        'assets/images/story_kikay_4.png',
        'assets/images/story_kikay_5.png',
        'assets/images/story_kikay_6.png',
        'assets/images/story_kikay_7.png',
        'assets/images/story_kikay_8.png',
        'assets/images/story_kikay_9.png',
        'assets/images/story_kikay_10.png',
      ],
    },
  };

  // ── Song Data ──────────────────────────────────────────────────────────
  static Map<String, Map<String, dynamic>> getSongData() {
    return _songData;
  }

  static const Map<String, Map<String, dynamic>> _songData = {
    // Was two entries — this one plus a duplicate 'ania_ti_naganmo' with
    // identical lyrics but no recording of its own. Merged into one: the
    // audioPath below is the recording that used to live on the deleted
    // entry, moved here rather than dropped along with it.
    'ania_ti_naganmo_full': {
      'title': 'Ania ti Nagan Mo',
      'tune': 'Audio Recording',
      'lyrics': [
        'Ania ti nagan mo',
        'Ibagam man, gayyemko',
        'Abrasaem ta man',
        'Dayta dakulap mo',
        'Aginnisem ta man',
        'Iti nakaay-ayo',
        'Agsala, agkanta',
        'Itung-ed ti ulo.',
      ],
      'image': 'assets/images/song_nagan.png',
      // Re-recorded and cleaned up 2026-09-02 (highpass + FFT denoise +
      // loudnorm, see the note on Sipsipat's audioPath) — replaces the
      // earlier Kurtjam Kyle Silva Nono recording entirely. Lyrics rewritten
      // 2026-09-05.
      'audioPath': 'audio/songs/Ania_ti_Nagan_Mo.mp3',
      'lineTimestampsMs': [0, 2645, 4757, 7174, 9783, 12184, 14623, 17059],
      'action': {
        'en': 'Wave hands and dance',
        'fil': 'Ikaway ang mga kamay at sumayaw',
        'ilo': 'Iwagayway dagiti imam ket agsala',
      },
    },
    'uppat_a_pato': {
      'title': 'Uppat a Pato',
      'tune': 'Audio Recording',
      'lyrics': [
        'Uppat a pato',
        'Ti nakitak',
        'Dua ti dadakkel',
        'Dua ti babassit',
        'Agkukuyog da',
        'Diay kabassitan',
        'Atiddog ti ipusna',
        'Maringgoran, kunana',
        '"Kuak-kuak-kuak!"',
        'Diay karayan aglalangoy da',
        'Agkinnikinni diay patong da',
        'Ngem diay kabassitan',
        'Atiddog ti ipusna',
        'Maringgoran, kunana',
        '"Kuak-kuak-kuak!"',
      ],
      'image': 'assets/images/song_pato.png',
      // Added and cleaned up 2026-09-02, see the note on Sipsipat's
      // audioPath. Lyrics rewritten 2026-09-05.
      'audioPath': 'audio/songs/Uppat_a_Pato.mp3',
      'lineTimestampsMs': [
        0,
        1892,
        4157,
        6193,
        7818,
        10319,
        11979,
        14231,
        16219,
        18368,
        22593,
        26532,
        28093,
        30629,
        32695
      ],
      'action': {
        'en': 'Count with fingers and waddle like a duck',
        'fil': 'Magbilang gamit ang mga daliri at lumakad na parang pato',
        'ilo': 'Agbilang babaen dagiti ramay ket magna a kas iti pato',
      },
    },
    'duat_imak': {
      'title': 'Duat\' Imak',
      'tune': 'Audio Recording',
      'lyrics': [
        'Dua ti imak',
        'Kannigid ken kannawan',
        'Ingatok ida, nadalus da',
        'Agsipatak, maysa, dua',
        'Kitam ida ket nadalus da.',
      ],
      'image': 'assets/images/song_imak.png',
      // Added and cleaned up 2026-09-02, see the note on Sipsipat's
      // audioPath. Lyrics rewritten 2026-09-05.
      'audioPath': 'audio/songs/Duat_Imak.mp3',
      'lineTimestampsMs': [0, 1690, 4114, 8377, 12477],
      'action': {
        'en': 'Show your hands and clap',
        'fil': 'Ipakita ang mga kamay at pumalakpak',
        'ilo': 'Ipakitam dagiti imam ket agpalakpak',
      },
    },
    'bassit_a_lawwalawwa': {
      'title': 'Bassit a Lawwalawwa',
      'tune': 'Audio Recording',
      'lyrics': [
        'Bassit a lawwalawwa',
        'Immuli diay sanga',
        'Immay ti tudo',
        'Nagna diay baba',
        'Rimmuar ti init',
        'Amin nagmaga',
        'Ket bassit a lawwalawwa',
        'Immuli diay sanga.',
      ],
      'image': 'assets/images/song_lawwa.png',
      // Added and cleaned up 2026-09-02, see the note on Sipsipat's
      // audioPath. Lyrics rewritten 2026-09-05.
      'audioPath': 'audio/songs/Bassit_a_Lawwalawwa.mp3',
      'lineTimestampsMs': [0, 2971, 5396, 8034, 10434, 12686, 14574, 17273],
      'action': {
        'en': 'Spider hand movements climbing up',
        'fil': 'Gayahin ang gagambang umaakyat gamit ang mga kamay',
        'ilo': 'Tuladem ti lawwalawwa nga umuli babaen dagiti imam',
      },
    },
    'maysa_dua_baduya': {
      'title': 'Maysa, Dua, Baduya',
      'tune': 'Audio Recording',
      'lyrics': [
        'Maysa, dua, baduya',
        'Tallo, uppat, patupat',
        'Lima, innem, kankanen',
        'Pito, walo, ginao',
        'Siam, pullo, mangantayo',
        'Ti ruskaldo.',
        '',
        'Maysa, dua, baduya',
        'Tallo, uppat, patupat',
        'Lima, innem, kankanen',
        'Pito, walo, ginao',
        'Siam, pullo, mangantayo',
        'Ti ruskaldo.',
      ],
      'image': 'assets/images/song_baduya.png',
      // Added and cleaned up 2026-09-02, see the note on Sipsipat's
      // audioPath. Lyrics rewritten 2026-09-05.
      'audioPath': 'audio/songs/Maysa_Dua_Baduya.mp3',
      'lineTimestampsMs': [
        0,
        2354,
        5618,
        8604,
        12079,
        15016,
        16541,
        17769,
        20903,
        24067,
        27143,
        30503,
        33553
      ],
      'action': {
        'en': 'Count with fingers 1-10',
        'fil': 'Magbilang ng 1 hanggang 10 gamit ang mga daliri',
        'ilo': 'Agbilang manipud 1 agingga 10 babaen dagiti ramay',
      },
    },
    'ni_nanangko': {
      'title': 'Ni Nanangko',
      'tune': 'Audio Recording',
      'lyrics': [
        'Ni Nanangko, ay-ayatennak',
        'Ub-ubbaennak idi bassitak',
        'Barukong na\'t pagsadsadagak',
        'Ayatna nga agbiagak.',
        'Naragsak aldaw ni Nanangko',
        'Nayanak ti bulan ti Mayo',
        'Pinaglalangto ti kaykayo',
        'Bungbunganat adu.',
      ],
      'image': 'assets/images/song_nanang.png',
      // Added and cleaned up 2026-09-02, see the note on Sipsipat's
      // audioPath. Lyrics rewritten 2026-09-05.
      'audioPath': 'audio/songs/Ni_Nanangko.mp3',
      'lineTimestampsMs': [0, 4593, 9267, 14080, 18045, 22830, 26943, 31193],
      'action': {
        'en': 'Hug yourself and sway',
        'fil': 'Yakapin ang sarili at umindayog',
        'ilo': 'Arakupem ta bagim ket agindayon',
      },
    },
    'da_tarong': {
      'title': 'Da Tarong, Kamatis ken Paria',
      'tune': 'Audio Recording',
      'lyrics': [
        'Maysa a bigat nga agsapa',
        'Agtatamdagak man idiay tawa',
        'Adda da Tarong, Kamatis, Paria',
        'Agtutungtong da nga agsasarita',
        'Kunani Tarong kadakuada',
        'Siak kaimasan kadakay a dua',
        'Ngem ni met Paria simmungbat ita',
        'Agalwad ka Tarong napalangguadka',
        'Ngem ni Kamatis ummisem laeng',
        'Ay gagayyemko, inkay agparbeng',
        'Ta no addaak iti dinengdeng',
        'Diay pinakbet naimimas manen.',
      ],
      'image': 'assets/images/song_tarong.png',
      // Added and cleaned up 2026-09-02, see the note on Sipsipat's
      // audioPath. Lyrics rewritten 2026-09-05.
      'audioPath': 'audio/songs/Da_Tarong_Kamatis_ken_Paria.mp3',
      'lineTimestampsMs': [
        0,
        4479,
        8992,
        13393,
        18306,
        23231,
        27779,
        32354,
        37070,
        41555,
        45779,
        50219
      ],
      'action': {
        'en': 'Point to different vegetables',
        'fil': 'Ituro ang ibaʼt ibang gulay',
        'ilo': 'Itudom dagiti nadumaduma a natnateng',
      },
    },
    'nagmulaak_iti_katuday': {
      'title': 'Nagmulaak iti Katuday',
      'tune': 'Audio Recording',
      'lyrics': [
        'Nagmulaak iti katuday',
        'Diay tuktok ti banbantay',
        'Napan kinaraykay',
        'Ti nadawel a kannaway',
        'Agaluad ka a kannaway',
        'Tuktukkolek ta ramramay',
        'Aramidek a sagaysay',
        'Sagaysay ni Nanang Ikay.',
      ],
      'image': 'assets/images/song_katuday.png',
      // Added and cleaned up 2026-09-02, see the note on Sipsipat's
      // audioPath. Lyrics rewritten 2026-09-05.
      'audioPath': 'audio/songs/Nagmulaak_iti_Katuday.mp3',
      'lineTimestampsMs': [0, 3476, 7642, 10762, 14065, 17164, 21476, 24788],
      'action': {
        'en': 'Planting motion',
        'fil': 'Gayahin ang pagtatanim',
        'ilo': 'Tuladem ti panagmula',
      },
    },
    'lima_a_tinapay': {
      'title': 'Lima nga Tinapay ken dua nga Ikan',
      'tune': 'Audio Recording',
      'lyrics': [
        'Lima nga tinapay ken dua nga ikan (3x)',
        'Intugot diay ubing',
        'Immadu diay tinapay, immadu met diay ikan (3x)',
        'Ket nabsogda amin.',
      ],
      'image': 'assets/images/song_tinapay.png',
      // Added and cleaned up 2026-09-02, see the note on Sipsipat's
      // audioPath. Lyrics rewritten 2026-09-05.
      'audioPath': 'audio/songs/Lima_a_Tinapay.mp3',
      'lineTimestampsMs': [0, 14385, 18436, 33126],
      'action': {
        'en': 'Show five fingers then two fingers',
        'fil': 'Magpakita ng limang daliri, tapos dalawa',
        'ilo': 'Mangipakita iti lima a ramay, kalpasanna dua',
      },
    },
  };
}
