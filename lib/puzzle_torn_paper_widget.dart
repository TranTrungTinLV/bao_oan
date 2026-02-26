import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PuzzleTornPaperWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onClose;

  const PuzzleTornPaperWidget({
    super.key,
    required this.onSolved,
    required this.onClose,
  });

  @override
  State<PuzzleTornPaperWidget> createState() => _PuzzleTornPaperWidgetState();
}

class _PuzzleTornPaperWidgetState extends State<PuzzleTornPaperWidget> {
  bool _isSnapped = false;
  bool _isBurning = false;
  final AudioPlayer _sfxPlayer = AudioPlayer();

  void _handleAccept(var data) async {
    if (data == 'torn_piece') {
      setState(() {
        _isSnapped = true;
      });
      // Fire effect
      await _sfxPlayer.play(AssetSource('match_burn.mp3'));
      setState(() {
        _isBurning = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        widget.onSolved();
      });
    }
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          width: 350,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: Border.all(color: Colors.orange[900]!, width: 4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Text(
                  'Ghép bùa chú',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Target area
              Positioned(
                top: 100,
                left: 50,
                child: DragTarget<String>(
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: 250,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(color: Colors.red[900]!, width: 2),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Text(
                              'Cõi âm ty cửa ngục khép kín\n...\nOan hồn vất vưởng chốn...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'HorrorText'),
                            ),
                          ),
                          // The torn hole
                          if (!_isSnapped)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.brown[900], // See-through hole
                                  border: Border.all(color: Colors.red[300]!, style: BorderStyle.solid),
                                ),
                                child: const Center(
                                  child: Text('?', style: TextStyle(color: Colors.white54, fontSize: 30)),
                                ),
                              ),
                            ),
                          if (_isSnapped)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                width: 80,
                                height: 80,
                                color: Colors.yellow[200],
                                child: const Center(
                                  child: Text('u minh', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  onWillAcceptWithDetails: (details) => details.data == 'torn_piece',
                  onAcceptWithDetails: (details) => _handleAccept(details.data),
                ),
              ),

              // Fire effect
              if (_isBurning)
                Positioned.fill(
                  child: Container(
                    color: Colors.orange.withOpacity(0.5),
                    child: const Center(
                      child: Icon(Icons.local_fire_department, size: 100, color: Colors.deepOrange),
                    ),
                  ),
                ),

              // Draggable piece
              if (!_isSnapped)
                Positioned(
                  bottom: 30,
                  left: 135,
                  child: Draggable<String>(
                    data: 'torn_piece',
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildTornPiece(true),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildTornPiece(false),
                    ),
                    child: _buildTornPiece(false),
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

  Widget _buildTornPiece(bool isDragging) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.yellow[200],
        boxShadow: isDragging ? [const BoxShadow(color: Colors.black54, blurRadius: 10)] : [],
      ),
      child: const Center(
        child: Text(
          'u minh',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
