import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _floatCtrl;
  late AnimationController _starCtrl;
  late Animation<double> _floatAnim;

  final Random _rng = Random();
  final List<_Star> _stars = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    // Teacher floating animation
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Background stars
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    for (int i = 0; i < 18; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 14 + 6,
        speed: _rng.nextDouble() * 0.4 + 0.6,
        emoji: ['⭐', '🌟', '✨', '💫'][_rng.nextInt(4)],
      ));
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _starCtrl.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onStart() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);

    final provider = context.read<AppProvider>();
    await provider.setUser(UserModel(
      id: const Uuid().v4(),
      name: name,
      avatar: '🧑‍🎓',
      createdAt: DateTime.now(),
    ));

    // Greet by name
    await TtsService.instance.speak('خوش آمدید $name! آپ کا استقبال ہے۔');

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4a0080),
              Color(0xFF9b5de5),
              Color(0xFFf15bb5),
              Color(0xFFffe66d),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating stars background
            ...List.generate(_stars.length, (i) {
              final star = _stars[i];
              return AnimatedBuilder(
                animation: _starCtrl,
                builder: (ctx, _) {
                  final yOffset = sin(_starCtrl.value * pi * 2 * star.speed) * 10;
                  return Positioned(
                    left: star.x * size.width,
                    top: star.y * size.height + yOffset,
                    child: Opacity(
                      opacity: 0.5 + 0.5 * sin(_starCtrl.value * pi * star.speed),
                      child: Text(star.emoji,
                          style: TextStyle(fontSize: star.size)),
                    ),
                  );
                },
              );
            }),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // App title
                    const Text(
                      'اردو سیکھیں',
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const Text(
                      'Urdu Seekhain',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Teacher avatar (floating)
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (ctx, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
                      child: _buildTeacherAvatar(),
                    ),

                    const SizedBox(height: 28),

                    // White card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Greeting
                            const Text(
                              'آپ کا نام کیا ہے؟',
                              style: TextStyle(
                                fontFamily: 'NotoNastaliqUrdu',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4a0080),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'What is your name?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name input
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4a0080),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ali / عائشہ / Sara',
                                hintStyle: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3E8FF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF9b5de5),
                                    width: 2.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('🌟', style: TextStyle(fontSize: 24)),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _onStart(),
                            ),

                            const SizedBox(height: 24),

                            // Start button
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _onStart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9b5de5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 6,
                                  shadowColor:
                                      const Color(0xFF9b5de5).withOpacity(0.5),
                                ),
                                child: _loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        'شروع کریں  🚀',
                                        style: TextStyle(
                                          fontFamily: 'NotoNastaliqUrdu',
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Text(
                              'For KG & Nursery Students',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bottom row of emojis
                    const Text(
                      '📚  🎨  🔤  🎵  🌟  🦁  🍎  🎮',
                      style: TextStyle(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherAvatar() {
    // Try to load the teacher image; fall back to a nice emoji circle
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow ring
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.35),
                Colors.white.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Teacher image or emoji fallback
        ClipOval(
          child: Image.asset(
            'assets/images/teacher.png',
            width: 155,
            height: 155,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 155,
              height: 155,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF9b5de5), Color(0xFFf15bb5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text('👩‍🏫', style: TextStyle(fontSize: 80)),
              ),
            ),
          ),
        ),
        // Stars around the avatar
        ...List.generate(6, (i) {
          final angle = i * pi / 3;
          return Positioned(
            left: 90 + 86 * cos(angle) - 12,
            top: 90 + 86 * sin(angle) - 12,
            child: Text(
              ['⭐', '🌟', '✨', '💫', '⭐', '🌟'][i],
              style: const TextStyle(fontSize: 18),
            ),
          );
        }),
      ],
    );
  }
}

class _Star {
  final double x, y, size, speed;
  final String emoji;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.emoji,
  });
}
