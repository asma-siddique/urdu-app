import 'package:flutter/material.dart';
import '../services/tts_service.dart';

const _kBg   = Color(0xFFFAFBFF);
const _kTeal = Color(0xFF26C6DA);

// ══════════════════════════════════════════════════════════════════════════════
// Hub screen
// ══════════════════════════════════════════════════════════════════════════════
class VocabularyBankScreen extends StatelessWidget {
  const VocabularyBankScreen({super.key});

  static const List<_VocabCat> _cats = [
    _VocabCat('Daily Use Terms',        Icons.wb_sunny_rounded,        Color(0xFF2563EB)),
    _VocabCat('Urdu Poetic Terms',      Icons.auto_stories_rounded,    Color(0xFF7C3AED)),
    _VocabCat('Essential Urdu Phrases', Icons.chat_bubble_rounded,     Color(0xFF059669)),
    _VocabCat('Basic Shapes',           Icons.category_rounded,        Color(0xFFE07B2A)),
    _VocabCat('3D Shapes',              Icons.view_in_ar_rounded,      Color(0xFF0EA5E9)),
    _VocabCat('Occupations',            Icons.work_rounded,            Color(0xFF7C3AED)),
    _VocabCat('Political Terms',        Icons.account_balance_rounded, Color(0xFF1E3A5F)),
    _VocabCat('Legal Terms',            Icons.gavel_rounded,           Color(0xFF78350F)),
    _VocabCat('Home Vocabulary',        Icons.home_rounded,            Color(0xFF16A34A)),
    _VocabCat('Flowers',                Icons.local_florist_rounded,   Color(0xFFf15bb5)),
    _VocabCat('Celestial Names',        Icons.nights_stay_rounded,     Color(0xFF4F46E5)),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(children: [
          const _VocabHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Vocabulary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('All Topics',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF374151)),
                ]),
              ),
            ]),
          ),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            itemCount: _cats.length,
            itemBuilder: (ctx, i) => _CatRow(cat: _cats[i]),
          )),
        ]),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _VocabHeader extends StatelessWidget {
  const _VocabHeader();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -20,
            child: Container(width: 120, height: 120,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07), shape: BoxShape.circle))),
        Positioned(top: 50, right: 55,
            child: Container(width: 60, height: 60,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 10, 16, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => TtsService.instance.speak('Vocabulary Bank. ذخیرہ الفاظ'),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20)),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.15), blurRadius: 10,
                      offset: const Offset(0, 4))],
                ),
                child: const Center(child: Text('🧒', style: TextStyle(fontSize: 36)))),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Vocabulary Bank',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(width: 5),
                  Text('📚', style: TextStyle(fontSize: 18)),
                ]),
                SizedBox(height: 2),
                Directionality(textDirection: TextDirection.rtl,
                  child: Text('ذخیرہ الفاظ سیکھیں',
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu', fontSize: 13, color: Colors.white70,
                      height: 1.2, leadingDistribution: TextLeadingDistribution.even))),
              ])),
              const SizedBox(width: 72, height: 72, child: Stack(children: [
                Positioned(bottom: 0, left: 6, child: Text('📖', style: TextStyle(fontSize: 38))),
                Positioned(top: 0, left: 24,  child: Text('✏️', style: TextStyle(fontSize: 20))),
                Positioned(top: 2, right: 0,  child: Text('✨', style: TextStyle(fontSize: 16))),
                Positioned(bottom: 14, right: 2, child: Text('⭐', style: TextStyle(fontSize: 11))),
              ])),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('📝', style: TextStyle(fontSize: 14)),
                SizedBox(width: 7),
                Text('11 categories  •  Tap to explore',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────────
class _CatRow extends StatelessWidget {
  final _VocabCat cat;
  const _CatRow({required this.cat});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => VocabDetailScreen(title: cat.label))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: cat.color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: cat.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: cat.color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(child: Icon(cat.icon, color: Colors.white, size: 26))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 3),
            Text('Tap to explore words',
                style: TextStyle(fontSize: 11, color: cat.color.withOpacity(0.75))),
          ])),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, color: cat.color.withOpacity(0.6), size: 24),
        ]),
      ),
    );
  }
}

class _VocabCat {
  final String label;
  final IconData icon;
  final Color color;
  const _VocabCat(this.label, this.icon, this.color);
}

// ══════════════════════════════════════════════════════════════════════════════
// Detail screen
// ══════════════════════════════════════════════════════════════════════════════
class VocabDetailScreen extends StatefulWidget {
  final String title;
  const VocabDetailScreen({super.key, required this.title});
  @override
  State<VocabDetailScreen> createState() => _VocabDetailState();
}

class _VocabDetailState extends State<VocabDetailScreen> {
  static const Map<String, List<_Word>> _data = {
    'Daily Use Terms': [
      _Word('پانی',     'Paani',       'Water',              '💧'),
      _Word('کھانا',    'Khaana',      'Food',               '🍽️'),
      _Word('گھر',      'Ghar',        'Home',               '🏠'),
      _Word('دوست',     'Dost',        'Friend',             '🤝'),
      _Word('وقت',      'Waqt',        'Time',               '⏰'),
      _Word('کام',      'Kaam',        'Work',               '💼'),
      _Word('راستہ',    'Raasta',      'Path / Way',         '🛤️'),
      _Word('صبح',      'Subah',       'Morning',            '🌅'),
      _Word('شام',      'Shaam',       'Evening',            '🌆'),
      _Word('رات',      'Raat',        'Night',              '🌙'),
    ],
    'Urdu Poetic Terms': [
      _Word('غزل',      'Ghazal',      'Lyric poem',         '📜'),
      _Word('شعر',      'Shair',       'Verse / Poetry',     '✍️'),
      _Word('ردیف',     'Radif',       'Refrain',            '🔁'),
      _Word('قافیہ',    'Qaafia',      'Rhyme',              '🎵'),
      _Word('مصرع',     'Misra',       'Hemistich',          '📝'),
      _Word('دیوان',    'Diwaan',      'Poetry collection',  '📚'),
      _Word('مطلع',     'Matla',       'Opening couplet',    '🌟'),
      _Word('مقطع',     'Maqta',       'Closing couplet',    '🔚'),
    ],
    'Essential Urdu Phrases': [
      _Word('آداب',     'Aadaab',      'Greetings',          '🙏'),
      _Word('شکریہ',    'Shukriya',    'Thank you',          '💛'),
      _Word('معاف کریں','Maaf karen',  'Excuse me',          '🙇'),
      _Word('کیا حال ہے','Kya haal hai','How are you?',      '😊'),
      _Word('ٹھیک ہوں', 'Theek hoon',  'I am fine',          '✅'),
      _Word('خوش آمدید','Khush aamdeed','Welcome',           '🎉'),
    ],
    'Basic Shapes': [
      _Word('دائرہ',    'Daira',       'Circle',             '⭕'),
      _Word('مربع',     'Muraba',      'Square',             '⬜'),
      _Word('مثلث',     'Musalas',     'Triangle',           '🔺'),
      _Word('آیت',      'Aayat',       'Rectangle',          '▬'),
      _Word('ستارہ',    'Sitaara',     'Star',               '⭐'),
      _Word('دل',       'Dil',         'Heart',              '❤️'),
    ],
    '3D Shapes': [
      _Word('کرہ',      'Kura',        'Sphere',             '🔵'),
      _Word('مکعب',     'Mukab',       'Cube',               '🟫'),
      _Word('مخروط',    'Makhrut',     'Cone',               '🔺'),
      _Word('اسطوانہ',  'Ustuwaana',   'Cylinder',           '🥫'),
    ],
    'Occupations': [
      _Word('استاد',    'Ustaad',      'Teacher',            '👨‍🏫'),
      _Word('ڈاکٹر',    'Doctor',      'Doctor',             '👨‍⚕️'),
      _Word('انجینیئر', 'Engineer',    'Engineer',           '👷'),
      _Word('کسان',     'Kisaan',      'Farmer',             '👨‍🌾'),
      _Word('دکاندار',  'Dukaandaar',  'Shopkeeper',         '🏪'),
      _Word('پولیس',    'Police',      'Police',             '👮'),
    ],
    'Political Terms': [
      _Word('حکومت',    'Hukumat',     'Government',         '🏛️'),
      _Word('انتخاب',   'Intikhab',    'Election',           '🗳️'),
      _Word('وزیر',     'Wazir',       'Minister',           '👔'),
      _Word('پارلیمنٹ', 'Parliament',  'Parliament',         '🏢'),
      _Word('جمہوریت',  'Jamhuriyat',  'Democracy',          '🗽'),
    ],
    'Legal Terms': [
      _Word('عدالت',    'Adalat',      'Court',              '⚖️'),
      _Word('قانون',    'Qaanoon',     'Law',                '📋'),
      _Word('گواہ',     'Gawah',       'Witness',            '👁️'),
      _Word('وکیل',     'Wakeel',      'Lawyer',             '👨‍⚖️'),
      _Word('فیصلہ',    'Faisla',      'Verdict',            '🔨'),
    ],
    'Home Vocabulary': [
      _Word('کمرہ',     'Kamra',       'Room',               '🛏️'),
      _Word('باورچی خانہ','Bawarchi khaana','Kitchen',       '🍳'),
      _Word('دروازہ',   'Darwaaza',    'Door',               '🚪'),
      _Word('کھڑکی',    'Khirki',      'Window',             '🪟'),
      _Word('چھت',      'Chhat',       'Roof',               '🏠'),
      _Word('صحن',      'Sahn',        'Courtyard',          '🌿'),
    ],
    'Flowers': [
      _Word('گلاب',     'Gulaab',      'Rose',               '🌹'),
      _Word('چمیلی',    'Chameli',     'Jasmine',            '🌸'),
      _Word('سورج مکھی','Suraj Mukhi', 'Sunflower',          '🌻'),
      _Word('کنول',     'Kamal',       'Lotus',              '🪷'),
      _Word('گیندا',    'Genda',       'Marigold',           '🌼'),
      _Word('نرگس',     'Nargis',      'Daffodil',           '🌷'),
    ],
    'Celestial Names': [
      _Word('سورج',     'Suraj',       'Sun',                '☀️'),
      _Word('چاند',     'Chaand',      'Moon',               '🌙'),
      _Word('ستارہ',    'Sitaara',     'Star',               '⭐'),
      _Word('زہرہ',     'Zuhra',       'Venus',              '🪐'),
      _Word('مریخ',     'Marreekh',    'Mars',               '🔴'),
      _Word('مشتری',    'Mushtari',    'Jupiter',            '🟤'),
      _Word('زحل',      'Zuhaal',      'Saturn',             '🪐'),
      _Word('کہکشاں',   'Kahkashaan',  'Galaxy',             '🌌'),
    ],
  };

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) TtsService.instance.speak(widget.title);
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = _data[widget.title] ?? [const _Word('جلد آ رہا ہے','Coming soon','Coming soon','🚧')];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(children: [
          _DetailBar(title: widget.title),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: words.length,
            itemBuilder: (ctx, i) => _WordRow(word: words[i]),
          )),
        ]),
      ),
    );
  }
}

// ── Detail top bar ─────────────────────────────────────────────────────────────
class _DetailBar extends StatelessWidget {
  final String title;
  const _DetailBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF10B981)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 16),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
        GestureDetector(
          onTap: () => TtsService.instance.speak(title),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20)),
        ),
      ]),
    );
  }
}

// ── Word row ───────────────────────────────────────────────────────────────────
class _WordRow extends StatelessWidget {
  final _Word word;
  const _WordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
          ),
          child: Center(child: Text(word.emoji, style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Directionality(textDirection: TextDirection.rtl,
              child: Text(word.urdu,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu', fontSize: 20,
                  fontWeight: FontWeight.bold, color: Color(0xFF1B4332),
                  height: 1.2, leadingDistribution: TextLeadingDistribution.even))),
            const SizedBox(height: 2),
            Text('${word.roman}  •  ${word.english}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        )),
        GestureDetector(
          onTap: () => TtsService.instance.speak(
              '${word.roman}. ${word.english}'),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.volume_up_rounded, color: _kTeal, size: 20)),
        ),
      ]),
    );
  }
}

class _Word {
  final String urdu, roman, english, emoji;
  const _Word(this.urdu, this.roman, this.english, this.emoji);
}
