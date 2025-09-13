import 'package:flutter/material.dart';

import '../models/vn_letter.dart';
import '../screens/letter_screen.dart';
import '../services/audio_service.dart';

class LetterCard extends StatefulWidget {
  final VnLetter letter;

  const LetterCard({super.key, required this.letter});

  @override
  State<LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<LetterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());

    if (widget.letter.audioPath != null) {
      AudioService.play(widget.letter.audioPath!);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LetterScreen(letter: widget.letter)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors
                .primaries[widget.letter.char.codeUnitAt(0) %
                    Colors.primaries.length]
                .shade100,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.letter.imagePath != null)
                  Expanded(
                    child: Image.asset(
                      widget.letter.imagePath!,
                      fit: BoxFit.contain,
                    ),
                  ),
                Text(
                  widget.letter.char,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
