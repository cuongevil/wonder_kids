import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vn_letter.dart';
import '../widgets/game_base.dart';
import '../services/audio_service.dart';

class GameMatch extends StatefulWidget {
  const GameMatch({super.key});

  @override
  State<GameMatch> createState() => _GameMatchState();
}

class _GameMatchState extends GameBaseState<GameMatch> {
  @override
  String get gameId => "game2";

  @override
  String get title => "Xếp hình chữ cái";

  List<VnLetter> letters = [];
  List<_Pair> pairs = []; // danh sách (chữ, ảnh)
  VnLetter? selectedLetter;
  VnLetter? selectedImage;

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
    final selected = [...letters]..shuffle();
    final chosen = selected.take(4).toList(); // 4 cặp mỗi lần

    pairs = chosen.map((l) => _Pair(letter: l, image: l.imagePath)).toList();
    pairs.shuffle();

    selectedLetter = null;
    selectedImage = null;
  }

  void _onTapLetter(VnLetter l) {
    setState(() => selectedLetter = l);
    _checkMatch();
  }

  void _onTapImage(VnLetter l) {
    setState(() => selectedImage = l);
    _checkMatch();
  }

  void _checkMatch() async {
    if (selectedLetter == null || selectedImage == null) return;

    final isCorrect = selectedLetter!.char == selectedImage!.char;
    await onAnswer(isCorrect);

    if (isCorrect) {
      AudioService.play("audio/correct.mp3");
      setState(() {
        pairs.removeWhere((p) => p.letter.char == selectedLetter!.char);
        selectedLetter = null;
        selectedImage = null;
      });

      if (pairs.isEmpty) {
        Future.delayed(const Duration(seconds: 1), _nextRound);
      }
    } else {
      AudioService.play("audio/wrong.mp3");
      setState(() {
        selectedLetter = null;
        selectedImage = null;
      });
    }
  }

  @override
  void onReset() {
    _nextRound();
  }

  @override
  Widget buildGame(BuildContext context) {
    if (pairs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text("Ghép chữ với hình tương ứng",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: pairs.map((p) {
                    return GestureDetector(
                      onTap: () => _onTapLetter(p.letter),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedLetter == p.letter
                              ? Colors.blue.shade200
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2))
                          ],
                        ),
                        child: Text(
                          p.letter.char,
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: pairs.map((p) {
                    return GestureDetector(
                      onTap: () => _onTapImage(p.letter),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedImage == p.letter
                              ? Colors.green.shade200
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2))
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
      ],
    );
  }
}

/// Cặp chữ + ảnh
class _Pair {
  final VnLetter letter;
  final String? image;
  _Pair({required this.letter, this.image});
}
