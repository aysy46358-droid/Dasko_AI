import 'package:flutter/material.dart';

import 'audio_waveform_widget.dart';

/// Cinematic landing surface for the Dasko AI companion.
///
/// This widget is presentation-only: all visuals are composed from Flutter
/// primitives and it owns no application or audio business logic.
class CinematicScreen extends StatelessWidget {
  const CinematicScreen({super.key});

  static const Color _navy = Color(0xFF030817);
  static const Color _cyan = Color(0xFF35F4F4);
  static const Color _purple = Color(0xFFB56BFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _CosmicBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _cyan.withValues(alpha: 0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _cyan.withValues(alpha: 0.18),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.all_inclusive_rounded,
                          color: _cyan,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'DASKO AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: _cyan, size: 6),
                            SizedBox(width: 7),
                            Text(
                              'LOCAL CORE',
                              style: TextStyle(
                                color: Color(0xFFB7C9E8),
                                fontSize: 9,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final robotHeight = (constraints.maxHeight * 0.76)
                            .clamp(300.0, 570.0)
                            .toDouble();
                        return Center(
                          child: SizedBox(
                            height: robotHeight,
                            width: constraints.maxWidth,
                            child: const _CompanionIllustration(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'YOUR INTELLIGENCE. YOUR SPACE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB7C8E9),
                      fontSize: 10,
                      letterSpacing: 3.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Always here. Always yours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A private companion, powered by you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFB9C5E0).withValues(alpha: 0.78),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const AudioWaveformWidget(
                    barCount: 35,
                    height: 36,
                    color: _cyan,
                    secondaryColor: _purple,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [_cyan, Color(0xFF78C9FF), _purple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withValues(alpha: 0.2),
                          blurRadius: 26,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'ENTER YOUR SPACE',
                        style: TextStyle(
                          color: Color(0xFF061026),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PRIVATE BY DESIGN  •  READY WHEN YOU ARE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 8,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CosmicBackdrop extends StatelessWidget {
  const _CosmicBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.25),
          radius: 1.05,
          colors: [Color(0xFF101A48), Color(0xFF050B20), Color(0xFF020510)],
          stops: [0, 0.52, 1],
        ),
      ),
      child: CustomPaint(
        painter: _StarfieldPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 90; i++) {
      final x = ((i * 73 + 19) % 997) / 997 * size.width;
      final y = ((i * 137 + 31) % 991) / 991 * size.height;
      final radius = i % 11 == 0 ? 1.35 : 0.55;
      paint.color = (i % 3 == 0 ? const Color(0xFF54EFFF) : Colors.white)
          .withValues(alpha: i % 4 == 0 ? 0.65 : 0.24);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    final framePaint = Paint()
      ..color = const Color(0xFF58CFFF).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(28),
    );
    canvas.drawRRect(frame, framePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompanionIllustration extends StatelessWidget {
  const _CompanionIllustration();

  static const Color _cyan = Color(0xFF35F4F4);
  static const Color _purple = Color(0xFFB56BFF);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: width * 0.83,
              height: height * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _purple.withValues(alpha: 0.13),
                    _cyan.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              top: height * 0.01,
              left: width * 0.19,
              child: const _Antenna(color: _cyan, length: 53),
            ),
            Positioned(
              top: height * 0.0,
              right: width * 0.18,
              child: const _Antenna(color: _cyan, length: 67),
            ),
            Positioned(
              top: height * 0.13,
              child: Container(
                width: width * 0.83,
                height: height * 0.48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(74),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFB8FFFF),
                      Color(0xFF38DCEB),
                      Color(0xFF7468E8),
                      Color(0xFFE7A8FF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _cyan.withValues(alpha: 0.27),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _purple.withValues(alpha: 0.2),
                      blurRadius: 45,
                      offset: const Offset(12, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF020615),
                    borderRadius: BorderRadius.circular(65),
                    border: Border.all(
                      color: const Color(0xFF6ABCFB).withValues(alpha: 0.8),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black87, blurRadius: 15),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_HappyEye(), SizedBox(width: 42), _HappyEye()],
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.27,
              left: width * 0.015,
              child: const _EarPiece(),
            ),
            Positioned(
              top: height * 0.28,
              right: width * 0.015,
              child: const _EarPiece(),
            ),
            Positioned(
              top: height * 0.61,
              child: Container(
                width: width * 0.67,
                height: height * 0.36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(75),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFB3FFFF),
                      Color(0xFF27CFE7),
                      Color(0xFF6C6DE8),
                      Color(0xFFC98AFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _cyan.withValues(alpha: 0.17),
                      blurRadius: 30,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Container(
                    width: width * 0.42,
                    height: height * 0.19,
                    decoration: BoxDecoration(
                      color: const Color(0xFF030719),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withValues(alpha: 0.16),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.all_inclusive_rounded,
                      size: 68,
                      color: _cyan,
                      shadows: [
                        Shadow(color: _cyan, blurRadius: 15),
                        Shadow(color: _purple, blurRadius: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: height * 0.0,
              child: Container(
                width: width * 0.56,
                height: 1,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: _cyan.withValues(alpha: 0.8),
                      blurRadius: 24,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Antenna extends StatelessWidget {
  const _Antenna({required this.color, required this.length});

  final Color color;
  final double length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            gradient: const RadialGradient(
              colors: [Colors.white, Color(0xFF68FFFF), Color(0xFF4089FF)],
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 13),
            ],
          ),
        ),
        Container(
          width: 3,
          height: length,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.08)],
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _HappyEye extends StatelessWidget {
  const _HappyEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 28,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF35F4F4), width: 7),
          left: BorderSide(color: Color(0xFF35F4F4), width: 7),
          right: BorderSide(color: Color(0xFF35F4F4), width: 7),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Color(0xFF35F4F4), blurRadius: 16)],
      ),
    );
  }
}

class _EarPiece extends StatelessWidget {
  const _EarPiece();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF9EFFFF), Color(0xFF22D5E8), Color(0xFF8276F8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF35F4F4).withValues(alpha: 0.5),
            blurRadius: 14,
          ),
        ],
      ),
    );
  }
}
