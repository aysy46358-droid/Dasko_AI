import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'interactive_dasko_robot.dart';
import 'chat_screen.dart';

class DaskoIntroScreen extends StatefulWidget {
  const DaskoIntroScreen({super.key});

  @override
  State<DaskoIntroScreen> createState() => _DaskoIntroScreenState();
}

class _DaskoIntroScreenState extends State<DaskoIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    _playWelcomeIfAvailable();
  }

  Future<void> _playWelcomeIfAvailable() async {
    // The recording is optional. Missing audio must never block app startup.
    try {
      await _audioPlayer.play(AssetSource('sounds/welcome.mp3'));
    } catch (_) {
      // Continue silently until assets/sounds/welcome.mp3 is supplied.
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _orbit.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startChat() {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => const ChatScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entrance, _orbit]),
          builder: (context, _) {
            final entrance = Curves.easeOutCubic.transform(_entrance.value);
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DigitalSpacePainter(rotation: _orbit.value),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: entrance,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - entrance)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'DASKO AI',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                                color: Color(0xFF00E5FF),
                                shadows: [
                                  Shadow(color: Color(0xFF00E5FF), blurRadius: 22),
                                  Shadow(color: Color(0xFF7C4DFF), blurRadius: 34),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 260,
                              width: 260,
                              child: AnimatedBuilder(
                                animation: _orbit,
                                builder: (context, _) => Transform.rotate(
                                  angle: _orbit.value * math.pi * 2,
                                  child: const _HologramRing(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const InteractiveDaskoRobot(
                              state: DaskoRobotState.ready,
                              size: 112,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'أهلاً بك يا أبو خالد',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'أنا داسكو، رفيقك الذكي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFFB8C5DF),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _startChat,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text('ابدأ المحادثة'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BFD8),
                                  foregroundColor: const Color(0xFF061018),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'محلي • تجريبي • دون اتصال بالخادم',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HologramRing extends StatelessWidget {
  const _HologramRing();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x6600E5FF), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x4400E5FF), blurRadius: 28, spreadRadius: 2),
            BoxShadow(color: Color(0x337C4DFF), blurRadius: 44, spreadRadius: 6),
          ],
          gradient: const RadialGradient(
            colors: [Color(0x223F51B5), Color(0x000B0F19)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.hub_rounded, size: 100, color: Color(0xFF00E5FF)),
        ),
      );
}

class _DigitalSpacePainter extends CustomPainter {
  const _DigitalSpacePainter({required this.rotation});
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;
    for (var i = 0; i < 18; i++) {
      final x = (i * 47.0 + rotation * 90) % size.width;
      final y = (i * 83.0) % size.height;
      paint.color = i.isEven
          ? const Color(0x5500E5FF)
          : const Color(0x447C4DFF);
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 2 : 1, paint);
    }
    paint
      ..color = const Color(0x2200E5FF)
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.48),
          width: size.width * i * 0.24,
          height: size.height * i * 0.12,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DigitalSpacePainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
