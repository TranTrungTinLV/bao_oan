import 'package:flutter/material.dart';

class PuzzleMandalaWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onClose;

  const PuzzleMandalaWidget({
    super.key,
    required this.onSolved,
    required this.onClose,
  });

  @override
  State<PuzzleMandalaWidget> createState() => _PuzzleMandalaWidgetState();
}

class _PuzzleMandalaWidgetState extends State<PuzzleMandalaWidget> {
  // 5 nodes (corners of pentagram)
  // Solution requires a specific rotation or connection.
  // We'll simulate a lock where user taps nodes to cycle colors or states.
  List<int> _nodeStates = [0, 0, 0, 0, 0];
  final List<int> _solution = [1, 2, 0, 2, 1]; // Example correct states

  void _tapNode(int index) {
    setState(() {
      _nodeStates[index] = (_nodeStates[index] + 1) % 3;
      if (_checkSolution()) {
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onSolved();
        });
      }
    });
  }

  bool _checkSolution() {
    for (int i = 0; i < 5; i++) {
      if (_nodeStates[i] != _solution[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: Border.all(color: Colors.red[900]!, width: 4),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Stack(
            children: [
              // Background book texture
              Positioned.fill(
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    'images/backgrounds/room_interior.png', // Fallback texture
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Text(
                  'Giải trừ ấn chú chỉ đỏ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Pentagon layout roughly
              _buildNode(0, 150, 80),
              _buildNode(1, 230, 160),
              _buildNode(2, 200, 280),
              _buildNode(3, 100, 280),
              _buildNode(4, 70, 160),

              // Close button
              Positioned(
                bottom: 16,
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

  Widget _buildNode(int index, double x, double y) {
    Color nodeColor;
    switch (_nodeStates[index]) {
      case 0:
        nodeColor = Colors.grey;
        break;
      case 1:
        nodeColor = Colors.red;
        break;
      case 2:
        nodeColor = Colors.black;
        break;
      default:
        nodeColor = Colors.grey;
    }

    return Positioned(
      left: x - 25,
      top: y - 25,
      child: GestureDetector(
        onTap: () => _tapNode(index),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: nodeColor,
            border: Border.all(color: Colors.white30, width: 2),
            boxShadow: [
              if (_nodeStates[index] == 1)
                BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 10)
            ],
          ),
          child: const Center(
            child: Icon(Icons.change_history, size: 20, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
