import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class VocabularyBankScreen extends StatefulWidget {
  const VocabularyBankScreen({super.key});

  @override
  State<VocabularyBankScreen> createState() => _VocabularyBankScreenState();
}

class _VocabularyBankScreenState extends State<VocabularyBankScreen> {
  static const _darkGreen = Color(0xFF1B4332);
  static const _medGreen  = Color(0xFF2D6A4F);

  static const List<_VocabCategory> _categories = [
    _VocabCategory('Daily Use Terms',           '/vocab/daily'),
    _VocabCategory('Urdu Poetic Terms',         '/vocab/poetic'),
    _VocabCategory('Essential Urdu Phrases',    '/vocab/phrases'),
    _VocabCategory('Basic Shapes',              '/vocab/shapes'),
    _VocabCategory('3D shapes',                 '/vocab/3d-shapes'),
    _VocabCategory('Occupations',               '/vocab/occupations'),
    _VocabCategory('Political Terms and Positions', '/vocab/political'),
    _VocabCategory('Legal Terms',               '/vocab/legal'),
    _VocabCategory('Home Related Vocabulary',   '/vocab/home'),
    _VocabCategory('Flowers',                   '/vocab/flowers'),
    _VocabCategory('Celestial Names',           '/vocab/celestial'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Vocabulary Bank',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE0D9CC)),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          return _VocabCategoryTile(category: cat);
        },
      ),
    );
  }
}

class _VocabCategoryTile extends StatelessWidget {
  final _VocabCategory category;
  const _VocabCategoryTile({required this.category});

  static const _darkGreen = Color(0xFF1B4332);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        category.label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B6B6B)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VocabDetailScreen(title: category.label),
          ),
        );
      },
    );
  }
}

class _VocabCategory {
  final String label;
  final String route;
  const _VocabCategory(this.label, this.route);
}

// ── Detail screen for each vocabulary category ────────────────────────────────
class VocabDetailScreen extends StatelessWidget {
  final String title;
  const VocabDetailScreen({super.key, required this.title});

  static const Map<String, List<_VocabWord>> _data = {
    'Daily Use Terms': [
      _VocabWord('پانی',     'Paani',    'Water',      '💧'),
      _VocabWord('کھانا',    'Khaana',   'Food',       '🍽️'),
      _VocabWord('گھر',      'Ghar',     'Home',       '🏠'),
      _VocabWord('دوست',     'Dost',     'Friend',     '🤝'),
      _VocabWord('وقت',      'Waqt',     'Time',       '⏰'),
      _VocabWord('کام',      'Kaam',     'Work',       '💼'),
      _VocabWord('راستہ',   'Raasta',   'Path/Way',   '🛤️'),
      _VocabWord('صبح',      'Subah',    'Morning',    '🌅'),
      _VocabWord('شام',      'Shaam',    'Evening',    '🌆'),
      _VocabWord('رات',      'Raat',     'Night',      '🌙'),
    ],
    'Urdu Poetic Terms': [
      _VocabWord('غزل',      'Ghazal',   'Lyric poem', '📜'),
      _VocabWord('شعر',      'Shair',    'Verse/Poetry','✍️'),
      _VocabWord('ردیف',     'Radif',    'Refrain',    '🔁'),
      _VocabWord('قافیہ',    'Qaafia',   'Rhyme',      '🎵'),
      _VocabWord('مصرع',    'Misra',    'Hemistich',  '📝'),
      _VocabWord('دیوان',    'Diwaan',   'Poetry collection','📚'),
      _VocabWord('مطلع',    'Matla',    'Opening couplet','🌟'),
      _VocabWord('مقطع',    'Maqta',    'Closing couplet','🔚'),
    ],
    'Essential Urdu Phrases': [
      _VocabWord('آداب',     'Aadaab',   'Greetings',  '🙏'),
      _VocabWord('شکریہ',   'Shukriya', 'Thank you',  '💛'),
      _VocabWord('معاف کریں','Maaf karen','Excuse me', '🙇'),
      _VocabWord('کیا حال ہے','Kya haal hai','How are you?','😊'),
      _VocabWord('ٹھیک ہوں', 'Theek hoon','I am fine',  '✅'),
      _VocabWord('خوش آمدید','Khush aamdeed','Welcome', '🎉'),
    ],
    'Basic Shapes': [
      _VocabWord('دائرہ',   'Daira',    'Circle',     '⭕'),
      _VocabWord('مربع',    'Muraba',   'Square',     '⬜'),
      _VocabWord('مثلث',    'Musalas',  'Triangle',   '🔺'),
      _VocabWord('آیت',      'Aayat',    'Rectangle',  '▬'),
      _VocabWord('ستارہ',   'Sitaara',  'Star',       '⭐'),
      _VocabWord('دل',       'Dil',      'Heart',      '❤️'),
    ],
    'Occupations': [
      _VocabWord('استاد',   'Ustaad',   'Teacher',    '👨‍🏫'),
      _VocabWord('ڈاکٹر',   'Doctor',   'Doctor',     '👨‍⚕️'),
      _VocabWord('انجینیئر','Engineer', 'Engineer',   '👷'),
      _VocabWord('کسان',    'Kisaan',   'Farmer',     '👨‍🌾'),
      _VocabWord('دکاندار', 'Dukaandaar','Shopkeeper', '🏪'),
      _VocabWord('پولیس',   'Police',   'Police',     '👮'),
    ],
    'Flowers': [
      _VocabWord('گلاب',    'Gulaab',   'Rose',       '🌹'),
      _VocabWord('چمیلی',   'Chameli',  'Jasmine',    '🌸'),
      _VocabWord('سورج مکھی','Suraj Mukhi','Sunflower','🌻'),
      _VocabWord('کنول',    'Kamal',    'Lotus',      '🪷'),
      _VocabWord('گیندا',   'Genda',    'Marigold',   '🌼'),
      _VocabWord('نرگس',    'Nargis',   'Daffodil',   '🌷'),
    ],
    'Celestial Names': [
      _VocabWord('سورج',    'Suraj',    'Sun',        '☀️'),
      _VocabWord('چاند',    'Chaand',   'Moon',       '🌙'),
      _VocabWord('ستارہ',   'Sitaara',  'Star',       '⭐'),
      _VocabWord('زہرہ',    'Zuhra',    'Venus',      '🪐'),
      _VocabWord('مریخ',    'Marreekh', 'Mars',       '🔴'),
      _VocabWord('مشتری',   'Mushtari', 'Jupiter',    '🟤'),
      _VocabWord('زحل',     'Zuhaal',   'Saturn',     '🪐'),
      _VocabWord('کہکشاں',  'Kahkashaan','Galaxy',    '🌌'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final words = _data[title] ?? _buildDefaultWords();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: words.length,
        itemBuilder: (ctx, i) => _WordCard(word: words[i]),
      ),
    );
  }

  List<_VocabWord> _buildDefaultWords() => [
    const _VocabWord('جلد آ رہا ہے', 'Jald aa raha hai', 'Coming Soon', '🚧'),
  ];
}

class _WordCard extends StatelessWidget {
  final _VocabWord word;
  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4332).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(word.emoji, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(
          word.urdu,
          style: const TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          '${word.roman} • ${word.english}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up, color: Color(0xFF2D6A4F)),
          onPressed: () => TtsService.instance.speak(word.urdu),
        ),
      ),
    );
  }
}

class _VocabWord {
  final String urdu, roman, english, emoji;
  const _VocabWord(this.urdu, this.roman, this.english, this.emoji);
}