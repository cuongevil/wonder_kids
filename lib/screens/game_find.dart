import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/vn_letter.dart';
import '../widgets/game_base.dart';

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

  int starCount = 0; // ⭐ mỗi câu đúng +1
  int streak = 0;    // chuỗi đúng liên tục
  int crownCount = 0; // 👑 cứ 5 sao → +1 vương miện

  final GlobalKey _starKey = GlobalKey();
  OverlayEntry? _starOverlay;

  @override
  void initState() {
    super.initState();
    _loadLetters();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
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
    });

    _controller.forward(from: 0);
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
        starCount++; // ✅ chỉ cộng sao nếu đúng
        streak++;
        if (streak % 3 == 0) {
          _playSound("star.mp3");
          _showFlyingStar();
        }
      });
    } else {
      _playSound("wrong.mp3");
      await onAnswer(false);

      setState(() {
        streak = 0;
      });
    }

    // ✅ luôn next round (đúng hay sai)
    setState(() {
      round++;
    });

    Future.delayed(const Duration(seconds: 1), _nextRound);
  }

  void _showFlyingStar() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final renderBox = _starKey.currentContext?.findRenderObject() as RenderBox?;
    final starTargetPos = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    final screenSize = MediaQuery.of(context).size;
    final startPos = Offset(screenSize.width / 2, screenSize.height / 2);

    final entry = OverlayEntry(
      builder: (_) => FlyingStar(
        start: startPos,
        end: starTargetPos,
        onComplete: () {
          setState(() {
            // 👑 đủ 5 sao thì +1 vương miện
            if (starCount % 5 == 0) {
              crownCount++;
              _playSound("crown.mp3");
            }
          });
          _starOverlay?.remove();
          _starOverlay = null;
        },
      ),
    );

    overlay.insert(entry);
    _starOverlay = entry;
  }

  void _showLevelComplete() {
    String msg =
        "Bạn đã hoàn thành $maxRound câu của Level $level!\n⭐ Sao đạt được: $starCount";
    if (crownCount > 0) {
      msg += "\n👑 Vương miện: $crownCount";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Hoàn thành level!"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                level++;
                round = 0;
                streak = 0;
              });
              _nextRound();
            },
            child: const Text("Tiếp tục Level mới"),
          ),
        ],
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
    starCount = 0;
    crownCount = 0;
    _nextRound();
  }

  @override
  Widget buildGame(BuildContext context) {
    if (targetLetter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = round / maxRound;

    return Stack(
      children: [
        Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(
                value: progress > 1 ? 1 : progress,
                minHeight: 12,
                borderRadius: BorderRadius.circular(12),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.pinkAccent.shade200,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Level $level - Câu $round/$maxRound",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Row(
                  key: _starKey,
                  children: [
                    const Text("⭐ ",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("$starCount  ",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    const Text("👑 ",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("$crownCount",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text(
              "Hãy tìm chữ cái sau:",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            ScaleTransition(
              scale: _scaleAnimation,
              child: Text(
                targetLetter!.char,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
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

                  return GestureDetector(
                    onTap: selected == null ? () => _checkAnswer(letter) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: correctChoice
                              ? [Colors.green.shade400, Colors.green.shade200]
                              : wrongChoice
                              ? [Colors.red.shade400, Colors.red.shade200]
                              : [Colors.blue.shade200, Colors.blue.shade50],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          )
                        ],
                      ),
                      child: Text(
                        letter.char,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
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
    );
  }
}

class FlyingStar extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onComplete;

  const FlyingStar(
      {super.key, required this.start, required this.end, required this.onComplete});

  @override
  State<FlyingStar> createState() => _FlyingStarState();
}

class _FlyingStarState extends State<FlyingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _position = Tween<Offset>(
      begin: widget.start,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scale = Tween<double>(begin: 1.2, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    _controller.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Positioned(
          left: _position.value.dx,
          top: _position.value.dy,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: const Icon(
                Icons.star,
                size: 60,
                color: Colors.yellow,
              ),
            ),
          ),
        );
      },
    );
  }
}
