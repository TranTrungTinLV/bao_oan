import 'package:flutter/material.dart';

class PuzzleBetelTrayWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onClose;

  const PuzzleBetelTrayWidget({
    super.key,
    required this.onSolved,
    required this.onClose,
  });

  @override
  State<PuzzleBetelTrayWidget> createState() => _PuzzleBetelTrayWidgetState();
}

class _PuzzleBetelTrayWidgetState extends State<PuzzleBetelTrayWidget> {
  int _wipeCount = 0;
  List<Offset> _wipePoints = [];
  bool _solved = false;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_solved) return;
    
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    // Cho phép vẽ tự do trong khung Container lớn hơn để dễ trúng
    if (localPosition.dy > 0 && localPosition.dx > 0) {
      setState(() {
        _wipePoints.add(localPosition);
        _wipeCount++;
      });

      if (_wipeCount > 80) { // Giảm số lượng điểm yêu cầu xuống 80 để dễ qua màn hơn
        _solved = true;
        Future.delayed(const Duration(seconds: 2), () {
          widget.onSolved();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          width: 300,
          height: 450,
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: Border.all(color: Colors.red[900]!, width: 4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Text(
                  'Dùng máu đỏ giải mã',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // The invisible writing area
              Positioned(
                top: 100,
                left: 30,
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  child: Container(
                    width: 240,
                    height: 250,
                    color: Colors.yellow[100],
                    child: CustomPaint(
                      painter: _BloodWipePainter(_wipePoints, _solved),
                    ),
                  ),
                ),
              ),

              if (_solved)
                Positioned.fill(
                  child: Container(
                    color: Colors.red.withOpacity(0.3),
                    child: const Center(
                      child: Text(
                        'OÁN',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'HorrorText',
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton(
                    onPressed: widget.onClose,
                    child: const Text('Bỏ qua', style: TextStyle(color: Colors.white54)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _BloodWipePainter extends CustomPainter {
  final List<Offset> points;
  final bool solved;

  _BloodWipePainter(this.points, this.solved);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red[900]!.withOpacity(0.6)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20.0;

    for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(
          Offset(points[i].dx - 30, points[i].dy - 100), 
          Offset(points[i+1].dx - 30, points[i+1].dy - 100), 
          paint);
    }
    
    if (solved) {
      TextPainter textPainter = TextPainter(
        text: const TextSpan(
          text: 'Ngày 15 tháng 7...\nHọ đã giết tôi...\nVà chôn tôi ở...\nSau bức tường 403...',
          style: TextStyle(
            color: Colors.red,
            fontSize: 22,
            fontFamily: 'HorrorText',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(20, 50));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
