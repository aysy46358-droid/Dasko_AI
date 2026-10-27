import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'chat_screen.dart';
import 'digital_space_background.dart';
import 'interactive_dasko_robot.dart';

class DaskoIntroScreen extends StatefulWidget {
  const DaskoIntroScreen({super.key});

  @override
  State<DaskoIntroScreen> createState() => _DaskoIntroScreenState();
}

class _DaskoIntroScreenState extends State<DaskoIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _openingChat = false;
  bool _welcomeAttempted = false;

  @override
  void initState() {
    super.initState();
    unawaited(_playWelcome());
  }

  Future<void> _playWelcome() async {
    if (_welcomeAttempted) return;
    _welcomeAttempted = true;

    // The short local chime is independent of speech. Missing device TTS
    // support must not prevent the app from opening.
    try {
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.play(AssetSource('sounds/welcome.wav'));
    } catch (_) {
      // Speech is still attempted when the optional sound effect fails.
    }

    try {
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.43);
      await _tts.setVolume(0.9);
      await _tts.setPitch(1.0);
      await _tts.speak('أهلاً بك يا داسكو.');
    } catch (_) {
      // Android needs an installed Arabic TTS voice. Fail silently and keep
      // the welcome screen usable when that voice is unavailable.
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    unawaited(_audioPlayer.dispose());
    unawaited(_tts.stop());
    super.dispose();
  }

  void _startChat() {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    unawaited(_tts.stop());

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) => const ChatScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: DigitalSpaceBackground(
          child: AnimatedBuilder(
            animation: _entrance,
            builder: (context, _) {
              final entrance =
                  Curves.easeOutCubic.transform(_entrance.value);
              return Opacity(
                opacity: entrance,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - entrance)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final robotSize =
                          constraints.maxHeight < 650 ? 205.0 : 245.0;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 42,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                'DASKO AI',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                  color: Color(0xFF00E5FF),
                                  shadows: [
                                    Shadow(
                                      color: Color(0xAA00E5FF),
                                      blurRadius: 22,
                                    ),
                                    Shadow(
                                      color: Color(0x887C4DFF),
                                      blurRadius: 34,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              InteractiveDaskoRobot(
                                state: DaskoRobotState.ready,
                                size: robotSize,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'أهلاً بك يا داسكو.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x7700E5FF),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _openingChat ? null : _startChat,
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('ابدأ المحادثة'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF00D4E8),
                                    foregroundColor: const Color(0xFF061018),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
