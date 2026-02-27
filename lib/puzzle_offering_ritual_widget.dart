import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════
// PUZZLE: NGHI THỨC CÚNG CÔ HỒN
// Bày mâm cúng đúng phong tục dân gian Việt Nam
// ════════════════════════════════════════════════════════════

class PuzzleOfferingRitualWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onClose;

  const PuzzleOfferingRitualWidget({
    super.key,
    required this.onSolved,
    required this.onClose,
  });

  @override
  State<PuzzleOfferingRitualWidget> createState() =>
      _PuzzleOfferingRitualWidgetState();
}

class _PuzzleOfferingRitualWidgetState extends State<PuzzleOfferingRitualWidget>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // 5 ô trên bàn thờ:   [Nến] [Trái cây] [Nhang + Cơm] [Vàng mã] [Nến]
  // Vật phẩm đúng cho mỗi ô
  static const List<String> _correctItems = [
    'nen', 'traicay', 'nhang_com', 'vangma', 'nen2'
  ];

  // Pool vật phẩm
  final List<_OfferingItem> _allItems = [
    _OfferingItem('nen', '🕯️', 'Nến trái'),
    _OfferingItem('traicay', '🍊', 'Trái cây'),
    _OfferingItem('nhang_com', '🪔', 'Nhang + Cơm'),
    _OfferingItem('vangma', '🪙', 'Vàng mã'),
    _OfferingItem('nen2', '🕯️', 'Nến phải'),
    _OfferingItem('ruou', '🍶', 'Rượu (sai)'),
  ];

  List<String?> _placedItems = List.filled(5, null);
  late List<_OfferingItem> _availableItems;
  bool _solved = false;
  bool _showError = false;
  int _wrongCount = 0;

  late AnimationController _smokeController;

  @override
  void initState() {
    super.initState();
    _availableItems = List.from(_allItems);
    _availableItems.shuffle();

    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _smokeController.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _placeItem(int slotIndex, String itemId) {
    if (_solved) return;

    setState(() {
      // Trả lại item cũ
      if (_placedItems[slotIndex] != null) {
        String oldId = _placedItems[slotIndex]!;
        _OfferingItem? item = _allItems.where((e) => e.id == oldId).firstOrNull;
        if (item != null) _availableItems.add(item);
      }

      _placedItems[slotIndex] = itemId;
      _availableItems.removeWhere((e) => e.id == itemId);
    });

    // Check hết ô chưa
    if (!_placedItems.contains(null)) {
      _checkSolution();
    }
  }

  void _returnItem(int slotIndex) {
    if (_solved || _placedItems[slotIndex] == null) return;
    setState(() {
      String oldId = _placedItems[slotIndex]!;
      _OfferingItem? item = _allItems.where((e) => e.id == oldId).firstOrNull;
      if (item != null) _availableItems.add(item);
      _placedItems[slotIndex] = null;
    });
  }

  void _checkSolution() {
    bool correct = true;
    for (int i = 0; i < 5; i++) {
      if (_placedItems[i] != _correctItems[i]) {
        correct = false;
        break;
      }
    }

    if (correct) {
      setState(() => _solved = true);
      _sfxPlayer.play(AssetSource('chanting_nam_mo.mp3'));
      _sfxPlayer.setVolume(0.7);
      Future.delayed(const Duration(seconds: 3), () {
        widget.onSolved();
      });
    } else {
      _wrongCount++;
      _sfxPlayer.play(AssetSource('wind_howl.mp3'));
      _sfxPlayer.setVolume(0.6);
      setState(() => _showError = true);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showError = false;
            // Trả hết lại pool
            for (var itemId in _placedItems) {
              if (itemId != null) {
                _OfferingItem? item =
                    _allItems.where((e) => e.id == itemId).firstOrNull;
                if (item != null && !_availableItems.contains(item)) {
                  _availableItems.add(item);
                }
              }
            }
            _placedItems = List.filled(5, null);
            _availableItems.shuffle();
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
        child: Container(
          width: 350,
          height: 550,
          decoration: BoxDecoration(
            color: const Color(0xFF1c0800),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _solved ? Colors.amber : Colors.orange[900]!,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(_solved ? 0.5 : 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Tiêu đề
              const Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      '🪔 NGHI THỨC CÚNG CÔ HỒN 🪔',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bày mâm cúng đúng phong tục\nNến 2 bên, nhang cơm ở giữa',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // ═══ BÀN THỜ (5 ô) ═══
              Positioned(
                top: 100,
                left: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a1200),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.brown[700]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Khói nhang animated
                      if (_solved)
                        AnimatedBuilder(
                          animation: _smokeController,
                          builder: (context, _) {
                            return Opacity(
                              opacity: 0.5 + _smokeController.value * 0.3,
                              child: const Text(
                                '૮ ૮ ૮',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      // Label
                      const Text(
                        '┃  Bàn thờ  ┃',
                        style: TextStyle(
                          color: Colors.brown,
                          fontSize: 13,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 5 slots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (i) => _buildSlot(i)),
                      ),
                      const SizedBox(height: 8),
                      // Labels cho slot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _SlotLabel('Trái'),
                          _SlotLabel('②'),
                          _SlotLabel('Giữa'),
                          _SlotLabel('④'),
                          _SlotLabel('Phải'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ═══ VẬT PHẨM CÚNG (Pool) ═══
              Positioned(
                bottom: 110,
                left: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Vật phẩm cúng:',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: _availableItems
                            .map((item) => _buildDraggableItem(item))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Error flash
              if (_showError)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.red.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.red, size: 50),
                          const SizedBox(height: 8),
                          Text(
                            'Sai vị trí! Bày lại đi...',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_wrongCount >= 2)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Gợi ý: Nến 2 bên, cơm nhang giữa,\ntrái cây bên trái, vàng mã bên phải',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.orange, fontSize: 11),
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
                      color: Colors.amber.withOpacity(0.1),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🙏',
                            style: TextStyle(fontSize: 50),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'CÔ HỒN SIÊU THOÁT',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Mâm cúng đã bày đúng phong tục',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Close
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton(
                    onPressed: widget.onClose,
                    child:
                        const Text('Bỏ qua', style: TextStyle(color: Colors.white38)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(int index) {
    bool hasItem = _placedItems[index] != null;
    _OfferingItem? placed;
    if (hasItem) {
      placed = _allItems.where((e) => e.id == _placedItems[index]).firstOrNull;
    }

    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => _returnItem(index),
          child: Container(
            width: 52,
            height: 60,
            decoration: BoxDecoration(
              color: hasItem
                  ? const Color(0xFF3a2000)
                  : isHovering
                      ? Colors.orange.withOpacity(0.15)
                      : const Color(0xFF150a00),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasItem
                    ? Colors.orange.withOpacity(0.6)
                    : Colors.brown[800]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                hasItem ? placed?.emoji ?? '?' : '╋',
                style: TextStyle(
                  fontSize: hasItem ? 26 : 18,
                  color: Colors.white30,
                ),
              ),
            ),
          ),
        );
      },
      onWillAcceptWithDetails: (details) => !_solved,
      onAcceptWithDetails: (details) => _placeItem(index, details.data),
    );
  }

  Widget _buildDraggableItem(_OfferingItem item) {
    return Draggable<String>(
      data: item.id,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 55,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withOpacity(0.4), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.emoji,
                  style: const TextStyle(
                      fontSize: 24, decoration: TextDecoration.none)),
              Text(item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    decoration: TextDecoration.none,
                  )),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 50,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Container(
        width: 50,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF1a0d00),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 22)),
            Text(
              item.name,
              style: const TextStyle(color: Colors.white30, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferingItem {
  final String id;
  final String emoji;
  final String name;
  _OfferingItem(this.id, this.emoji, this.name);
}

class _SlotLabel extends StatelessWidget {
  final String text;
  const _SlotLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white12, fontSize: 9),
      ),
    );
  }
}
