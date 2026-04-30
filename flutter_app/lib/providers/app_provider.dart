import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AppProvider extends ChangeNotifier {
  UserModel? _currentUser;
  List<ProgressModel> _progressHistory = [];
  Map<String, double> _weaknessScores = {};
  Map<String, int> _srsIntervals = {};
  int _currentScreen = 0;

  // ── Getters ──────────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  List<ProgressModel> get progressHistory => List.unmodifiable(_progressHistory);
  Map<String, double> get weaknessScores => Map.unmodifiable(_weaknessScores);
  Map<String, int> get srsIntervals => Map.unmodifiable(_srsIntervals);
  int get currentScreen => _currentScreen;

  String get profileLevel {
    if (_weaknessScores.isEmpty) return 'beginner';
    final mean =
        _weaknessScores.values.reduce((a, b) => a + b) / _weaknessScores.length;
    if (mean > 60) return 'beginner';
    if (mean < 30) return 'advanced';
    return 'intermediate';
  }

  // ── Screen navigation ────────────────────────────────────────────────────
  void setScreen(int i) {
    _currentScreen = i;
    notifyListeners();
  }

  // ── User persistence ─────────────────────────────────────────────────────
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    final progressJson = prefs.getString('progress_history');
    final weaknessJson = prefs.getString('weakness_scores');
    final srsJson = prefs.getString('srs_intervals');

    if (userJson != null) {
      _currentUser =
          UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }

    if (progressJson != null) {
      final list = jsonDecode(progressJson) as List<dynamic>;
      _progressHistory = list
          .map((e) => ProgressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (weaknessJson != null) {
      final raw = jsonDecode(weaknessJson) as Map<String, dynamic>;
      _weaknessScores =
          raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    if (srsJson != null) {
      final raw = jsonDecode(srsJson) as Map<String, dynamic>;
      _srsIntervals = raw.map((k, v) => MapEntry(k, (v as int)));
    }

    notifyListeners();
  }

  Future<void> saveUser() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
    await prefs.setString(
      'progress_history',
      jsonEncode(_progressHistory.map((p) => p.toJson()).toList()),
    );
    await prefs.setString('weakness_scores', jsonEncode(_weaknessScores));
    await prefs.setString('srs_intervals', jsonEncode(_srsIntervals));
  }

  Future<void> setUser(UserModel user) async {
    _currentUser = user;
    notifyListeners();
    await saveUser();
  }

  // ── Spaced-repetition + weakness tracking ────────────────────────────────
  /// EMA update: weakness = 0.7 * old + 0.3 * (100 - score)
  /// A score of 100 means perfect → weakness goes toward 0.
  /// A score of 0 means total failure → weakness goes toward 100.
  void recordResult(String id, double score) {
    final oldScore = _weaknessScores[id] ?? 50.0;
    _weaknessScores[id] = 0.7 * oldScore + 0.3 * (100.0 - score);

    // Simple SRS: good performance (score >= 80) doubles interval; otherwise reset to 1.
    final currentInterval = _srsIntervals[id] ?? 1;
    if (score >= 80) {
      _srsIntervals[id] = (currentInterval * 2).clamp(1, 64);
    } else {
      _srsIntervals[id] = 1;
    }

    notifyListeners();
    saveUser();
  }

  /// Returns the [n] items with the highest weakness scores.
  List<String> weakestItems(int n) {
    final sorted = _weaknessScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  // ── Progress history ─────────────────────────────────────────────────────
  void addProgress(ProgressModel p) {
    _progressHistory.add(p);

    // Update stars on the user model
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        totalStars: _currentUser!.totalStars + p.stars,
        sessionsCompleted: _currentUser!.sessionsCompleted + 1,
        currentLevel: profileLevel,
      );
    }

    notifyListeners();
    saveUser();
  }

  // ── Weak areas sync to UserModel ─────────────────────────────────────────
  void syncWeakAreasToUser() {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      weakAreas: weakestItems(5),
      currentLevel: profileLevel,
    );
    notifyListeners();
    saveUser();
  }
}
