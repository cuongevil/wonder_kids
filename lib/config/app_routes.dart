import 'package:flutter/material.dart';
import '../models/vn_letter.dart';
import '../screens/start_screen.dart';
import '../screens/home_screen.dart';
import '../screens/flashcard_screen.dart';
import '../screens/letter_screen.dart';
import '../screens/game_screen.dart';

class AppRoutes {
  static const start = '/';
  static const home = '/home';
  static const flashcard = '/flashcard';
  static const letter = '/letter';
  static const game = '/game';

  static Map<String, WidgetBuilder> map() => {
    start: (_) => const StartScreen(),
    home: (_) => const HomeScreen(),
    flashcard: (_) => const FlashcardScreen(),
    game: (_) => const GameScreen(),
    letter: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as VnLetter;
      return LetterScreen(letter: args);
    }
  };
}
