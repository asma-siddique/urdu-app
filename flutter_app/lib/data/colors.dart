import 'package:flutter/material.dart';
import '../models/urdu_color.dart';
import '../models/urdu_word.dart';

const List<UrduColor> COLORS = [
  UrduColor(urdu: 'سرخ',    english: 'Red',      color: Color(0xFFEF233C), emoji: '🔴'),
  UrduColor(urdu: 'نیلا',   english: 'Blue',     color: Color(0xFF0077B6), emoji: '🔵'),
  UrduColor(urdu: 'سبز',    english: 'Green',    color: Color(0xFF2DC653), emoji: '🟢'),
  UrduColor(urdu: 'پیلا',   english: 'Yellow',   color: Color(0xFFFEE440), emoji: '🟡'),
  UrduColor(urdu: 'نارنجی', english: 'Orange',   color: Color(0xFFFF6D00), emoji: '🟠'),
  UrduColor(urdu: 'بنفشی',  english: 'Purple',   color: Color(0xFF9B5DE5), emoji: '🟣'),
  UrduColor(urdu: 'گلابی',  english: 'Pink',     color: Color(0xFFF15BB5), emoji: '🩷'),
  UrduColor(urdu: 'سفید',   english: 'White',    color: Color(0xFFFFFFFF), emoji: '⬜'),
  UrduColor(urdu: 'کالا',   english: 'Black',    color: Color(0xFF212529), emoji: '⬛'),
  UrduColor(urdu: 'بھورا',  english: 'Brown',    color: Color(0xFF6D4C41), emoji: '🟤'),
  UrduColor(urdu: 'آسمانی', english: 'Sky Blue', color: Color(0xFF00BBF9), emoji: '🩵'),
  UrduColor(urdu: 'سنہری',  english: 'Golden',   color: Color(0xFFFFD700), emoji: '🌟'),
  UrduColor(urdu: 'چاندی',  english: 'Silver',   color: Color(0xFFADB5BD), emoji: '🩶'),
  UrduColor(urdu: 'جامنی',  english: 'Maroon',   color: Color(0xFF800000), emoji: '🟥'),
  UrduColor(urdu: 'لال',    english: 'Crimson',  color: Color(0xFFDC143C), emoji: '❤️'),
];

/// UrduWord versions of colors — used by the Colors Quiz screen
const List<UrduWord> COLORS_WORDS = [
  UrduWord(urdu: 'سرخ',    roman: 'Surkh',    english: 'Red',      emoji: '🔴', category: 'رنگ', level: 'easy',   target: 'surkh'),
  UrduWord(urdu: 'نیلا',   roman: 'Neela',    english: 'Blue',     emoji: '🔵', category: 'رنگ', level: 'easy',   target: 'neela'),
  UrduWord(urdu: 'سبز',    roman: 'Sabz',     english: 'Green',    emoji: '🟢', category: 'رنگ', level: 'easy',   target: 'sabz'),
  UrduWord(urdu: 'پیلا',   roman: 'Peela',    english: 'Yellow',   emoji: '🟡', category: 'رنگ', level: 'easy',   target: 'peela'),
  UrduWord(urdu: 'نارنجی', roman: 'Naranji',  english: 'Orange',   emoji: '🟠', category: 'رنگ', level: 'medium', target: 'naranji'),
  UrduWord(urdu: 'بنفشی',  roman: 'Banafshi', english: 'Purple',   emoji: '🟣', category: 'رنگ', level: 'medium', target: 'banafshi'),
  UrduWord(urdu: 'گلابی',  roman: 'Gulabi',   english: 'Pink',     emoji: '🩷', category: 'رنگ', level: 'easy',   target: 'gulabi'),
  UrduWord(urdu: 'سفید',   roman: 'Safaid',   english: 'White',    emoji: '⬜', category: 'رنگ', level: 'easy',   target: 'safaid'),
  UrduWord(urdu: 'کالا',   roman: 'Kaala',    english: 'Black',    emoji: '⬛', category: 'رنگ', level: 'easy',   target: 'kaala'),
  UrduWord(urdu: 'بھورا',  roman: 'Bhoora',   english: 'Brown',    emoji: '🟤', category: 'رنگ', level: 'medium', target: 'bhoora'),
  UrduWord(urdu: 'آسمانی', roman: 'Aasmani',  english: 'Sky Blue', emoji: '🩵', category: 'رنگ', level: 'medium', target: 'aasmani'),
  UrduWord(urdu: 'سنہری',  roman: 'Sonehari', english: 'Golden',   emoji: '🌟', category: 'رنگ', level: 'hard',   target: 'sonehari'),
];
