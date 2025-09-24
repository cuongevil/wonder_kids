import 'dart:convert';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vn_letter.dart';
import '../models/mascot_mood.dart';
import '../widgets/game_base.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/score_board.dart';
import '../widgets/rainbow_progress.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/level_complete_dialog.dart';
import '../services/audio_service.dart';

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

  int round = 0;
  final int maxRound = 5;
  int level = 1;

  int streak = 0;
  int maxStreak = 0;
  int totalCorrect = 0;

  MascotMood mascotMood = MascotMood.idle;

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

    _controller =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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

  void _checkAnswer(VnLetter chosen) async {
    setState(() {
      selected = chosen;
      isCorrect = (chosen.char == targetLetter!.char);
    });

    if (isCorrect) {
      _confettiController.play();
      AudioService.play("correct.mp3");
      await onAnswer(true);

      setState(() {
        totalCorrect++;
        streak++;
        if (streak > maxStreak) maxStreak = streak;
        mascotMood = MascotMood.happy;
      });
    } else {
      AudioService.play("wrong.mp3");
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelCompleteDialog(
        maxRound: maxRound,
        streak: streak,
        maxStreak: maxStreak,
        totalCorrect: totalCorrect,
        confettiController: _confettiController,
        onNextLevel: () {
          setState(() {
            level++;
            round = 0;
            streak = 0;
            maxStreak = 0;
            mascotMood = MascotMood.idle;
          });
          _nextRound();
        },
      ),
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
              RainbowProgress(progress: progress, controller: _controller),
              ScoreBoard(streak: streak, maxStreak: maxStreak, totalCorrect: totalCorrect),
              const SizedBox(height: 12),

              const Text("Hãy tìm chữ cái sau:",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

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
                        : pastelColors[Random().nextInt(pastelColors.length)];

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

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MascotWidget(mood: mascotMood),
              ),
            ],
          ),

          ConfettiOverlay(controller: _confettiController),
        ],
      ),
    );
  }
}
