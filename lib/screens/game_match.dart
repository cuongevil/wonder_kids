import 'dart:convert';
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
import '../widgets/letter_column.dart';
import '../widgets/image_column.dart';
import '../services/audio_service.dart';

class GameMatch extends StatefulWidget {
  const GameMatch({super.key});

  @override
  State<GameMatch> createState() => _GameMatchState();
}

class _GameMatchState extends GameBaseState<GameMatch>
    with TickerProviderStateMixin {
  @override
  String get gameId => "game2";

  @override
  String get title => "Xếp hình chữ cái";

  List<VnLetter> letters = [];
  List<_Pair> pairs = [];

  VnLetter? selectedLetter;
  VnLetter? selectedImage;
  VnLetter? wrongLeft;
  VnLetter? wrongRight;

  int round = 0;
  int maxRound = 5;
  int level = 1;

  int streak = 0;
  int maxStreak = 0;
  int totalCorrect = 0;

  MascotMood mascotMood = MascotMood.idle;

  late AnimationController _progressController;
  late ConfettiController _confettiController;
  int _pairsAtRoundStart = 0;

  @override
  void initState() {
    super.initState();
    _loadLetters();

    _progressController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _progressController.dispose();
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
    if (round >= maxRound) {
      _showLevelComplete();
      return;
    }

    final chosen = [...letters]..shuffle();
    final optionCount = (level * 2 + 2).clamp(4, 8);
    final selected = chosen.take(optionCount).toList();

    pairs = selected.map((l) => _Pair(letter: l, image: l.gameImagePath)).toList();
    pairs.shuffle();

    _pairsAtRoundStart = pairs.length;

    selectedLetter = null;
    selectedImage = null;
    wrongLeft = null;
    wrongRight = null;
    mascotMood = MascotMood.idle;

    setState(() {});
  }

  void _onTapLetter(VnLetter l) {
    setState(() {
      selectedLetter = l;
      wrongLeft = null;
    });
    _checkMatch();
  }

  void _onTapImage(VnLetter l) {
    setState(() {
      selectedImage = l;
      wrongRight = null;
    });
    _checkMatch();
  }

  void _checkMatch() async {
    if (selectedLetter == null || selectedImage == null) return;

    final isCorrect = selectedLetter!.char == selectedImage!.char;
    await onAnswer(isCorrect);

    if (isCorrect) {
      _confettiController.play();
      AudioService.play("correct.mp3");

      setState(() {
        pairs.removeWhere((p) => p.letter.char == selectedLetter!.char);
        streak++;
        totalCorrect++;
        if (streak > maxStreak) maxStreak = streak;
        mascotMood = MascotMood.happy;
        selectedLetter = null;
        selectedImage = null;
        wrongLeft = null;
        wrongRight = null;
      });

      if (pairs.isEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            round++;
          });
          _nextRound();
        });
      }
    } else {
      AudioService.play("wrong.mp3");
      setState(() {
        streak = 0;
        mascotMood = MascotMood.sad;
        wrongLeft = selectedLetter;
        wrongRight = selectedImage;
        selectedLetter = null;
        selectedImage = null;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          wrongLeft = null;
          wrongRight = null;
        });
      });
    }
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
          Future.delayed(const Duration(milliseconds: 200), _nextRound);
        },
      ),
    );
  }

  @override
  void onReset() {
    setState(() {
      round = 0;
      level = 1;
      streak = 0;
      maxStreak = 0;
      totalCorrect = 0;
      mascotMood = MascotMood.idle;
      wrongLeft = null;
      wrongRight = null;
    });
    _loadLetters();
  }

  double _overallProgress() {
    if (maxRound <= 0) return 0;
    final perRound = (_pairsAtRoundStart == 0)
        ? 0.0
        : (_pairsAtRoundStart - pairs.length) / _pairsAtRoundStart;
    final overall = (round + perRound) / maxRound;
    return overall.clamp(0.0, 1.0);
  }

  @override
  Widget buildGame(BuildContext context) {
    final progress = _overallProgress();

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
              RainbowProgress(progress: progress, controller: _progressController),
              ScoreBoard(
                streak: streak,
                maxStreak: maxStreak,
                totalCorrect: totalCorrect,
              ),
              const SizedBox(height: 12),
              const Text("Ghép chữ với hình tương ứng",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (pairs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(),
                )
              else
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: LetterColumn(
                          items: pairs
                              .map((p) => LetterItem(
                            letter: p.letter,
                            isSelected: selectedLetter == p.letter,
                            isWrong: wrongLeft == p.letter,
                          ))
                              .toList(),
                          onTap: _onTapLetter,
                        ),
                      ),
                      Expanded(
                        child: ImageColumn(
                          items: pairs
                              .map((p) => ImageItem(
                            letter: p.letter,
                            image: p.image,
                            isSelected: selectedImage == p.letter,
                            isWrong: wrongRight == p.letter,
                          ))
                              .toList(),
                          onTap: _onTapImage,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 120),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: MascotWidget(mood: mascotMood)),
          ),
          ConfettiOverlay(controller: _confettiController),
        ],
      ),
    );
  }
}

class _Pair {
  final VnLetter letter;
  final String? image;
  _Pair({required this.letter, this.image});
}
