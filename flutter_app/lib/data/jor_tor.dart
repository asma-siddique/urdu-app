class JorTorItem {
  final String letter;
  final String letterRoman;
  final String vowelMark;
  final String vowelRoman;
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
    required this.result,
    required this.resultRoman,
    required this.exampleWord,
    required this.exampleMeaning,
    required this.emoji,
  });
}

const List<JorTorItem> JOR_TOR = [
  JorTorItem(letter: 'ب', letterRoman: 'B',  vowelMark: 'ا', vowelRoman: 'a', result: 'با', resultRoman: 'Baa', exampleWord: 'باپ',  exampleMeaning: 'Father',      emoji: '👨'),
  JorTorItem(letter: 'پ', letterRoman: 'P',  vowelMark: 'ا', vowelRoman: 'a', result: 'پا', resultRoman: 'Paa', exampleWord: 'پانی', exampleMeaning: 'Water',       emoji: '💧'),
  JorTorItem(letter: 'ت', letterRoman: 'T',  vowelMark: 'ا', vowelRoman: 'a', result: 'تا', resultRoman: 'Taa', exampleWord: 'تاج',  exampleMeaning: 'Crown',       emoji: '👑'),
  JorTorItem(letter: 'ج', letterRoman: 'J',  vowelMark: 'ا', vowelRoman: 'a', result: 'جا', resultRoman: 'Jaa', exampleWord: 'جادو', exampleMeaning: 'Magic',       emoji: '🪄'),
  JorTorItem(letter: 'د', letterRoman: 'D',  vowelMark: 'ا', vowelRoman: 'a', result: 'دا', resultRoman: 'Daa', exampleWord: 'دادا', exampleMeaning: 'Grandfather',  emoji: '👴'),
  JorTorItem(letter: 'ر', letterRoman: 'R',  vowelMark: 'ا', vowelRoman: 'a', result: 'را', resultRoman: 'Raa', exampleWord: 'راجہ', exampleMeaning: 'King',        emoji: '🤴'),
  JorTorItem(letter: 'س', letterRoman: 'S',  vowelMark: 'ا', vowelRoman: 'a', result: 'سا', resultRoman: 'Saa', exampleWord: 'سانپ', exampleMeaning: 'Snake',       emoji: '🐍'),
  JorTorItem(letter: 'م', letterRoman: 'M',  vowelMark: 'ا', vowelRoman: 'a', result: 'ما', resultRoman: 'Maa', exampleWord: 'ماں',  exampleMeaning: 'Mother',      emoji: '👩'),
  JorTorItem(letter: 'ن', letterRoman: 'N',  vowelMark: 'ا', vowelRoman: 'a', result: 'نا', resultRoman: 'Naa', exampleWord: 'ناک',  exampleMeaning: 'Nose',        emoji: '👃'),
  JorTorItem(letter: 'ک', letterRoman: 'K',  vowelMark: 'ا', vowelRoman: 'a', result: 'کا', resultRoman: 'Kaa', exampleWord: 'کام',  exampleMeaning: 'Work',        emoji: '💼'),
  JorTorItem(letter: 'گ', letterRoman: 'G',  vowelMark: 'ا', vowelRoman: 'a', result: 'گا', resultRoman: 'Gaa', exampleWord: 'گانا', exampleMeaning: 'Song',        emoji: '🎵'),
  JorTorItem(letter: 'ل', letterRoman: 'L',  vowelMark: 'ا', vowelRoman: 'a', result: 'لا', resultRoman: 'Laa', exampleWord: 'لال',  exampleMeaning: 'Red',         emoji: '🔴'),
  JorTorItem(letter: 'ہ', letterRoman: 'H',  vowelMark: 'ا', vowelRoman: 'a', result: 'ہا', resultRoman: 'Haa', exampleWord: 'ہاتھ', exampleMeaning: 'Hand',        emoji: '✋'),
  JorTorItem(letter: 'ب', letterRoman: 'B',  vowelMark: 'ے', vowelRoman: 'e', result: 'بے', resultRoman: 'Be',  exampleWord: 'بے',   exampleMeaning: 'Without',     emoji: '—'),
  JorTorItem(letter: 'پ', letterRoman: 'P',  vowelMark: 'ے', vowelRoman: 'e', result: 'پے', resultRoman: 'Pe',  exampleWord: 'پیر',  exampleMeaning: 'Monday',      emoji: '📅'),
  JorTorItem(letter: 'ت', letterRoman: 'T',  vowelMark: 'ی', vowelRoman: 'i', result: 'تی', resultRoman: 'Ti',  exampleWord: 'تیر',  exampleMeaning: 'Arrow',       emoji: '🏹'),
  JorTorItem(letter: 'ب', letterRoman: 'B',  vowelMark: 'و', vowelRoman: 'o', result: 'بو', resultRoman: 'Bo',  exampleWord: 'بوند', exampleMeaning: 'Drop',        emoji: '💧'),
  JorTorItem(letter: 'ک', letterRoman: 'K',  vowelMark: 'و', vowelRoman: 'o', result: 'کو', resultRoman: 'Ko',  exampleWord: 'کوا',  exampleMeaning: 'Crow',        emoji: '🐦‍⬛'),
  JorTorItem(letter: 'م', letterRoman: 'M',  vowelMark: 'ی', vowelRoman: 'i', result: 'می', resultRoman: 'Mi',  exampleWord: 'میز',  exampleMeaning: 'Table',       emoji: '🪑'),
  JorTorItem(letter: 'ن', letterRoman: 'N',  vowelMark: 'ے', vowelRoman: 'e', result: 'نے', resultRoman: 'Ne',  exampleWord: 'نے',   exampleMeaning: 'Did',         emoji: '—'),
];
