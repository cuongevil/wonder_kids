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

  // chỉ highlight 2 thẻ sai vừa chọn
  VnLetter? wrongLeft;
  VnLetter? wrongRight;

  // rounds
  int round = 0;          // số vòng đã HOÀN THÀNH
  int maxRound = 5;
  int level = 1;

  // score
  int streak = 0;
  int maxStreak = 0;
  int totalCorrect = 0;

  MascotMood mascotMood = MascotMood.idle;

  late AnimationController _progressController;
  late ConfettiController _confettiController;

  // để tính progress trong vòng
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
    // Nếu đã hoàn thành đủ vòng → hiển thị tổng kết
    if (round >= maxRound) {
      _showLevelComplete();
      return;
    }

    // chọn data cho vòng mới
    final chosen = [...letters]..shuffle();
    final optionCount = (level * 2 + 2).clamp(4, 8);
    final selected = chosen.take(optionCount).toList();

    pairs = selected.map((l) => _Pair(letter: l, image: l.imagePath)).toList();
    pairs.shuffle();

    _pairsAtRoundStart = pairs.length;

    // reset chọn/đánh dấu
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
      wrongLeft = null; // clear đỏ cũ bên trái
    });
    _checkMatch();
  }

  void _onTapImage(VnLetter l) {
    setState(() {
      selectedImage = l;
      wrongRight = null; // clear đỏ cũ bên phải
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

        // clear select/wrong
        selectedLetter = null;
        selectedImage = null;
        wrongLeft = null;
        wrongRight = null;
      });

      // nếu đã ghép hết trong vòng → chuyển vòng SAU một nhịp
      if (pairs.isEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            round++; // ✅ tăng số vòng đã hoàn thành TẠI ĐÂY
          });
          _nextRound(); // rồi mới setup vòng mới
        });
      }
    } else {
      AudioService.play("wrong.mp3");
      setState(() {
        streak = 0;
        mascotMood = MascotMood.sad;

        // chỉ đỏ đúng 2 thẻ vừa chọn
        wrongLeft = selectedLetter;
        wrongRight = selectedImage;

        // clear chọn để bé chọn lại
        selectedLetter = null;
        selectedImage = null;
      });

      // tự xóa highlight đỏ sau 600ms
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
          _nextRound();
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

  // ✅ progress tổng = (vòng đã hoàn thành + tiến độ trong vòng) / maxRound
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
    // Vừa ghép xong và đang chuyển vòng → vẫn render progress + nền
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
              // 🌈 progress bar chạy mượt
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

              // Nếu chưa có cặp (đang chuyển vòng) → loader nhỏ
              if (pairs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(),
                )
              else
                Expanded(
                  child: Row(
                    children: [
                      // Cột chữ
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: pairs.map((p) {
                            final isSelected = selectedLetter == p.letter;
                            final isWrong = wrongLeft == p.letter;

                            Color bg = Colors.white;
                            if (isWrong) {
                              bg = Colors.red.shade200;
                            } else if (isSelected) {
                              bg = Colors.blue.shade200;
                            }

                            return GestureDetector(
                              onTap: () => _onTapLetter(p.letter),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    )
                                  ],
                                ),
                                child: Text(
                                  p.letter.char,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Cột hình
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: pairs.map((p) {
                            final isSelected = selectedImage == p.letter;
                            final isWrong = wrongRight == p.letter;

                            Color bg = Colors.white;
                            if (isWrong) {
                              bg = Colors.red.shade200;
                            } else if (isSelected) {
                              bg = Colors.green.shade200;
                            }

                            return GestureDetector(
                              onTap: () => _onTapImage(p.letter),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    )
                                  ],
                                ),
                                child: p.image != null
                                    ? Image.asset(p.image!, height: 60)
                                    : const Icon(Icons.image, size: 40),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 80),
              MascotWidget(mood: mascotMood),
            ],
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
