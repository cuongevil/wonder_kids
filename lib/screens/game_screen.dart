import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vn_letter.dart';
import '../services/audio_service.dart';
import '../utils/letter_assets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
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

    // lấy thêm vài lựa chọn sai
    final shuffled = [...letters]..shuffle();
    options = (shuffled.take(5).toList()..add(targetLetter!))..shuffle();

    // phát âm thanh: "Hãy tìm chữ X"
    if (targetLetter!.audioPath != null) {
      AudioService.play(LetterAssets.getAudio(targetLetter!.audioPath!));
    }
  }

  void _checkAnswer(VnLetter chosen) {
    if (chosen.char == targetLetter!.char) {
      // đúng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Giỏi lắm!")),
      );
      AudioService.play("audio/correct.mp3"); // âm thanh đúng
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _nextRound();
        });
      });
    } else {
      // sai
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Sai rồi, thử lại nhé!")),
      );
      AudioService.play("audio/wrong.mp3"); // âm thanh sai
    }
  }

  @override
  Widget build(BuildContext context) {
    if (targetLetter == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎮 Trò chơi tìm chữ"),
        backgroundColor: Colors.pinkAccent.shade100,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Hãy tìm chữ cái sau:",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              targetLetter!.char,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: options.map((letter) {
                return GestureDetector(
                  onTap: () => _checkAnswer(letter),
                  child: Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.primaries[
                      letter.char.codeUnitAt(0) %
                          Colors.primaries.length]
                          .shade200,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        )
                      ],
                    ),
                    child: Text(
                      letter.char,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                if (targetLetter!.audioPath != null) {
                  AudioService.play(
                      LetterAssets.getAudio(targetLetter!.audioPath!));
                }
              },
              icon: const Icon(Icons.volume_up),
              label: const Text("Nghe lại"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
