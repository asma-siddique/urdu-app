import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AvatarEmotion { neutral, happy, sad, thinking, excited, speaking }

/// Animated professor avatar with emotion-driven visuals and speech bubble.
/// Use a [GlobalKey<ProfessorAvatarState>] to call [speak(text)] externally.
class ProfessorAvatar extends StatefulWidget {
  final AvatarEmotion emotion;
  final double size;
  final String? speechText;

  const ProfessorAvatar({
    super.key,
    this.emotion = AvatarEmotion.neutral,
    this.size = 110,
    this.speechText,
  });

  @override
  State<ProfessorAvatar> createState() => ProfessorAvatarState();
}

class ProfessorAvatarState extends State<ProfessorAvatar>
    with TickerProviderStateMixin {
  // ── Animations ────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;   // speaking pulse
  late AnimationController _bounceCtrl;  // happy bounce
  late AnimationController _shakeCtrl;   // sad shake

  late Animation<double> _pulseAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _shakeAnim;

  String _bubble = '';

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _updateAnimations(widget.emotion);
  }

  @override
  void didUpdateWidget(ProfessorAvatar old) {
    super.didUpdateWidget(old);
    if (old.emotion != widget.emotion) _updateAnimations(widget.emotion);
    if (old.speechText != widget.speechText && widget.speechText != null) {
      setState(() => _bubble = widget.speechText!);
    }
  }

  void _updateAnimations(AvatarEmotion emotion) {
    switch (emotion) {
      case AvatarEmotion.speaking:
        if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
        break;
      case AvatarEmotion.happy:
      case AvatarEmotion.excited:
        _pulseCtrl.stop();
        _bounceCtrl.forward(from: 0);
        break;
      case AvatarEmotion.sad:
        _pulseCtrl.stop();
        _shakeCtrl.forward(from: 0);
        break;
      default:
        _pulseCtrl.stop();
    }
  }

  /// Call from outside via GlobalKey to show a speech bubble.
  void speak(String text) {
    setState(() => _bubble = text.length > 35 ? '${text.substring(0, 33)}…' : text);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _bubble = '');
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  String get _emoji {
    switch (widget.emotion) {
      case AvatarEmotion.happy:    return '😄';
      case AvatarEmotion.excited:  return '🤩';
      case AvatarEmotion.sad:      return '😔';
      case AvatarEmotion.thinking: return '🤔';
      case AvatarEmotion.speaking: return '🗣️';
      case AvatarEmotion.neutral:
      default:                     return '🧑‍🏫';
    }
  }

  Color get _ringColor {
    switch (widget.emotion) {
      case AvatarEmotion.happy:
      case AvatarEmotion.excited:  return AppTheme.green;
      case AvatarEmotion.sad:      return Colors.redAccent;
      case AvatarEmotion.speaking: return AppTheme.teal;
      case AvatarEmotion.thinking: return AppTheme.yellow;
      default:                     return AppTheme.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Speech bubble ──────────────────────────────────────────────
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _bubble.isNotEmpty ? 1.0 : 0.0,
          child: Container(
            constraints: BoxConstraints(maxWidth: widget.size * 2.2),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.purple.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                _bubble,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 13,
                  color: Color(0xFF1a1a2e),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // ── Avatar body ────────────────────────────────────────────────
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnim, _bounceAnim, _shakeAnim]),
          builder: (context, child) {
            double scale = 1.0;
            double offsetX = 0.0;

            if (widget.emotion == AvatarEmotion.speaking) {
              scale = _pulseAnim.value;
            } else if (widget.emotion == AvatarEmotion.happy ||
                widget.emotion == AvatarEmotion.excited) {
              scale = _bounceCtrl.isAnimating ? _bounceAnim.value : 1.0;
            } else if (widget.emotion == AvatarEmotion.sad) {
              offsetX = _shakeCtrl.isAnimating ? _shakeAnim.value : 0.0;
            }

            return Transform.translate(
              offset: Offset(offsetX, 0),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _ringColor.withOpacity(0.3),
                  _ringColor.withOpacity(0.08),
                ],
              ),
              border: Border.all(color: _ringColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _ringColor.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/teacher.png',
                width: widget.size * 0.86,
                height: widget.size * 0.86,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    _emoji,
                    style: TextStyle(fontSize: widget.size * 0.48),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
