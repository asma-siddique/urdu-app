import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const _darkGreen = Color(0xFF1B4332);
  static const _medGreen  = Color(0xFF2D6A4F);
  static const _amber     = Color(0xFFD4A017);

  // Simulated daily usage minutes (Mon–Sun for current week)
  List<int> _weeklyMinutes = [0, 0, 0, 0, 0, 0, 0];
  int _lessonsCompleted = 0;
  int _streak = 0;
  DateTime? _lastSessionDate;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = context.read<AppProvider>();

    setState(() {
      _lessonsCompleted = provider.currentUser?.sessionsCompleted ?? 0;

      // Load saved weekly minutes
      for (int i = 0; i < 7; i++) {
        _weeklyMinutes[i] = prefs.getInt('weekly_minutes_$i') ?? 0;
      }

      // Load streak
      _streak = prefs.getInt('streak_count') ?? 0;

      final lastStr = prefs.getString('last_session_date');
      if (lastStr != null) {
        _lastSessionDate = DateTime.tryParse(lastStr);
      }
    });

    // Record today's session (at least 1 min)
    _recordTodayUsage();
  }

  Future<void> _recordTodayUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dayIndex = now.weekday - 1; // Mon=0 … Sun=6

    // Add some minutes for the current session
    final current = prefs.getInt('weekly_minutes_$dayIndex') ?? 0;
    // Only add if user has done something meaningful (has progress)
    final provider = context.read<AppProvider>();
    if (provider.progressHistory.isNotEmpty) {
      await prefs.setInt('weekly_minutes_$dayIndex', current + 2);
    }

    // Streak calculation
    final lastStr = prefs.getString('last_session_date');
    int streak = prefs.getInt('streak_count') ?? 0;
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null) {
        final diff = now.difference(last).inDays;
        if (diff == 1) {
          streak += 1;
        } else if (diff > 1) {
          streak = 1;
        }
        // diff == 0 means same day, don't change streak
      }
    } else {
      streak = 1;
    }

    await prefs.setString('last_session_date', now.toIso8601String());
    await prefs.setInt('streak_count', streak);

    if (mounted) {
      setState(() {
        _weeklyMinutes[dayIndex] = prefs.getInt('weekly_minutes_$dayIndex') ?? 0;
        _streak = streak;
      });
    }
  }

  int get _totalWeeklyMinutes => _weeklyMinutes.reduce((a, b) => a + b);
  double get _dailyAverageMinutes => _totalWeeklyMinutes / 7.0;
  int get _maxMinutes => _weeklyMinutes.reduce(max).clamp(1, 9999);

  String _formatDuration(double minutes) {
    final h = minutes ~/ 60;
    final m = minutes.round() % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIndex = DateTime.now().weekday - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Your Progress',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Weekly Learning Time ──────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Weekly Learning Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDuration(_totalWeeklyMinutes.toDouble()),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Daily Average  ',
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                      Text(
                        _formatDuration(_dailyAverageMinutes),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Average Time you spent per day using Urdu\nUstaad app on this device in the last week',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 20),

                  // Bar chart
                  SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final mins = _weeklyMinutes[i];
                        final ratio = mins / _maxMinutes;
                        final isToday = i == todayIndex;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  width: 28,
                                  height: (80 * ratio).clamp(4.0, 80.0),
                                  decoration: BoxDecoration(
                                    color: isToday ? _amber : _medGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              days[i],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday ? _amber : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Learning Progress ─────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Learning Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBadge(
                          value: '$_lessonsCompleted',
                          label: 'Lessons\nCompleted',
                          color: _darkGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatBadge(
                          value: '$_streak',
                          label: 'Streak',
                          color: _amber,
                          suffix: '🔥',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Level Badge ───────────────────────────────────────────────
            Consumer<AppProvider>(
              builder: (ctx, provider, _) {
                final level = provider.profileLevel;
                final levelEmoji = {
                  'beginner': '🌱',
                  'intermediate': '⚡',
                  'advanced': '🏆',
                }[level] ?? '🌱';
                return _SectionCard(
                  child: Row(
                    children: [
                      Text(levelEmoji, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level[0].toUpperCase() + level.substring(1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const Text(
                            'Current Level',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Recent sessions ───────────────────────────────────────────
            Consumer<AppProvider>(
              builder: (ctx, provider, _) {
                final history = provider.progressHistory.reversed.take(5).toList();
                if (history.isEmpty) return const SizedBox.shrink();

                return _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Sessions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...history.map((p) => _SessionRow(progress: p)),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final String? suffix;
  const _StatBadge({
    required this.value,
    required this.label,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(suffix!, style: const TextStyle(fontSize: 20)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final dynamic progress;
  const _SessionRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2D6A4F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              progress.module ?? 'Lesson',
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFD4A017), size: 14),
              Text(
                ' ${progress.stars ?? 0}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}