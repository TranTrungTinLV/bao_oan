import 'package:bao_oan/play_game_screen.dart';
import 'package:bao_oan/trailer_fpv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeGame extends StatefulWidget {
  static String id = 'home_game';
  const HomeGame({super.key});

  @override
  State<HomeGame> createState() => _HomeGameState();
}

class _HomeGameState extends State<HomeGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.85),
              ],
              radius: 1.2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Game title
                const Text(
                  'BÁO OAN',
                  style: TextStyle(
                    fontFamily: 'HorrorText',
                    fontSize: 60,
                    color: Colors.white,
                    letterSpacing: 10,
                    shadows: [
                      Shadow(blurRadius: 25, color: Color(0xFFcc0000)),
                      Shadow(blurRadius: 5, color: Colors.black, offset: Offset(3, 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // ── Play Demo Button ──
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, PlayGameScreen.id);
                  },
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.2 + _pulseController.value * 0.1),
                              Colors.red.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5 + _pulseController.value * 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1 + _pulseController.value * 0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'CHƠI DEMO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                letterSpacing: 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Coming Soon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.4 + _pulseController.value * 0.6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.withOpacity(0.4), width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DỰ KIẾN CUỐI QUÝ 4',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Replay trailer
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, 'splash_game');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.replay, color: Colors.white30, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Xem lại Trailer',
                          style: TextStyle(color: Colors.white30, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Trailer FPV - Góc nhìn thứ nhất
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, TrailerFPV.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '🎬 Trailer Đặc Biệt',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
