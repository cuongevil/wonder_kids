import 'package:flutter/material.dart';
import '../services/progress_service.dart';

abstract class GameBaseState<T extends StatefulWidget> extends State<T> {
  String get gameId;
  String get title;

  int score = 0;
  int round = 0;
  int combo = 0;

  Future<void> onAnswer(bool isCorrect) async {
    setState(() {
      round++;
      if (isCorrect) {
        score++;
        combo++;
      } else {
        combo = 0;
      }
    });

    // Lưu tiến độ
    await ProgressService.saveProgress(gameId, score, round);
  }

  void onReset(); // từng game override

  /// Nội dung riêng của game
  Widget buildGame(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.pinkAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                "⭐ $score/$round\n🔥 $combo",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Chơi lại",
            onPressed: onReset,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: buildGame(context),
      ),
    );
  }
}
