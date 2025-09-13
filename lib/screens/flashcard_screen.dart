import 'dart:convert';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vn_letter.dart';
import '../services/audio_service.dart';
import '../widgets/celebration_overlay.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<VnLetter> letters = [];
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    final String response = await rootBundle.loadString(
      'assets/config/letters.json',
    );
    final List<dynamic> data = json.decode(response);
    setState(() {
      letters = data.map((e) => VnLetter.fromJson(e)).toList();
    });
  }

  void _playAudio(String? path) {
    if (path != null) {
      AudioService.play(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flashcard chữ cái"),
        backgroundColor: Colors.pinkAccent.shade100,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: letters.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : PageView.builder(
                controller: _pageController,
                itemCount: letters.length,
                itemBuilder: (context, index) {
                  final letter = letters[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                      }
                      return Center(
                        child: Transform.scale(
                          scale: Curves.easeOut.transform(value),
                          child: child,
                        ),
                      );
                    },
                    child: FlipCard(
                      direction: FlipDirection.HORIZONTAL,
                      front: _buildFrontCard(letter),
                      back: _buildBackCard(letter),
                      onFlipDone: (isFront) {
                        if (!isFront) {
                          CelebrationOverlay.show(context); // 🎉 hiệu ứng
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFrontCard(VnLetter letter) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Center(
        child: Text(
          letter.char,
          style: const TextStyle(
            fontSize: 140,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(VnLetter letter) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (letter.imagePath != null)
              Image.asset(letter.imagePath!, height: 160),
            const SizedBox(height: 16),
            if (letter.sampleWord != null)
              Text(
                letter.sampleWord!,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.pinkAccent,
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _playAudio(letter.audioPath),
              icon: const Icon(Icons.volume_up, size: 28),
              label: const Text("Nghe lại", style: TextStyle(fontSize: 22)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: const StadiumBorder(),
                elevation: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
