import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class PoetryBankScreen extends StatefulWidget {
  const PoetryBankScreen({super.key});
  @override
  State<PoetryBankScreen> createState() => _PoetryBankScreenState();
}

class _PoetryBankScreenState extends State<PoetryBankScreen> {
  int _selectedPoetIndex = 0;

  static const _poems = [
    _Poem(
      poet: 'منور رانا',
      poetRoman: 'Munawwar Rana',
      urduLines: [
        'تنہائی بھی کند سی آنے لگی ہے حم بھی',
        'چلو ہم آج یہ قصہ ادھورا چھوڑ دیتے ہیں',
      ],
      romanLines: [
        'tanhayi bhi kund si aane lagi hai ham bhi',
        'chalo ham aaj ye qissa adhoora chhod dete hain',
      ],
      english: 'Loneliness too has become dull for us now\nLet us leave this story incomplete today',
    ),
    _Poem(
      poet: 'علامہ اقبال',
      poetRoman: 'Allama Iqbal',
      urduLines: [
        'ستاروں سے آگے جہاں اور بھی ہیں',
        'ابھی عشق کے امتحاں اور بھی ہیں',
      ],
      romanLines: [
        'sitaaron se aage jahaan aur bhi hain',
        'abhi ishq ke imtihaan aur bhi hain',
      ],
      english: 'Beyond the stars there are more worlds yet\nThere are more trials of love still to come',
    ),
    _Poem(
      poet: 'میر تقی میر',
      poetRoman: 'Mir Taqi Mir',
      urduLines: [
        'میر کیا سادہ ہیں بیمار ہوئے جس کے سبب',
        'اسی عطار کے لڑکے سے دوا لیتے ہیں',
      ],
      romanLines: [
        'Mir kya saada hain bemaar hue jis ke sabab',
        'usi attaar ke ladke se dawa lete hain',
      ],
      english: 'How naive Mir is — the one who caused his illness\nHe seeks remedy from the same apothecary\'s boy',
    ),
    _Poem(
      poet: 'فیض احمد فیض',
      poetRoman: 'Faiz Ahmad Faiz',
      urduLines: [
        'مجھ سے پہلی سی محبت مری محبوب نہ مانگ',
        'میں نے سمجھا تھا کہ تو ہے تو درخشاں ہے حیات',
      ],
      romanLines: [
        'mujh se pehli si muhabbat meri mahboob na maang',
        'main ne samjha tha ke tu hai to darakhshaan hai hayaat',
      ],
      english: 'Do not ask of me, my love, that love I had for you once\nI had thought that you were there, life was radiant',
    ),
    _Poem(
      poet: 'پروین شاکر',
      poetRoman: 'Parveen Shakir',
      urduLines: [
        'خوشبو کا سفر ہے ابھی باقی',
        'پھول کی ضد نہیں ہے میری',
      ],
      romanLines: [
        'khushbu ka safar hai abhi baqi',
        'phool ki zid nahin hai meri',
      ],
      english: 'The journey of fragrance is still not over\nI do not insist on the flower itself',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDD8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Poetry Bank',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Poet selector tabs
          Container(
            color: const Color(0xFF1B4332),
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _poems.length,
              itemBuilder: (ctx, i) {
                final isSelected = i == _selectedPoetIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPoetIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _poems[i].poetRoman,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF1B4332) : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main poem display
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _PoemCard(poem: _poems[_selectedPoetIndex]),
                  const SizedBox(height: 20),
                  // All poems in compact list
                  ...List.generate(_poems.length, (i) {
                    if (i == _selectedPoetIndex) return const SizedBox.shrink();
                    return _CompactPoemTile(
                      poem: _poems[i],
                      onTap: () => setState(() => _selectedPoetIndex = i),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoemCard extends StatefulWidget {
  final _Poem poem;
  const _PoemCard({required this.poem});
  @override
  State<_PoemCard> createState() => _PoemCardState();
}

class _PoemCardState extends State<_PoemCard> {
  bool _showRoman = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Quote mark
          const Align(
            alignment: Alignment.topRight,
            child: Text('❝', style: TextStyle(fontSize: 36, color: Colors.white54)),
          ),
          const SizedBox(height: 8),

          // Urdu lines
          ...widget.poem.urduLines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 20,
                color: Colors.white,
                height: 2.0,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          )),

          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),

          // Poet name
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '~ ${widget.poem.poet}',
              style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 15,
                color: Colors.white70,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),

          const SizedBox(height: 16),

          // Transliteration
          if (_showRoman) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.poem.romanLines.map((line) => Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      height: 1.8,
                    ),
                  )),
                  const SizedBox(height: 8),
                  Text(
                    widget.poem.english,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action row
          Row(
            children: [
              // Listen button
              ElevatedButton.icon(
                onPressed: () => TtsService.instance.speak(
                  widget.poem.urduLines.join(' '),
                ),
                icon: const Icon(Icons.volume_up, size: 16),
                label: const Text('سنیں', style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 10),
              // Transliteration toggle
              ElevatedButton.icon(
                onPressed: () => setState(() => _showRoman = !_showRoman),
                icon: Icon(_showRoman ? Icons.visibility_off : Icons.translate, size: 16),
                label: Text(
                  _showRoman ? 'Hide' : 'Transliteration',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactPoemTile extends StatelessWidget {
  final _Poem poem;
  final VoidCallback onTap;
  const _CompactPoemTile({required this.poem, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              poem.urduLines.first,
              style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 15,
                color: Color(0xFF1B4332),
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 4),
            Text(
              '~ ${poem.poet}',
              style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}

class _Poem {
  final String poet, poetRoman, english;
  final List<String> urduLines, romanLines;
  const _Poem({
    required this.poet,
    required this.poetRoman,
    required this.urduLines,
    required this.romanLines,
    required this.english,
  });
}