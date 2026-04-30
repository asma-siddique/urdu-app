import '../models/urdu_word.dart';

const List<UrduWord> WORDS = [
  // جانور — Animals
  UrduWord(urdu: 'بلی',          roman: 'Billi',       english: 'Cat',        emoji: '🐱', category: 'جانور', level: 'easy',   target: 'billi'),
  UrduWord(urdu: 'کتا',          roman: 'Kutta',       english: 'Dog',        emoji: '🐶', category: 'جانور', level: 'easy',   target: 'kutta'),
  UrduWord(urdu: 'شیر',          roman: 'Sher',        english: 'Lion',       emoji: '🦁', category: 'جانور', level: 'easy',   target: 'sher'),
  UrduWord(urdu: 'ہاتھی',        roman: 'Haathi',      english: 'Elephant',   emoji: '🐘', category: 'جانور', level: 'medium', target: 'haathi'),
  UrduWord(urdu: 'بندر',         roman: 'Bandar',      english: 'Monkey',     emoji: '🐒', category: 'جانور', level: 'medium', target: 'bandar'),
  UrduWord(urdu: 'مچھلی',        roman: 'Machhli',     english: 'Fish',       emoji: '🐟', category: 'جانور', level: 'medium', target: 'machhli'),
  UrduWord(urdu: 'گائے',         roman: 'Gaaye',       english: 'Cow',        emoji: '🐄', category: 'جانور', level: 'easy',   target: 'gaaye'),
  UrduWord(urdu: 'مرغی',         roman: 'Murghi',      english: 'Chicken',    emoji: '🐔', category: 'جانور', level: 'easy',   target: 'murghi'),
  UrduWord(urdu: 'خرگوش',        roman: 'Khargosh',    english: 'Rabbit',     emoji: '🐰', category: 'جانور', level: 'medium', target: 'khargosh'),
  UrduWord(urdu: 'طوطا',         roman: 'Toota',       english: 'Parrot',     emoji: '🦜', category: 'جانور', level: 'medium', target: 'toota'),
  // کھانا — Food
  UrduWord(urdu: 'آم',           roman: 'Aam',         english: 'Mango',      emoji: '🥭', category: 'کھانا', level: 'easy',   target: 'aam'),
  UrduWord(urdu: 'سیب',          roman: 'Saib',        english: 'Apple',      emoji: '🍎', category: 'کھانا', level: 'easy',   target: 'saib'),
  UrduWord(urdu: 'دودھ',         roman: 'Doodh',       english: 'Milk',       emoji: '🥛', category: 'کھانا', level: 'easy',   target: 'doodh'),
  UrduWord(urdu: 'روٹی',         roman: 'Roti',        english: 'Bread',      emoji: '🫓', category: 'کھانا', level: 'easy',   target: 'roti'),
  UrduWord(urdu: 'کیلا',         roman: 'Kela',        english: 'Banana',     emoji: '🍌', category: 'کھانا', level: 'easy',   target: 'kela'),
  UrduWord(urdu: 'گاجر',         roman: 'Gajar',       english: 'Carrot',     emoji: '🥕', category: 'کھانا', level: 'medium', target: 'gajar'),
  UrduWord(urdu: 'چاول',         roman: 'Chaawal',     english: 'Rice',       emoji: '🍚', category: 'کھانا', level: 'medium', target: 'chaawal'),
  UrduWord(urdu: 'پانی',         roman: 'Paani',       english: 'Water',      emoji: '💧', category: 'کھانا', level: 'easy',   target: 'paani'),
  // فطرت — Nature
  UrduWord(urdu: 'سورج',         roman: 'Suraj',       english: 'Sun',        emoji: '☀️', category: 'فطرت',  level: 'easy',   target: 'suraj'),
  UrduWord(urdu: 'چاند',         roman: 'Chaand',      english: 'Moon',       emoji: '🌙', category: 'فطرت',  level: 'easy',   target: 'chaand'),
  UrduWord(urdu: 'درخت',         roman: 'Darakht',     english: 'Tree',       emoji: '🌳', category: 'فطرت',  level: 'medium', target: 'darakht'),
  UrduWord(urdu: 'پھول',         roman: 'Phool',       english: 'Flower',     emoji: '🌸', category: 'فطرت',  level: 'easy',   target: 'phool'),
  UrduWord(urdu: 'آسمان',        roman: 'Aasmaan',     english: 'Sky',        emoji: '🌌', category: 'فطرت',  level: 'medium', target: 'aasmaan'),
  UrduWord(urdu: 'بارش',         roman: 'Baarish',     english: 'Rain',       emoji: '🌧️', category: 'فطرت',  level: 'easy',   target: 'baarish'),
  // چیزیں — Things
  UrduWord(urdu: 'کتاب',         roman: 'Kitaab',      english: 'Book',       emoji: '📚', category: 'چیزیں', level: 'easy',   target: 'kitaab'),
  UrduWord(urdu: 'قلم',          roman: 'Qalam',       english: 'Pen',        emoji: '✏️', category: 'چیزیں', level: 'easy',   target: 'qalam'),
  UrduWord(urdu: 'گھر',          roman: 'Ghar',        english: 'House',      emoji: '🏠', category: 'چیزیں', level: 'easy',   target: 'ghar'),
  UrduWord(urdu: 'میز',          roman: 'Mez',         english: 'Table',      emoji: '🪑', category: 'چیزیں', level: 'easy',   target: 'mez'),
  UrduWord(urdu: 'گاڑی',         roman: 'Gaari',       english: 'Car',        emoji: '🚗', category: 'چیزیں', level: 'easy',   target: 'gaari'),
  UrduWord(urdu: 'اسکول',        roman: 'Iskool',      english: 'School',     emoji: '🏫', category: 'چیزیں', level: 'medium', target: 'iskool'),
  // جسم — Body
  UrduWord(urdu: 'ہاتھ',         roman: 'Haath',       english: 'Hand',       emoji: '✋', category: 'جسم',   level: 'easy',   target: 'haath'),
  UrduWord(urdu: 'آنکھ',         roman: 'Aankh',       english: 'Eye',        emoji: '👁️', category: 'جسم',   level: 'easy',   target: 'aankh'),
  UrduWord(urdu: 'کان',          roman: 'Kaan',        english: 'Ear',        emoji: '👂', category: 'جسم',   level: 'easy',   target: 'kaan'),
  UrduWord(urdu: 'ناک',          roman: 'Naak',        english: 'Nose',       emoji: '👃', category: 'جسم',   level: 'easy',   target: 'naak'),
  UrduWord(urdu: 'دل',           roman: 'Dil',         english: 'Heart',      emoji: '❤️', category: 'جسم',   level: 'easy',   target: 'dil'),
  UrduWord(urdu: 'سر',           roman: 'Sar',         english: 'Head',       emoji: '🗣️', category: 'جسم',   level: 'easy',   target: 'sar'),
  UrduWord(urdu: 'پاؤں',         roman: 'Paaon',       english: 'Foot',       emoji: '🦶', category: 'جسم',   level: 'medium', target: 'paaon'),
  UrduWord(urdu: 'منہ',          roman: 'Muh',         english: 'Mouth',      emoji: '👄', category: 'جسم',   level: 'easy',   target: 'muh'),
  UrduWord(urdu: 'بال',          roman: 'Baal',        english: 'Hair',       emoji: '💇', category: 'جسم',   level: 'easy',   target: 'baal'),
  UrduWord(urdu: 'دانت',         roman: 'Daant',       english: 'Teeth',      emoji: '🦷', category: 'جسم',   level: 'easy',   target: 'daant'),
];
