import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vn_letter.dart';
import '../widgets/game_base.dart';
import '../services/audio_service.dart';

class GameFill extends StatefulWidget {
  const GameFill({super.key});

  @override
  State<GameFill> createState() => _GameFillState();
}

class _GameFillState extends GameBaseState<GameFill> {
  @override
  String get gameId => "game3";

  @override
  String get title => "Trò chơi điền chữ";

  List<VnLetter> letters = [];
  VnLetter? answerLetter;
  String? sampleWord; // từ có chỗ trống
  List<String> displayed; // từ với dấu _ trống
  List<VnLetter> options = [];

  _GameFillState() : displayed = [];

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
    answerLetter = letters[random.nextInt(letters.length)];

    // lấy word từ model (nếu có), fallback là chính chữ đó
    sampleWord = answerLetter!.sampleWord ?? answerLetter!.char;

    // chọn ngẫu nhiên vị trí bỏ trống (1 chữ trong từ)
    final chars = sampleWord!.split('');
    final idx = random.nextInt(chars.length);
    chars[idx] = "_";
    displayed = chars;

    // tạo options: 1 chữ đúng + 3 chữ sai
    final shuffled = [...letters]..shuffle();
    options = [answerLetter!, ...shuffled.take(3)].toList()..shuffle();
  }

  void _checkAnswer(VnLetter chosen) async {
    final isCorrect = chosen.char == answerLetter!.char;
    await onAnswer(isCorrect);

    if (isCorrect) {
      AudioService.play("audio/correct.mp3");
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _nextRound();
        });
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
    if (answerLetter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        const Text("Điền chữ cái còn thiếu",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),

        // hiển thị từ có chỗ trống
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
                color: c == "_"
                    ? Colors.pink
                    : Colors.black87,
              ),
            ),
          ))
              .toList(),
        ),

        const SizedBox(height: 32),

        // lựa chọn chữ cái
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: options.map((l) {
            return GestureDetector(
              onTap: () => _checkAnswer(l),
              child: Container(
                width: 70,
                height: 70,
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
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
