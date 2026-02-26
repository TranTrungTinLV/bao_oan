import 'dart:async';
import 'package:flutter/material.dart';

/// RPG-style dialog box widget with typewriter effect
/// Hiển thị dialog kiểu game RPG: avatar + tên + text gõ từng chữ
class DialogWidget extends StatefulWidget {
  final String speaker;
  final String text;
  final bool isNPC;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const DialogWidget({
    super.key,
    required this.speaker,
    required this.text,
    required this.isNPC,
    required this.onComplete,
    required this.onTap,
  });

  @override
  State<DialogWidget> createState() => _DialogWidgetState();
}

class _DialogWidgetState extends State<DialogWidget> {
  int _visibleChars = 0;
  Timer? _typewriterTimer;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void didUpdateWidget(DialogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _visibleChars = 0;
      _isComplete = false;
      _typewriterTimer?.cancel();
      _startTypewriter();
    }
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(
      const Duration(milliseconds: 35),
      (timer) {
        if (_visibleChars < widget.text.length) {
          setState(() {
            _visibleChars++;
          });
        } else {
          timer.cancel();
          setState(() {
            _isComplete = true;
          });
        }
      },
    );
  }

  void _handleTap() {
    if (!_isComplete) {
      // Skip typewriter, show full text
      _typewriterTimer?.cancel();
      setState(() {
        _visibleChars = widget.text.length;
        _isComplete = true;
      });
    } else {
      widget.onTap();
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.text.substring(0, _visibleChars);
    final isSystem = widget.speaker == 'Hệ thống';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSystem
                ? Colors.black.withOpacity(0.85)
                : (widget.isNPC
                    ? const Color(0xDD1a1a2e)
                    : const Color(0xDD0f3460)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSystem
                  ? Colors.amber.withOpacity(0.5)
                  : (widget.isNPC
                      ? Colors.red.withOpacity(0.4)
                      : Colors.blue.withOpacity(0.4)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speaker name
              Row(
                children: [
                  if (!isSystem)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isNPC ? Colors.red : Colors.cyan,
                      ),
                    ),
                  Text(
                    widget.speaker,
                    style: TextStyle(
                      fontFamily: 'HorrorText',
                      fontSize: isSystem ? 13 : 16,
                      color: isSystem
                          ? Colors.amber
                          : (widget.isNPC
                              ? const Color(0xFFff6b6b)
                              : const Color(0xFF74b9ff)),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (_isComplete)
                    Text(
                      '▶',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Dialog text
              Text(
                displayText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
