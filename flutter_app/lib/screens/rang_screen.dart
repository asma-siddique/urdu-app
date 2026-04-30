import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class _ColorData {
  final String urdu;
  final String english;
  final String roman;
  final Color color;
  final List<String> objects; // "emoji اردو" pairs
  const _ColorData({
    required this.urdu, required this.english, required this.roman,
    required this.color, required this.objects,
  });
}

const List<_ColorData> _COLORS = [
  _ColorData(urdu:'سرخ',    english:'Red',      roman:'Surkh',    color:Color(0xFFEF233C),
    objects:['🍎 سیب','🍓 اسٹرابیری','🌹 گلاب','❤️ دل']),
  _ColorData(urdu:'نیلا',   english:'Blue',     roman:'Neela',    color:Color(0xFF0077B6),
    objects:['🌊 سمندر','🫐 بیری','🧢 ٹوپی','🦋 تتلی']),
  _ColorData(urdu:'سبز',    english:'Green',    roman:'Sabz',     color:Color(0xFF2DC653),
    objects:['🌿 پودا','🥦 بروکلی','🐸 مینڈک','🌳 درخت']),
  _ColorData(urdu:'پیلا',   english:'Yellow',   roman:'Peela',    color:Color(0xFFFDD835),
    objects:['🌻 سورج مکھی','🍋 لیموں','🌟 ستارہ','🐤 چوزہ']),
  _ColorData(urdu:'نارنجی', english:'Orange',   roman:'Naranji',  color:Color(0xFFFF6D00),
    objects:['🍊 مالٹا','🎃 کدو','🦊 لومڑی','🥕 گاجر']),
  _ColorData(urdu:'بنفشی',  english:'Purple',   roman:'Banafshi', color:Color(0xFF9B5DE5),
    objects:['🍇 انگور','🌸 پھول','🦄 یونیکورن','🫐 بیری']),
  _ColorData(urdu:'گلابی',  english:'Pink',     roman:'Gulabi',   color:Color(0xFFf48fb1),
    objects:['🌸 پھول','🦩 فلیمنگو','🍬 ٹافی','🎀 ربن']),
  _ColorData(urdu:'سفید',   english:'White',    roman:'Safaid',   color:Color(0xFFEEEEEE),
    objects:['☁️ بادل','🕊️ کبوتر','🥛 دودھ','🏔️ برف']),
  _ColorData(urdu:'کالا',   english:'Black',    roman:'Kaala',    color:Color(0xFF212529),
    objects:['🌑 رات','🎱 گیند','🖊️ قلم','🐈‍⬛ بلی']),
  _ColorData(urdu:'بھورا',  english:'Brown',    roman:'Bhoora',   color:Color(0xFF795548),
    objects:['🐻 ریچھ','☕ چائے','🍫 چاکلیٹ','🪵 لکڑی']),
  _ColorData(urdu:'آسمانی', english:'Sky Blue', roman:'Aasmani',  color:Color(0xFF00BBF9),
    objects:['☀️ آسمان','🐦 پرندہ','💧 پانی','🧊 برف']),
  _ColorData(urdu:'سنہری',  english:'Golden',   roman:'Sonehari', color:Color(0xFFFFD700),
    objects:['👑 تاج','🏆 ٹرافی','⭐ ستارہ','🌾 گندم']),
];

class RangScreen extends StatefulWidget {
  const RangScreen({super.key});

  @override
  State<RangScreen> createState() => _RangScreenState();
}

class _RangScreenState extends State<RangScreen> {
  int _current = 0;
  AvatarEmotion _emotion = AvatarEmotion.happy;
  late final PageController _pageCtrl;
  final Map<int, double> _scores = {};

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _speak(_ColorData c) async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak('${c.urdu}۔ ${c.roman}۔ ${c.english}');
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic(int index, _ColorData c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: c.urdu,
        targetRoman: c.roman,
        onScore: (score, _) {
          Navigator.pop(context);
          setState(() {
            _scores[index] = score;
            _emotion = score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          context.read<AppProvider>().recordResult(c.urdu, score);
          TtsService.instance.speak(score >= 70 ? 'شاباش!' : 'دوبارہ کوشش کریں۔');
        },
      ),
    );
  }

  void _goTo(int i) {
    _pageCtrl.animateToPage(i,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final c = _COLORS[_current];
    final isLight = c.color.computeLuminance() > 0.45;
    final fg = isLight ? Colors.black87 : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: c.color.withOpacity(0.10),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Directionality(
            textDirection: TextDirection.rtl,
            child: Text('رنگ', style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
          ),
          backgroundColor: c.color,
          foregroundColor: fg,
          elevation: 0,
        ),
        body: Column(
          children: [
            // ── Full-screen color page ──────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _COLORS.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (ctx, i) => _ColorPage(
                  data: _COLORS[i],
                  score: _scores[i],
                  emotion: i == _current ? _emotion : AvatarEmotion.happy,
                  onSpeak: () => _speak(_COLORS[i]),
                  onMic: () => _openMic(i, _COLORS[i]),
                ),
              ),
            ),

            // ── Navigation bar ─────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  // Prev
                  IconButton(
                    onPressed: _current > 0 ? () => _goTo(_current - 1) : null,
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    color: c.color,
                    disabledColor: Colors.grey.shade300,
                  ),
                  // Dot indicators
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_COLORS.length, (i) {
                          return GestureDetector(
                            onTap: () => _goTo(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _current ? 22 : 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: i == _current ? c.color : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  // Next
                  IconButton(
                    onPressed: _current < _COLORS.length - 1 ? () => _goTo(_current + 1) : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    color: c.color,
                    disabledColor: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPage extends StatelessWidget {
  final _ColorData data;
  final double? score;
  final AvatarEmotion emotion;
  final VoidCallback onSpeak;
  final VoidCallback onMic;

  const _ColorPage({
    required this.data, required this.emotion,
    required this.onSpeak, required this.onMic, this.score,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = data.color.computeLuminance() > 0.45;
    final fg = isLight ? Colors.black87 : Colors.white;
    final scoreColor = score == null ? Colors.grey
        : score! >= 70 ? Colors.green : score! >= 50 ? Colors.orange : Colors.red;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Color hero ──────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: double.infinity,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(color: data.color.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                ProfessorAvatar(emotion: emotion, size: 80),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(data.urdu, style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu', fontSize: 44,
                    fontWeight: FontWeight.bold, color: fg,
                  )),
                ),
                Text(data.roman, style: TextStyle(fontSize: 20, color: fg.withOpacity(0.85), fontWeight: FontWeight.w600)),
                Text(data.english, style: TextStyle(fontSize: 14, color: fg.withOpacity(0.65))),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Associated objects ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text('${data.urdu} رنگ کی چیزیں', style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu', fontSize: 18,
                fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e),
              )),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: data.objects.map((obj) {
                final parts = obj.split(' ');
                final emoji = parts.first;
                final word = parts.skip(1).join(' ');
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: data.color.withOpacity(0.4), width: 2),
                      boxShadow: [BoxShadow(color: data.color.withOpacity(0.12), blurRadius: 8)],
                    ),
                    child: Column(children: [
                      Text(emoji, style: const TextStyle(fontSize: 34)),
                      const SizedBox(height: 6),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(word, style: const TextStyle(
                          fontFamily: 'NotoNastaliqUrdu', fontSize: 13,
                          fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e),
                        ), textAlign: TextAlign.center),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Score badge ──────────────────────────────────────────────────
          if (score != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scoreColor.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(score! >= 70 ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('تلفظ: ${score!.toInt()}%', style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu', fontSize: 16, color: scoreColor, fontWeight: FontWeight.bold,
                )),
              ]),
            ),

          // ── Listen + Speak buttons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSpeak,
                  icon: const Text('🔊', style: TextStyle(fontSize: 20)),
                  label: const Text('سنیں', style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: data.color,
                    foregroundColor: fg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onMic,
                  icon: const Text('🎤', style: TextStyle(fontSize: 20)),
                  label: const Text('بولیں', style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: data.color,
                    side: BorderSide(color: data.color, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
