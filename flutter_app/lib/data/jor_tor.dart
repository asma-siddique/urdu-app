class JorTorItem {
  final String letter;
  final String letterRoman;
  final String vowelMark;
  final String vowelRoman;
  final String vowelName;   // e.g. "زبر", "زیر", "پیش"
  final String result;
  final String resultRoman;
  final String exampleWord;
  final String exampleMeaning;
  final String emoji;

  const JorTorItem({
    required this.letter,
    required this.letterRoman,
    required this.vowelMark,
    required this.vowelRoman,
    required this.vowelName,
    required this.result,
    required this.resultRoman,
    required this.exampleWord,
    required this.exampleMeaning,
    required this.emoji,
  });
}

// ── GROUP 1 : آ کی آواز (Aa — long A) ─────────────────────────────────────
const List<JorTorItem> JOR_TOR = [
  JorTorItem(letter:'ب', letterRoman:'B', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'با', resultRoman:'Baa', exampleWord:'باپ',   exampleMeaning:'Father',     emoji:'👨'),
  JorTorItem(letter:'پ', letterRoman:'P', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'پا', resultRoman:'Paa', exampleWord:'پانی',  exampleMeaning:'Water',      emoji:'💧'),
  JorTorItem(letter:'ت', letterRoman:'T', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'تا', resultRoman:'Taa', exampleWord:'تاج',   exampleMeaning:'Crown',      emoji:'👑'),
  JorTorItem(letter:'ج', letterRoman:'J', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'جا', resultRoman:'Jaa', exampleWord:'جادو',  exampleMeaning:'Magic',      emoji:'🪄'),
  JorTorItem(letter:'د', letterRoman:'D', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'دا', resultRoman:'Daa', exampleWord:'دادا',  exampleMeaning:'Grandfather',emoji:'👴'),
  JorTorItem(letter:'ر', letterRoman:'R', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'را', resultRoman:'Raa', exampleWord:'راجہ',  exampleMeaning:'King',       emoji:'🤴'),
  JorTorItem(letter:'س', letterRoman:'S', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'سا', resultRoman:'Saa', exampleWord:'سانپ',  exampleMeaning:'Snake',      emoji:'🐍'),
  JorTorItem(letter:'م', letterRoman:'M', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'ما', resultRoman:'Maa', exampleWord:'ماں',   exampleMeaning:'Mother',     emoji:'👩'),
  JorTorItem(letter:'ن', letterRoman:'N', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'نا', resultRoman:'Naa', exampleWord:'ناک',   exampleMeaning:'Nose',       emoji:'👃'),
  JorTorItem(letter:'ک', letterRoman:'K', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'کا', resultRoman:'Kaa', exampleWord:'کام',   exampleMeaning:'Work',       emoji:'💼'),
  JorTorItem(letter:'گ', letterRoman:'G', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'گا', resultRoman:'Gaa', exampleWord:'گانا',  exampleMeaning:'Song',       emoji:'🎵'),
  JorTorItem(letter:'ل', letterRoman:'L', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'لا', resultRoman:'Laa', exampleWord:'لال',   exampleMeaning:'Red',        emoji:'🔴'),
  JorTorItem(letter:'ہ', letterRoman:'H', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'ہا', resultRoman:'Haa', exampleWord:'ہاتھ',  exampleMeaning:'Hand',       emoji:'✋'),
  JorTorItem(letter:'چ', letterRoman:'Ch',vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'چا', resultRoman:'Chaa',exampleWord:'چاند',  exampleMeaning:'Moon',       emoji:'🌙'),
  JorTorItem(letter:'ش', letterRoman:'Sh',vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'شا', resultRoman:'Shaa',exampleWord:'شاگرد', exampleMeaning:'Student',    emoji:'🎓'),
  JorTorItem(letter:'ف', letterRoman:'F', vowelMark:'ا', vowelRoman:'aa', vowelName:'آ', result:'فا', resultRoman:'Faa', exampleWord:'فارم',  exampleMeaning:'Farm',       emoji:'🌾'),

  // ── GROUP 2 : ے/اے کی آواز (Ay sound) ────────────────────────────────────
  JorTorItem(letter:'ب', letterRoman:'B', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'بے', resultRoman:'Bay', exampleWord:'بیگ',   exampleMeaning:'Bag',        emoji:'🎒'),
  JorTorItem(letter:'پ', letterRoman:'P', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'پے', resultRoman:'Pay', exampleWord:'پیر',   exampleMeaning:'Monday/Foot',emoji:'📅'),
  JorTorItem(letter:'ت', letterRoman:'T', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'تے', resultRoman:'Tay', exampleWord:'تیر',   exampleMeaning:'Arrow',      emoji:'🏹'),
  JorTorItem(letter:'ج', letterRoman:'J', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'جے', resultRoman:'Jay', exampleWord:'جیت',   exampleMeaning:'Victory',    emoji:'🏆'),
  JorTorItem(letter:'ر', letterRoman:'R', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'رے', resultRoman:'Ray', exampleWord:'ریل',   exampleMeaning:'Train',      emoji:'🚂'),
  JorTorItem(letter:'س', letterRoman:'S', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'سے', resultRoman:'Say', exampleWord:'سیب',   exampleMeaning:'Apple',      emoji:'🍎'),
  JorTorItem(letter:'م', letterRoman:'M', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'مے', resultRoman:'May', exampleWord:'میز',   exampleMeaning:'Table',      emoji:'🪑'),
  JorTorItem(letter:'ن', letterRoman:'N', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'نے', resultRoman:'Nay', exampleWord:'نیلا',  exampleMeaning:'Blue',       emoji:'🔵'),
  JorTorItem(letter:'ک', letterRoman:'K', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'کے', resultRoman:'Kay', exampleWord:'کیلا',  exampleMeaning:'Banana',     emoji:'🍌'),
  JorTorItem(letter:'ل', letterRoman:'L', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'لے', resultRoman:'Lay', exampleWord:'لیموں', exampleMeaning:'Lemon',      emoji:'🍋'),
  JorTorItem(letter:'ہ', letterRoman:'H', vowelMark:'ے', vowelRoman:'ay', vowelName:'اے', result:'ہے', resultRoman:'Hay', exampleWord:'ہے',    exampleMeaning:'Is',         emoji:'✅'),

  // ── GROUP 3 : ی/اِی کی آواز (Ee sound) ───────────────────────────────────
  JorTorItem(letter:'ب', letterRoman:'B', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'بی', resultRoman:'Bee', exampleWord:'بیٹا',  exampleMeaning:'Son',        emoji:'👦'),
  JorTorItem(letter:'پ', letterRoman:'P', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'پی', resultRoman:'Pee', exampleWord:'پیلا',  exampleMeaning:'Yellow',     emoji:'🟡'),
  JorTorItem(letter:'ت', letterRoman:'T', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'تی', resultRoman:'Tee', exampleWord:'تیتر',  exampleMeaning:'Partridge',  emoji:'🐦'),
  JorTorItem(letter:'ج', letterRoman:'J', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'جی', resultRoman:'Jee', exampleWord:'جی',    exampleMeaning:'Yes/Heart',  emoji:'💚'),
  JorTorItem(letter:'چ', letterRoman:'Ch',vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'چی', resultRoman:'Chee',exampleWord:'چیتا',  exampleMeaning:'Cheetah',    emoji:'🐆'),
  JorTorItem(letter:'د', letterRoman:'D', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'دی', resultRoman:'Dee', exampleWord:'دیوار', exampleMeaning:'Wall',       emoji:'🧱'),
  JorTorItem(letter:'م', letterRoman:'M', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'می', resultRoman:'Mee', exampleWord:'میٹھا', exampleMeaning:'Sweet',      emoji:'🍬'),
  JorTorItem(letter:'ن', letterRoman:'N', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'نی', resultRoman:'Nee', exampleWord:'نیند',  exampleMeaning:'Sleep',      emoji:'😴'),
  JorTorItem(letter:'ک', letterRoman:'K', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'کی', resultRoman:'Kee', exampleWord:'کیڑا',  exampleMeaning:'Insect',     emoji:'🐛'),
  JorTorItem(letter:'ل', letterRoman:'L', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'لی', resultRoman:'Lee', exampleWord:'لیٹ',   exampleMeaning:'Lie down',   emoji:'🛏️'),
  JorTorItem(letter:'ہ', letterRoman:'H', vowelMark:'ی', vowelRoman:'ee', vowelName:'اِی', result:'ہی', resultRoman:'Hee', exampleWord:'ہیرا',  exampleMeaning:'Diamond',    emoji:'💎'),

  // ── GROUP 4 : و/اُو کی آواز (Oo sound) ───────────────────────────────────
  JorTorItem(letter:'ب', letterRoman:'B', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'بو', resultRoman:'Boo', exampleWord:'بوند',  exampleMeaning:'Drop',       emoji:'💧'),
  JorTorItem(letter:'پ', letterRoman:'P', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'پو', resultRoman:'Poo', exampleWord:'پودا',  exampleMeaning:'Plant',      emoji:'🌱'),
  JorTorItem(letter:'ت', letterRoman:'T', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'تو', resultRoman:'Too', exampleWord:'توتا',  exampleMeaning:'Parrot',     emoji:'🦜'),
  JorTorItem(letter:'ج', letterRoman:'J', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'جو', resultRoman:'Jo',  exampleWord:'جوتا',  exampleMeaning:'Shoe',       emoji:'👟'),
  JorTorItem(letter:'د', letterRoman:'D', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'دو', resultRoman:'Do',  exampleWord:'دودھ',  exampleMeaning:'Milk',       emoji:'🥛'),
  JorTorItem(letter:'ر', letterRoman:'R', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'رو', resultRoman:'Ro',  exampleWord:'روٹی',  exampleMeaning:'Bread',      emoji:'🫓'),
  JorTorItem(letter:'س', letterRoman:'S', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'سو', resultRoman:'So',  exampleWord:'سونا',  exampleMeaning:'Gold/Sleep', emoji:'😴'),
  JorTorItem(letter:'م', letterRoman:'M', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'مو', resultRoman:'Mo',  exampleWord:'موٹا',  exampleMeaning:'Fat',        emoji:'🐷'),
  JorTorItem(letter:'ک', letterRoman:'K', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'کو', resultRoman:'Ko',  exampleWord:'کوا',   exampleMeaning:'Crow',       emoji:'🐦‍⬛'),
  JorTorItem(letter:'گ', letterRoman:'G', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'گو', resultRoman:'Go',  exampleWord:'گول',   exampleMeaning:'Round',      emoji:'⭕'),
  JorTorItem(letter:'ل', letterRoman:'L', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'لو', resultRoman:'Lo',  exampleWord:'لومڑی', exampleMeaning:'Fox',        emoji:'🦊'),
  JorTorItem(letter:'ن', letterRoman:'N', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'نو', resultRoman:'No',  exampleWord:'نور',   exampleMeaning:'Light',      emoji:'💡'),
  JorTorItem(letter:'ہ', letterRoman:'H', vowelMark:'و', vowelRoman:'oo', vowelName:'اُو', result:'ہو', resultRoman:'Ho',  exampleWord:'ہوا',   exampleMeaning:'Wind/Air',   emoji:'🌬️'),

  // ── GROUP 5 : مشترکہ حروف (Combined — 2-letter syllables) ─────────────────
  JorTorItem(letter:'ب', letterRoman:'B', vowelMark:'ل', vowelRoman:'l',  vowelName:'بل', result:'بل', resultRoman:'Bal', exampleWord:'بلی',   exampleMeaning:'Cat',        emoji:'🐱'),
  JorTorItem(letter:'ک', letterRoman:'K', vowelMark:'ل', vowelRoman:'l',  vowelName:'کل', result:'کل', resultRoman:'Kal', exampleWord:'کل',    exampleMeaning:'Yesterday',  emoji:'📅'),
  JorTorItem(letter:'د', letterRoman:'D', vowelMark:'ل', vowelRoman:'l',  vowelName:'دل', result:'دل', resultRoman:'Dil', exampleWord:'دل',    exampleMeaning:'Heart',      emoji:'❤️'),
  JorTorItem(letter:'ج', letterRoman:'J', vowelMark:'ن', vowelRoman:'n',  vowelName:'جن', result:'جن', resultRoman:'Jin', exampleWord:'جنگل',  exampleMeaning:'Forest',     emoji:'🌳'),
  JorTorItem(letter:'م', letterRoman:'M', vowelMark:'ن', vowelRoman:'n',  vowelName:'من', result:'من', resultRoman:'Man', exampleWord:'منہ',   exampleMeaning:'Mouth',      emoji:'👄'),
  JorTorItem(letter:'ب', letterRoman:'B', vowelMark:'ر', vowelRoman:'r',  vowelName:'بر', result:'بر', resultRoman:'Bar', exampleWord:'بردار', exampleMeaning:'Brother',    emoji:'👦'),
  JorTorItem(letter:'س', letterRoman:'S', vowelMark:'ر', vowelRoman:'r',  vowelName:'سر', result:'سر', resultRoman:'Sar', exampleWord:'سر',    exampleMeaning:'Head',       emoji:'🗣️'),
  JorTorItem(letter:'ش', letterRoman:'Sh',vowelMark:'ر', vowelRoman:'r',  vowelName:'شر', result:'شر', resultRoman:'Shar',exampleWord:'شریف',  exampleMeaning:'Noble',      emoji:'😊'),
];
