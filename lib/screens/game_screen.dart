import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/vn_letter.dart';
import '../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  List<VnLetter> letters = [];
  VnLetter? targetLetter;
  List<VnLetter> options = [];
  VnLetter? selected;
  bool isCorrect = false;
  int combo = 0; // đếm đúng liên tiếp

  // animation khi sai
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  // confetti khi đúng
  late ConfettiController _confettiController;

  // random audio khen thưởng
  final List<String> praiseAudios = [
    "audio/correct.mp3"
  ];

  @override
  void initState() {
    super.initState();
    _loadLetters();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_controller);

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    final String response =
    await rootBundle.loadString('assets/config/letters.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      letters = data.map((e) => VnLetter.fromJson(e)).toList();
      _nextRound();
    });
  }

  void _nextRound() {
    if (letters.isEmpty) return;

    final random = Random();
    targetLetter = letters[random.nextInt(letters.length)];

    final shuffled = [...letters]..shuffle();
    options = (shuffled.take(5).toList()..add(targetLetter!))..shuffle();

    selected = null;
    isCorrect = false;

    if (targetLetter!.audioPath != null) {
      AudioService.play(targetLetter!.audioPath!);
    }
  }

  void _checkAnswer(VnLetter chosen) {
    setState(() {
      selected = chosen;
      isCorrect = (chosen.char == targetLetter!.char);
    });

    if (isCorrect) {
      combo++;
      _confettiController.play();

      // random audio khen thưởng
      final rnd = Random().nextInt(praiseAudios.length);
      AudioService.play(praiseAudios[rnd]);

      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _nextRound();
        });
      });
    } else {
      combo = 0;
      AudioService.play("audio/wrong.mp3");
      _controller.forward(from: 0);

      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          selected = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (targetLetter == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final width = MediaQuery.of(context).size.width;
    final progress = DateTime.now().millisecond / 1000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎮 Trò chơi tìm chữ"),
        backgroundColor: Colors.pinkAccent.shade100,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                "🔥 Liên tiếp: $combo",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // nền gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB3E5FC), Color(0xFFF8BBD0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // mây bay
          AnimatedPositioned(
            duration: const Duration(seconds: 20),
            left: (progress * width) % width - 150,
            top: 80,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset("assets/images/cloud.png", width: 150),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 25),
            right: (progress * width) % width - 200,
            bottom: 120,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset("assets/images/cloud.png", width: 180),
            ),
          ),
          // sao nhấp nháy
          for (int i = 0; i < 5; i++)
            Positioned(
              left: 40.0 + i * 70,
              top: 40.0 + (i % 2) * 90,
              child: AnimatedOpacity(
                opacity: (math.sin(progress * 2 * math.pi + i) + 1) / 2,
                duration: const Duration(seconds: 1),
                child: const Icon(Icons.star, color: Colors.white, size: 18),
              ),
            ),
          // confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.pink,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
              ],
            ),
          ),
          // nội dung chính
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Hãy tìm chữ cái sau:",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                targetLetter!.char,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 12),
              // mascot vui/buồn
              AnimatedScale(
                duration: const Duration(milliseconds: 600),
                scale: isCorrect
                    ? 1.3
                    : (selected != null && !isCorrect)
                    ? 0.8
                    : 1.0,
                curve: Curves.elasticOut,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 600),
                  turns: isCorrect
                      ? 0.05
                      : (selected != null && !isCorrect)
                      ? -0.05
                      : 0,
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    "assets/images/mascot.png",
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: options.map((letter) {
                    final isSelected = selected == letter;
                    bool correctChoice = isSelected && isCorrect;
                    bool wrongChoice = isSelected && !isCorrect;

                    Color baseColor = Colors.primaries[
                    letter.char.codeUnitAt(0) % Colors.primaries.length]
                        .shade200;

                    return AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        double offset = wrongChoice ? _shakeAnimation.value : 0;
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: GestureDetector(
                            onTap: selected == null
                                ? () => _checkAnswer(letter)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: correctChoice
                                      ? [Colors.greenAccent, Colors.lightGreen]
                                      : wrongChoice
                                      ? [Colors.redAccent,
                                    Colors.red.shade200]
                                      : [baseColor, Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(2, 3),
                                  ),
                                ],
                              ),
                              child: AnimatedOpacity(
                                opacity: wrongChoice ? 0.5 : 1.0,
                                duration: const Duration(milliseconds: 400),
                                child: AnimatedScale(
                                  scale: correctChoice ? 1.3 : 1.0,
                                  duration: const Duration(milliseconds: 400),
                                  child: Text(
                                    letter.char,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              PulseButton(
                onTap: () {
                  if (targetLetter!.audioPath != null) {
                    AudioService.play(targetLetter!.audioPath!);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget nút Nghe lại (pulsing + glow rainbow)
class PulseButton extends StatefulWidget {
  final VoidCallback onTap;
  const PulseButton({super.key, required this.onTap});

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleController,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowColor = HSVColor.fromAHSV(
            1,
            (_glowController.value * 360) % 360,
            0.8,
            1,
          ).toColor();

          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF80AB),
                    Color(0xFF9C27B0),
                    Color(0xFF3F51B5)
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.7),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.volume_up, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Nghe lại",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
