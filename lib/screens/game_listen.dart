import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vn_letter.dart';
import '../widgets/game_base.dart';
import '../services/audio_service.dart';

class GameListen extends StatefulWidget {
  const GameListen({super.key});

  @override
  State<GameListen> createState() => _GameListenState();
}

class _GameListenState extends GameBaseState<GameListen> {
  @override
  String get gameId => "game4";

  @override
  String get title => "Trò chơi nghe & chọn";

  List<VnLetter> letters = [];
  VnLetter? targetLetter;
  List<VnLetter> options = [];

  @override
  void initState() {
    super.initState();
    _loadLetters();
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

    // chọn thêm 3 chữ khác để làm đáp án sai
    final shuffled = [...letters]..shuffle();
    options = ([targetLetter!, ...shuffled.take(3)]..shuffle());

    // phát âm thanh
    if (targetLetter!.audioPath != null) {
      AudioService.play(targetLetter!.audioPath!);
    }
  }

  void _checkAnswer(VnLetter chosen) async {
    final isCorrect = chosen.char == targetLetter!.char;
    await onAnswer(isCorrect);

    if (isCorrect) {
      AudioService.play("audio/correct.mp3");
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() => _nextRound());
      });
    } else {
      AudioService.play("audio/wrong.mp3");
    }
  }

  @override
  void onReset() {
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
        const Text("Nghe âm thanh và chọn chữ đúng",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: () {
            if (targetLetter!.audioPath != null) {
              AudioService.play(targetLetter!.audioPath!);
            }
          },
          icon: const Icon(Icons.volume_up, size: 28),
          label: const Text("Nghe lại",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),

        const SizedBox(height: 40),

        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: options.map((l) {
            return GestureDetector(
              onTap: () => _checkAnswer(l),
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
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
                      fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
