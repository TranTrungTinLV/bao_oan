import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════
// PUZZLE: BÙA NGÃI KHƠ ME
// Xếp chữ Khmer đúng thứ tự để giải trừ bùa ngãi rắn thần Naga
// ════════════════════════════════════════════════════════════

class PuzzleKhmerCharmWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onClose;

  const PuzzleKhmerCharmWidget({
    super.key,
    required this.onSolved,
    required this.onClose,
  });

  @override
  State<PuzzleKhmerCharmWidget> createState() => _PuzzleKhmerCharmWidgetState();
}

class _PuzzleKhmerCharmWidgetState extends State<PuzzleKhmerCharmWidget>
    with TickerProviderStateMixin {
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // Chữ Khmer: នាគ បាល If the user needs to rearrange
  // Naga (នាគ) = rắn thần bảo hộ trong tín ngưỡng Khmer
  static const List<String> _correctOrder = ['න', 'ា', 'គ', ' ', 'រ', 'ក្', 'ស', 'ា'];
  // Simplified: 6 ký tự chính cần xếp
  static const List<String> _khmerChars = ['នា', 'គ', 'រក្', 'សា', 'ព', 'ល'];
  static const List<String> _correctChars = ['នា', 'គ', 'រក្', 'សា', 'ព', 'ល'];
  // Đáp án: នាគ រក្សា ពល = Naga bảo hộ sức mạnh

  late List<String> _shuffledChars;
  List<String?> _placedChars = List.filled(6, null);
  bool _solved = false;
  bool _showHint = false;
  double _glowIntensity = 0.0;
  int _wrongAttempts = 0;

  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _shuffledChars = List.from(_correctChars);
    _shuffledChars.shuffle(Random());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _onCharDropped(int slotIndex, String char) {
    if (_solved) return;

    setState(() {
      // Nếu ô đã có chữ, trả lại pool
      if (_placedChars[slotIndex] != null) {
        _shuffledChars.add(_placedChars[slotIndex]!);
      }
      _placedChars[slotIndex] = char;
      _shuffledChars.remove(char);
    });

    // Check nếu đã đặt hết
    if (!_placedChars.contains(null)) {
      _checkSolution();
    }
  }

  void _returnChar(int slotIndex) {
    if (_solved || _placedChars[slotIndex] == null) return;
    setState(() {
      _shuffledChars.add(_placedChars[slotIndex]!);
      _placedChars[slotIndex] = null;
    });
  }

  void _checkSolution() {
    bool correct = true;
    for (int i = 0; i < 6; i++) {
      if (_placedChars[i] != _correctChars[i]) {
        correct = false;
        break;
      }
    }

    if (correct) {
      setState(() => _solved = true);
      _sfxPlayer.play(AssetSource('chanting_nam_mo.mp3'));
      _sfxPlayer.setVolume(0.6);
      _glowController.forward();
      Future.delayed(const Duration(seconds: 3), () {
        widget.onSolved();
      });
    } else {
      _wrongAttempts++;
      _sfxPlayer.play(AssetSource('glitch_sound.mp3'));
      _sfxPlayer.setVolume(0.5);

      // Show hint after 2 wrong attempts
      if (_wrongAttempts >= 2) {
        setState(() => _showHint = true);
      }

      // Reset sau 1 giây
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            for (var char in _placedChars) {
              if (char != null) _shuffledChars.add(char);
            }
            _placedChars = List.filled(6, null);
            _shuffledChars.shuffle(Random());
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 340,
              height: 520,
              decoration: BoxDecoration(
                color: const Color(0xFF1a0a00),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _solved
                      ? Colors.amber.withOpacity(0.8)
                      : Colors.red[900]!.withOpacity(0.5 + _pulseController.value * 0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _solved
                        ? Colors.amber.withOpacity(0.4)
                        : Colors.red.withOpacity(0.2 + _pulseController.value * 0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Nền hoa văn Khmer
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.08,
                      child: CustomPaint(
                        painter: _KhmerPatternPainter(),
                      ),
                    ),
                  ),

                  // Tiêu đề
                  const Positioned(
                    top: 15,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          '☸ BÙA NGÃI KHƠ ME ☸',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Xếp chữ Khmer đúng thứ tự\nđể giải trừ bùa ngãi Naga',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hình Naga gợi ý (hiện mờ)
                  Positioned(
                    top: 80,
                    left: 70,
                    right: 70,
                    child: Opacity(
                      opacity: _showHint ? 0.25 : 0.08,
                      child: const Text(
                        '🐍',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 80),
                      ),
                    ),
                  ),

                  // Hint text
                  if (_showHint)
                    Positioned(
                      top: 85,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Gợi ý: Naga bảo hộ sức mạnh\nnàគ រក្សាពល',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                  // ═══ 6 Ô DROP TARGET ═══
                  Positioned(
                    top: 180,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        const Text(
                          'Đặt chữ vào lá bùa:',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: List.generate(6, (i) => _buildDropSlot(i)),
                        ),
                      ],
                    ),
                  ),

                  // ═══ Draggable chars pool ═══
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        const Text(
                          'Ký tự Khmer:',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _shuffledChars.map((c) => _buildDraggableChar(c)).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Solved overlay
                  if (_solved)
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, _) {
                        return Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.amber.withOpacity(0.15 * _glowController.value),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '☸ GIẢI TRỪ ☸',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 5,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 20 * _glowController.value,
                                          color: Colors.amber,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Bùa ngãi đã được hóa giải',
                                    style: TextStyle(color: Colors.white54, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Wrong attempt flash
                  if (_wrongAttempts > 0 && !_solved)
                    Positioned(
                      top: 165,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Sai! Thử lại... ($_wrongAttempts)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Close button
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TextButton(
                        onPressed: widget.onClose,
                        child: const Text('Bỏ qua', style: TextStyle(color: Colors.white38)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropSlot(int index) {
    bool hasChar = _placedChars[index] != null;

    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => _returnChar(index),
          child: Container(
            width: 45,
            height: 50,
            decoration: BoxDecoration(
              color: hasChar
                  ? const Color(0xFF2a1a00)
                  : isHovering
                      ? Colors.amber.withOpacity(0.15)
                      : const Color(0xFF0d0800),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasChar
                    ? Colors.amber.withOpacity(0.6)
                    : isHovering
                        ? Colors.amber.withOpacity(0.5)
                        : Colors.red[900]!.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                hasChar ? _placedChars[index]! : '${index + 1}',
                style: TextStyle(
                  color: hasChar ? Colors.amber : Colors.white12,
                  fontSize: hasChar ? 20 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
      onWillAcceptWithDetails: (details) => !_solved,
      onAcceptWithDetails: (details) => _onCharDropped(index, details.data),
    );
  }

  Widget _buildDraggableChar(String char) {
    return Draggable<String>(
      data: char,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 15),
            ],
          ),
          child: Center(
            child: Text(
              char,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
      ),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF1a0d00),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(
            char,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Vẽ hoa văn Khmer ở nền
class _KhmerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Vẽ hoa văn hình tròn đồng tâm
    for (double r = 30; r < size.width; r += 40) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        r,
        paint,
      );
    }

    // Vẽ đường chéo giao nhau
    for (int i = 0; i < 8; i++) {
      double angle = i * pi / 4;
      canvas.drawLine(
        Offset(size.width / 2, size.height / 2),
        Offset(
          size.width / 2 + cos(angle) * size.width,
          size.height / 2 + sin(angle) * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
