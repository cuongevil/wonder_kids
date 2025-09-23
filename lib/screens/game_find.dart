import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/vn_letter.dart';
import '../widgets/game_base.dart';

// 🐻 trạng thái mascot
enum MascotMood { idle, happy, sad, celebrate }

class GameFind extends StatefulWidget {
  const GameFind({super.key});

  @override
  State<GameFind> createState() => _GameFindState();
}

class _GameFindState extends GameBaseState<GameFind>
    with SingleTickerProviderStateMixin {
  @override
  String get gameId => "game1";

  @override
  String get title => "Săn chữ vui nhộn";

  List<VnLetter> letters = [];
  VnLetter? targetLetter;
  List<VnLetter> options = [];
  VnLetter? selected;
  bool isCorrect = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;
  final AudioPlayer _player = AudioPlayer();

  int round = 0;
  final int maxRound = 5;
  int level = 1;

  int streak = 0;        // ⭐ chuỗi hiện tại
  int maxStreak = 0;     // 🔥 chuỗi dài nhất
  int totalCorrect = 0;  // 👑 tổng số câu đúng

  MascotMood mascotMood = MascotMood.idle;

  final List<String> mascots = [
    "assets/images/mascot_1.png",
    "assets/images/mascot_2.png",
    "assets/images/mascot_3.png",
    "assets/images/mascot_4.png",
    "assets/images/mascot_5.png",
  ];

  final pastelColors = [
    [Colors.pinkAccent, Colors.pink.shade100],
    [Colors.lightBlueAccent, Colors.blue.shade100],
    [Colors.lightGreen, Colors.green.shade100],
    [Colors.orangeAccent, Colors.orange.shade100],
    [Colors.purpleAccent, Colors.purple.shade100],
  ];

  @override
  void initState() {
    super.initState();
    _loadLetters();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _player.dispose();
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
    if (round >= maxRound) {
      _showLevelComplete();
      return;
    }

    final random = Random();
    final newTarget = letters[random.nextInt(letters.length)];
    final optionCount = (level * 3).clamp(3, 9);
    final shuffled = [...letters]..shuffle();
    final newOptions =
    (shuffled.take(optionCount - 1).toList()..add(newTarget))..shuffle();

    setState(() {
      targetLetter = newTarget;
      options = newOptions;
      selected = null;
      isCorrect = false;
      mascotMood = MascotMood.idle;
    });
  }

  Future<void> _playSound(String file) async {
    await _player.play(AssetSource("audio/$file"));
  }

  void _checkAnswer(VnLetter chosen) async {
    setState(() {
      selected = chosen;
      isCorrect = (chosen.char == targetLetter!.char);
    });

    if (isCorrect) {
      _confettiController.play();
      _playSound("correct.mp3");
      await onAnswer(true);

      setState(() {
        totalCorrect++;
        streak++;
        if (streak > maxStreak) maxStreak = streak;
        mascotMood = MascotMood.happy;
      });
    } else {
      _playSound("wrong.mp3");
      await onAnswer(false);
      setState(() {
        streak = 0;
        mascotMood = MascotMood.sad;
      });
    }

    setState(() => round++);
    Future.delayed(const Duration(seconds: 1), _nextRound);
  }

  void _showLevelComplete() {
    setState(() => mascotMood = MascotMood.celebrate);

    final mascot = mascots[Random().nextInt(mascots.length)];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade100, Colors.yellow.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(mascot, height: 100),
                    const SizedBox(height: 12),
                    Text("🎉 Giỏi lắm bé ơi! 🎉",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade700)),
                    const SizedBox(height: 12),
                    Text(
                      "Hoàn thành $maxRound câu!\n"
                          "⭐ Chuỗi hiện tại: $streak\n"
                          "🔥 Chuỗi dài nhất: $maxStreak\n"
                          "👑 Tổng số câu đúng: $totalCorrect",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          level++;
                          round = 0;
                          streak = 0;
                          maxStreak = 0;
                          mascotMood = MascotMood.idle;
                        });
                        _nextRound();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Chơi Level mới",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              Positioned.fill(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 20,
                  maxBlastForce: 12,
                  minBlastForce: 5,
                  emissionFrequency: 0.05,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void onReset() {
    selected = null;
    isCorrect = false;
    round = 0;
    level = 1;
    streak = 0;
    maxStreak = 0;
    totalCorrect = 0;
    mascotMood = MascotMood.idle;
    _nextRound();
  }

  // 🎭 mascot động
  Widget _buildMascot() {
    String mascotImg = mascots[Random().nextInt(mascots.length)];
    Widget mascotWidget = Image.asset(mascotImg, height: 120);

    switch (mascotMood) {
      case MascotMood.happy:
        return Column(
          children: [
            _floatingHearts(),
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: mascotWidget,
            ),
          ],
        );
      case MascotMood.sad:
        return Column(
          children: [
            const Icon(Icons.cloud, color: Colors.grey, size: 30),
            Opacity(opacity: 0.7, child: mascotWidget),
          ],
        );
      case MascotMood.celebrate:
        return Column(
          children: [
            _floatingStars(),
            RotationTransition(
              turns: Tween<double>(begin: -0.05, end: 0.05).animate(
                CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
              ),
              child: mascotWidget,
            ),
            const Text("🎉 Yeah! 🎉",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        );
      default:
        return mascotWidget;
    }
  }

  Widget _floatingHearts() {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (i) {
          final dx = (i - 1) * 40.0;
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final offsetY = math.sin(_controller.value * 2 * math.pi + i) * 8;
              return Transform.translate(
                offset: Offset(dx, offsetY),
                child: const Icon(Icons.favorite,
                    color: Colors.pinkAccent, size: 18),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _floatingStars() {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (i) {
          final dx = (i - 1) * 40.0;
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final offsetY = math.cos(_controller.value * 2 * math.pi + i) * 8;
              return Transform.translate(
                offset: Offset(dx, offsetY),
                child:
                const Icon(Icons.star, color: Colors.yellow, size: 20),
              );
            },
          );
        }),
      ),
    );
  }

  @override
  Widget buildGame(BuildContext context) {
    if (targetLetter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = round / maxRound;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade50, Colors.blue.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // 🌈 progress bar + ⭐ chạy bounce + glow
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    const starSize = 28.0;
                    final starX = (barWidth - starSize) * progress;

                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.red,
                                Colors.orange,
                                Colors.yellow,
                                Colors.green,
                                Colors.blue,
                                Colors.purple
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Positioned(
                          left: starX,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final bounceY =
                                  math.sin(_controller.value * 2 * math.pi) * 6;
                              return Transform.translate(
                                offset: Offset(0, bounceY),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.yellow.withOpacity(
                                            0.6 +
                                                0.4 *
                                                    math.sin(_controller.value *
                                                        2 *
                                                        math.pi)),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.star,
                                      color: Colors.white, size: starSize),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ⭐ streak, 🔥 max streak, 👑 total correct
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("⭐ ",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("$streak  ",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500)),
                  const Text("🔥 ",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("$maxStreak  ",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500)),
                  const Text("👑 ",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("$totalCorrect",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),

              const Text("Hãy tìm chữ cái sau:",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              // 🌟 chữ cái chính glow + bounce
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(targetLetter!.char,
                    style: TextStyle(
                        fontSize: 90,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade600,
                        shadows: [
                          Shadow(
                              blurRadius: 20,
                              color: Colors.pink.shade200,
                              offset: Offset(0, 0))
                        ])),
              ),
              const SizedBox(height: 12),

              // 🔲 các lựa chọn
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: options.map((letter) {
                    final isSelected = selected == letter;
                    final correctChoice = isSelected && isCorrect;
                    final wrongChoice = isSelected && !isCorrect;

                    final gradient = correctChoice
                        ? [Colors.green, Colors.lightGreenAccent]
                        : wrongChoice
                        ? [Colors.red, Colors.redAccent]
                        : pastelColors[
                    Random().nextInt(pastelColors.length)];

                    return GestureDetector(
                      onTap:
                      selected == null ? () => _checkAnswer(letter) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(2, 2))
                          ],
                        ),
                        child: Text(letter.char,
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 🐻 mascot dưới
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMascot(),
              ),
            ],
          ),

          // 🎊 confetti hiệu ứng
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 25,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
