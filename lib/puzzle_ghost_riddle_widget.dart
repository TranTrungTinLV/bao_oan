import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════
// PUZZLE: CÂU ĐỐ MA DÂN GIAN VIỆT NAM
// Con ma đặt 3 câu đố, trả lời đúng mới được đi
// ════════════════════════════════════════════════════════════

class PuzzleGhostRiddleWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onClose;

  const PuzzleGhostRiddleWidget({
    super.key,
    required this.onSolved,
    required this.onClose,
  });

  @override
  State<PuzzleGhostRiddleWidget> createState() =>
      _PuzzleGhostRiddleWidgetState();
}

class _PuzzleGhostRiddleWidgetState extends State<PuzzleGhostRiddleWidget>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  int _currentRiddle = 0;
  bool _showWrong = false;
  bool _solved = false;

  late AnimationController _flickerController;

  // 3 câu đố dân gian
  static const List<_Riddle> _riddles = [
    _Riddle(
      question: '"Lúc sống thì đứng,\nlúc chết thì nằm.\nTa là gì?"',
      options: ['Cây tre', 'Cây nến', 'Con người', 'Cây nhang'],
      correctIndex: 1,
      explanation: 'Nến đứng khi cháy, nằm khi tắt',
    ),
    _Riddle(
      question:
          '"Sinh ra từ đất,\nchết đi về đất.\nSống không ai nhớ,\nchết rồi người ta đốt.\nTa là gì?"',
      options: ['Tiền vàng mã', 'Đống rác', 'Cây cỏ', 'Ngọn lửa'],
      correctIndex: 0,
      explanation: 'Vàng mã đốt cúng cho người chết',
    ),
    _Riddle(
      question:
          '"Giờ Sửu canh ba,\ncửa nào không nên mở?"',
      options: ['Cửa sổ', 'Cửa chính', 'Cửa sau', 'Cửa hông'],
      correctIndex: 2,
      explanation: 'Dân gian kiêng mở cửa sau lúc 1-3 giờ sáng',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_showWrong || _solved) return;

    final riddle = _riddles[_currentRiddle];

    if (index == riddle.correctIndex) {
      // Đúng
      _sfxPlayer.play(AssetSource('scratching.mp3'));
      _sfxPlayer.setVolume(0.3);

      setState(() {
        if (_currentRiddle < 2) {
          _currentRiddle++;
        } else {
          _solved = true;
          _sfxPlayer.play(AssetSource('wind_howl.mp3'));
          _sfxPlayer.setVolume(0.5);
          Future.delayed(const Duration(seconds: 3), () {
            widget.onSolved();
          });
        }
      });
    } else {
      // Sai → jumpscare flash
      _sfxPlayer.play(AssetSource('glitch_sound.mp3'));
      _sfxPlayer.setVolume(0.8);
      setState(() => _showWrong = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showWrong = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final riddle = _riddles[_currentRiddle.clamp(0, 2)];

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _flickerController,
        builder: (context, _) {
          double flicker = 0.8 + _flickerController.value * 0.2;

          return Center(
            child: Container(
              width: 340,
              height: 530,
              decoration: BoxDecoration(
                color: const Color(0xFF0a0a0a),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red[900]!.withOpacity(flicker * 0.6),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.15 * flicker),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Nền mờ sọc
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.red, Colors.black, Colors.red],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tiêu đề
                  Positioned(
                    top: 15,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        const Text(
                          '👻 CÂU ĐỐ CỦA QUỶ 👻',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Câu ${_currentRiddle + 1} / 3',
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        // Progress dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < _currentRiddle
                                    ? Colors.green
                                    : i == _currentRiddle
                                        ? Colors.red
                                        : Colors.white12,
                                border: Border.all(color: Colors.white24),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  // ═══ CÂU ĐỐ ═══
                  if (!_solved)
                    Positioned(
                      top: 100,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF120000),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red[900]!.withOpacity(0.3)),
                        ),
                        child: Text(
                          riddle.question,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontFamily: 'HorrorText',
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),

                  // ═══ 4 LỰA CHỌN ═══
                  if (!_solved)
                    Positioned(
                      top: 280,
                      left: 20,
                      right: 20,
                      child: Column(
                        children: List.generate(4, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => _selectAnswer(i),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a0500),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red[900]!.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red[900]!.withOpacity(0.3),
                                        border: Border.all(
                                            color: Colors.red[700]!, width: 1.5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          String.fromCharCode(65 + i), // A,B,C,D
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        riddle.options[i],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Wrong flash
                  if (_showWrong)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.red.withOpacity(0.3),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '😈',
                                style: TextStyle(fontSize: 60),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'SAI RỒI!\nHa ha ha...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'HorrorText',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Solved
                  if (_solved)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🔓',
                                style: TextStyle(fontSize: 50),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'GIẢI ĐƯỢC CÂU ĐỐ',
                                style: TextStyle(
                                  color: Colors.green[400],
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Con quỷ chấp nhận cho ngươi đi...',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Close
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TextButton(
                        onPressed: widget.onClose,
                        child: const Text('Bỏ qua',
                            style: TextStyle(color: Colors.white24)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Riddle {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _Riddle({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
