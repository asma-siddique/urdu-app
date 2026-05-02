import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _avatars = ['👦', '👧', '🧒', '👶', '🧑', '👩', '👨'];
  int _avatarIdx = 0;
  late TextEditingController _nameCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final name = context.read<AppProvider>().userName;
    _nameCtrl = TextEditingController(text: name);
    // Pick a consistent avatar from the name
    _avatarIdx = name.isNotEmpty ? name.codeUnitAt(0) % _avatars.length : 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName() {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      context.read<AppProvider>().updateUserName(name);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final name = provider.userName;
    final level = provider.profileLevel;
    final history = provider.progressHistory;
    final totalItems = history.length;
    final avgScore = history.isEmpty
        ? 0.0
        : history.map((p) => p.score.toDouble()).fold(0.0, (a, b) => a + b) /
            history.length;

    final levelData = {
      'beginner':     ('🌱', 'Beginner',     const Color(0xFF10B981)),
      'intermediate': ('⚡', 'Intermediate', const Color(0xFF0EA5E9)),
      'advanced':     ('🏆', 'Advanced',     const Color(0xFFF59E0B)),
    }[level] ?? ('🌱', 'Beginner', const Color(0xFF10B981));

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF4),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1917),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ── Avatar + name header ─────────────────────────────────────
              Container(
                width: double.infinity,
                color: const Color(0xFF1C1917),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    // Avatar circle
                    GestureDetector(
                      onTap: () => setState(
                          () => _avatarIdx = (_avatarIdx + 1) % _avatars.length),
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: levelData.$3.withOpacity(0.2),
                          border: Border.all(color: levelData.$3, width: 3),
                        ),
                        child: Center(
                          child: Text(_avatars[_avatarIdx],
                              style: const TextStyle(fontSize: 44)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('tap to change',
                        style: TextStyle(fontSize: 10, color: Colors.white38)),
                    const SizedBox(height: 12),

                    // Name / edit
                    if (_editing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _nameCtrl,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18,
                                  fontWeight: FontWeight.w700),
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white54)),
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white54)),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white)),
                              ),
                              onSubmitted: (_) => _saveName(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _saveName,
                            icon: const Icon(Icons.check_rounded,
                                color: Colors.greenAccent, size: 22),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name.isNotEmpty ? name : 'Student',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _editing = true),
                            child: const Icon(Icons.edit_rounded,
                                color: Colors.white54, size: 18),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: levelData.$3.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: levelData.$3.withOpacity(0.5)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(levelData.$1,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(levelData.$2,
                            style: TextStyle(
                                color: levelData.$3,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                    ),
                  ],
                ),
              ),

              // ── Stats grid ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(child: _StatCard(
                        icon: Icons.check_circle_rounded,
                        value: '$totalItems',
                        label: 'Items Practiced',
                        color: const Color(0xFF10B981),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        icon: Icons.mic_rounded,
                        value: '${avgScore.toInt()}%',
                        label: 'Avg Accuracy',
                        color: const Color(0xFF8B5CF6),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '${provider.currentUser?.sessionsCompleted ?? 0}',
                        label: 'Sessions Done',
                        color: const Color(0xFFF97316),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        icon: Icons.star_rounded,
                        value: level == 'advanced'
                            ? '🏆'
                            : level == 'intermediate'
                                ? '⚡'
                                : '🌱',
                        label: 'Level',
                        color: levelData.$3,
                        isEmoji: true,
                      )),
                    ]),
                    const SizedBox(height: 24),

                    // ── Recent activity ──────────────────────────────────
                    if (history.isNotEmpty) ...[
                      const Text('Recent Activity',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1917))),
                      const SizedBox(height: 10),
                      ...history.reversed.take(8).map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic_rounded,
                                color: Color(0xFF8B5CF6), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                p.module ?? '—',
                                style: const TextStyle(
                                    fontFamily: 'NotoNastaliqUrdu',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: p.score >= 70
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${p.score}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.score >= 70
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ]),
                      )),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(children: [
                          const Text('📚',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          const Text(
                            'No activity yet\nStart a lesson to track your progress!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF9CA3AF)),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Reset button ─────────────────────────────────────
                    OutlinedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reset Progress?'),
                          content: const Text(
                              'This will clear all your scores and history. This cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () {
                                  context
                                      .read<AppProvider>()
                                      .clearProgress();
                                  Navigator.pop(ctx);
                                },
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Reset')),
                          ],
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reset Progress'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isEmoji;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        isEmoji
            ? Text(value, style: const TextStyle(fontSize: 28))
            : Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF9CA3AF))),
      ]),
    );
  }
}
