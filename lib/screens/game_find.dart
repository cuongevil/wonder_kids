import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/vn_letter.dart';
import '../services/audio_service.dart';
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
  String get title => "Trò chơi tìm chữ";

  List<VnLetter> letters = [];
  VnLetter? targetLetter;
  List<VnLetter> options = [];
  VnLetter? selected;
  bool isCorrect = false;

  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadLetters();

    _controller =
        AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_controller);

    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
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
  }

  void _checkAnswer(VnLetter chosen) async {
    setState(() {
      selected = chosen;
      isCorrect = (chosen.char == targetLetter!.char);
    });

    if (isCorrect) {
      _confettiController.play();
      await onAnswer(true);
      Future.delayed(const Duration(seconds: 1), _nextRound);
    } else {
      _controller.forward(from: 0);
      await onAnswer(false);
      Future.delayed(const Duration(seconds: 1), () {
        setState(() => selected = null);
      });
    }
  }

  @override
  void onReset() {
    selected = null;
    isCorrect = false;
    _nextRound();
  }

  @override
  Widget buildGame(BuildContext context) {
    if (targetLetter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Hãy tìm chữ cái sau:",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Text(targetLetter!.char,
            style: const TextStyle(
                fontSize: 72, fontWeight: FontWeight.bold, color: Colors.pink)),
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
                    color: correctChoice
                        ? Colors.green
                        : wrongChoice
                        ? Colors.red
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(letter.char,
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
