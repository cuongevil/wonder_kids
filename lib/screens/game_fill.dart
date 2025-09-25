import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vn_letter.dart';
import '../models/mascot_mood.dart';
import '../widgets/game_base.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/score_board.dart';
import '../widgets/rainbow_progress.dart';
import '../widgets/confetti_overlay.dart';
import '../services/audio_service.dart';
import '../mixins/game_level_mixin.dart';

class GameFill extends StatefulWidget {
  const GameFill({super.key});

  @override
  State<GameFill> createState() => _GameFillState();
}

class _GameFillState extends GameBaseState<GameFill>
    with TickerProviderStateMixin, GameLevelMixin {
  @override
  String get gameId => "game3";

  @override
  String get title => "Chữ còn thiếu";

  List<VnLetter> letters = [];
  VnLetter? answerLetter;
  String? sampleWord;
  List<String> displayed = [];
  List<VnLetter> options = [];

  VnLetter? wrongChoice;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    initLevelMixin();
    _loadLetters();
    _progressController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    disposeLevelMixin();
    _progressController.dispose();
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
      showLevelComplete(
        title: "✨ Xuất sắc!",
        subtitle: "Bạn đã điền chữ còn thiếu chính xác 🤩",
        onNextRound: _nextRound,
      );
      return;
    }

    final random = Random();

    // chọn chữ có word hợp lệ
    VnLetter candidate;
    do {
      candidate = letters[random.nextInt(letters.length)];
    } while (candidate.word == null || candidate.word!.length < 2);

    answerLetter = candidate;
    sampleWord = answerLetter!.word!;

    // chọn vị trí bỏ trống
    final chars = sampleWord!.split('');
    final idx = random.nextInt(chars.length);
    final missingChar = chars[idx];
    chars[idx] = "_";
    displayed = chars;

    // tạo options: missingChar + 3 chữ khác
    final shuffled = [...letters]..shuffle();
    final setChars = <String>{missingChar};
    final List<VnLetter> temp = [
      letters.firstWhere(
            (l) => l.char.toLowerCase() == missingChar.toLowerCase(),
        orElse: () => VnLetter(
          key: missingChar,
          char: missingChar,
          word: missingChar,
          imagePath: "",
          gameImagePath: "",
          audioPath: "",
        ),
      )
    ];

    for (final l in shuffled) {
      if (setChars.length == 4) break;
      if (setChars.add(l.char)) temp.add(l);
    }
    temp.shuffle();
    options = temp;

    wrongChoice = null;
    mascotMood = MascotMood.idle;

    setState(() {});
  }

  void _checkAnswer(VnLetter chosen) async {
    final isCorrect = displayed.contains("_") &&
        sampleWord != null &&
        sampleWord!.contains(chosen.char);
    await onAnswer(isCorrect);

    setState(() {
      increaseScore(isCorrect);
      if (!isCorrect) wrongChoice = chosen;
    });

    if (isCorrect) {
      confettiController.play();
      AudioService.play("correct.mp3");
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          round++;
          _nextRound();
        });
      });
    } else {
      AudioService.play("wrong.mp3");
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => wrongChoice = null);
      });
    }
  }

  @override
  Widget buildGame(BuildContext context) {
    final progress = overallProgress();

    if (answerLetter == null || sampleWord == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
              const Text("Điền chữ cái còn thiếu",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),

              // từ hiển thị với chỗ trống
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: displayed
                    .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: c == "_" ? Colors.pink : Colors.black87,
                    ),
                  ),
                ))
                    .toList(),
              ),

              const SizedBox(height: 32),

              // lựa chọn
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: options.map((l) {
                  final isWrong = wrongChoice == l;
                  return GestureDetector(
                    onTap: () => _checkAnswer(l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isWrong ? Colors.red.shade200 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2))
                        ],
                      ),
                      child: Text(
                        l.char,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
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
          ConfettiOverlay(controller: confettiController),
        ],
      ),
    );
  }

  @override
  void onReset() {
    setState(() {
      // reset biến chung
      round = 0;
      level = 1;
      streak = 0;
      maxStreak = 0;
      totalCorrect = 0;
      mascotMood = MascotMood.idle;

      // reset biến riêng
      answerLetter = null;
      sampleWord = null;
      displayed = [];
      options = [];
      wrongChoice = null;
    });
    _loadLetters(); // nạp lại dữ liệu
  }

}
