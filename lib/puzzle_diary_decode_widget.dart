import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════
// PUZZLE: GIẢI MÃ NHẬT KÝ BÙA
// Cuốn nhật ký bị dính nước - vuốt hiện chữ + đọc chữ ngược
// ════════════════════════════════════════════════════════════

class PuzzleDiaryDecodeWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onClose;

  const PuzzleDiaryDecodeWidget({
    super.key,
    required this.onSolved,
    required this.onClose,
  });

  @override
  State<PuzzleDiaryDecodeWidget> createState() =>
      _PuzzleDiaryDecodeWidgetState();
}

class _PuzzleDiaryDecodeWidgetState extends State<PuzzleDiaryDecodeWidget>
    with TickerProviderStateMixin {
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // Các dòng nhật ký cần reveal
  // Dòng 0,1,3 → normal text
  // Dòng 2,4 → chữ ngược (mirror), cần bấm nút xoay
  final List<_DiaryLine> _lines = [
    _DiaryLine('Ngày 15 tháng 7...', false, false),
    _DiaryLine('Đêm đó trời mưa...', false, false),
    _DiaryLine('...iôt tếig ãđ ọH', true, false), // "Họ đã giết tôi..." ngược
    _DiaryLine('Xác tôi bị chôn...', false, false),
    _DiaryLine('...304 gnờưt cứb uas', true, false), // "sau bức tường 403" ngược
  ];

  // Reveal: vuốt lên từng vùng để hiện chữ
  List<bool> _revealed = [false, false, false, false, false];
  List<bool> _flipped = [false, false, false, false, false]; // đã xoay chữ ngược
  int _revealedCount = 0;
  bool _solved = false;
  bool _showFinalMessage = false;

  List<Offset> _scratchPoints = [];
  int _currentScratchLine = 0;

  late AnimationController _pageFlutter;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _pageFlutter = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pageFlutter.dispose();
    _glowController.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _onScratch(DragUpdateDetails details) {
    if (_solved || _currentScratchLine >= 5) return;

    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _scratchPoints.add(localPosition);
    });

    // Sau khi vuốt đủ → reveal dòng hiện tại
    if (_scratchPoints.length > 30) {
      _revealLine(_currentScratchLine);
    }
  }

  void _revealLine(int index) {
    if (index >= 5 || _revealed[index]) return;

    _sfxPlayer.play(AssetSource('scratching.mp3'));
    _sfxPlayer.setVolume(0.3);

    setState(() {
      _revealed[index] = true;
      _revealedCount++;
      _scratchPoints.clear();
      _currentScratchLine++;
    });

    _checkSolved();
  }

  void _flipLine(int index) {
    if (!_lines[index].isMirrored || _flipped[index]) return;

    _sfxPlayer.play(AssetSource('glitch_sound.mp3'));
    _sfxPlayer.setVolume(0.3);

    setState(() {
      _flipped[index] = true;
    });

    _checkSolved();
  }

  void _checkSolved() {
    // Cần reveal hết + flip hết chữ ngược
    bool allRevealed = !_revealed.contains(false);
    bool allFlipped = true;
    for (int i = 0; i < 5; i++) {
      if (_lines[i].isMirrored && !_flipped[i]) {
        allFlipped = false;
      }
    }

    if (allRevealed && allFlipped) {
      setState(() {
        _showFinalMessage = true;
      });

      _sfxPlayer.play(AssetSource('wind_howl.mp3'));
      _sfxPlayer.setVolume(0.6);
      _glowController.forward();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _solved = true);
          Future.delayed(const Duration(seconds: 2), () {
            widget.onSolved();
          });
        }
      });
    }
  }

  String _getFlippedText(String text) {
    // Đảo ngược chuỗi
    return text.split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: AnimatedBuilder(
          animation: _pageFlutter,
          builder: (context, _) {
            double flutter = sin(_pageFlutter.value * pi * 2) * 2;

            return Transform.rotate(
              angle: flutter * 0.003,
              child: Container(
                width: 330,
                height: 520,
                decoration: BoxDecoration(
                  color: const Color(0xFFf5e6c8), // Giấy cũ
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF8B7355),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // ═══ NỀN GIẤY CŨ (vết ố) ═══
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OldPaperPainter(),
                      ),
                    ),

                    // Tiêu đề
                    const Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Text(
                        '📖 NHẬT KÝ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4a3520),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                    // Hướng dẫn
                    Positioned(
                      top: 38,
                      left: 20,
                      right: 20,
                      child: Text(
                        _currentScratchLine < 5
                            ? 'Vuốt để hiện chữ ẩn (dòng ${_currentScratchLine + 1}/5)'
                            : 'Chạm vào chữ đỏ ngược để xoay đọc',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.brown.withOpacity(0.5),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    // ═══ 5 DÒNG NHẬT KÝ ═══
                    Positioned(
                      top: 70,
                      left: 25,
                      right: 25,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(5, (i) => _buildDiaryLine(i)),
                      ),
                    ),

                    // ═══ VÙNG VUỐT (scratch area) ═══
                    if (_currentScratchLine < 5)
                      Positioned(
                        top: 60,
                        left: 20,
                        right: 20,
                        height: 350,
                        child: GestureDetector(
                          onPanUpdate: _onScratch,
                          child: Container(
                            color: Colors.transparent,
                            child: CustomPaint(
                              painter: _ScratchPainter(_scratchPoints),
                            ),
                          ),
                        ),
                      ),

                    // Final message
                    if (_showFinalMessage)
                      Positioned(
                        bottom: 100,
                        left: 20,
                        right: 20,
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[900]!.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(
                                      0.3 * _glowController.value),
                                ),
                              ),
                              child: Text(
                                '"Họ đã giết tôi...\nvà chôn sau bức tường 403"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'HorrorText',
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Solved
                    if (_solved)
                      Positioned.fill(
                        child: Container(
                          color: Colors.red.withOpacity(0.2),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'OÁN',
                                  style: TextStyle(
                                    color: Colors.red[900],
                                    fontSize: 70,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'HorrorText',
                                    shadows: [
                                      Shadow(
                                        blurRadius: 20,
                                        color: Colors.red.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Bí mật đã được giải mã',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Close
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TextButton(
                          onPressed: widget.onClose,
                          child: Text(
                            'Bỏ qua',
                            style: TextStyle(
                              color: Colors.brown.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiaryLine(int index) {
    bool revealed = _revealed[index];
    bool isMirror = _lines[index].isMirrored;
    bool isFlipped = _flipped[index];
    bool isCurrentTarget =
        index == _currentScratchLine && !revealed;

    String displayText;
    if (!revealed) {
      displayText = '▓▓▓▓▓▓▓▓▓▓▓▓';
    } else if (isMirror && !isFlipped) {
      displayText = _lines[index].text;
    } else if (isMirror && isFlipped) {
      displayText = _getFlippedText(_lines[index].text);
    } else {
      displayText = _lines[index].text;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTap: revealed && isMirror && !isFlipped
            ? () => _flipLine(index)
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isCurrentTarget
                ? Colors.brown.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isCurrentTarget
                ? Border.all(color: Colors.brown.withOpacity(0.2))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayText,
                style: TextStyle(
                  color: !revealed
                      ? const Color(0xFFc8b8a0)
                      : isMirror && !isFlipped
                          ? Colors.red[700]
                          : const Color(0xFF3a2510),
                  fontSize: 15,
                  fontFamily: revealed ? 'HorrorText' : null,
                  fontWeight: FontWeight.w500,
                  letterSpacing: revealed ? 1.5 : 0,
                ),
              ),
              if (revealed && isMirror && !isFlipped)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '↻ Chạm để xoay đọc',
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.4),
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (isCurrentTarget)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '↕ Vuốt vào đây',
                    style: TextStyle(
                      color: Colors.brown.withOpacity(0.3),
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Vẽ vết ố trên giấy cũ
class _OldPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(12);

    // Vết ố vàng
    for (int i = 0; i < 8; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double r = 20 + random.nextDouble() * 60;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = const Color(0xFFd4b896).withOpacity(0.15 + random.nextDouble() * 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // Đường kẻ ngang
    final linePaint = Paint()
      ..color = const Color(0xFFc8b8a0).withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (double y = 70; y < size.height - 50; y += 55) {
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 20, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Vẽ vết vuốt (scratch reveal)
class _ScratchPainter extends CustomPainter {
  final List<Offset> points;
  _ScratchPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFa08060).withOpacity(0.3)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15.0;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data model cho dòng nhật ký
class _DiaryLine {
  final String text;
  final bool isMirrored;
  bool isRevealed;

  _DiaryLine(this.text, this.isMirrored, this.isRevealed);
}
