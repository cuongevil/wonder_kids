import 'package:flutter/material.dart';
import '../screens/start_screen.dart';
import '../screens/home_screen.dart';
import '../screens/flashcard_screen.dart';
import '../screens/letter_screen.dart';
import '../screens/game_screen.dart';
import '../models/vn_letter.dart';

class AppRoutes {
  static const String start = '/';
  static const String home = '/home';
  static const String flashcard = '/flashcard';
  static const String letter = '/letter';
  static const String game = '/game';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case start:
        return MaterialPageRoute(builder: (_) => const StartScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case flashcard:
        return MaterialPageRoute(builder: (_) => const FlashcardScreen());

      case game:
        return MaterialPageRoute(builder: (_) => const GameScreen());

      case letter:
      // arguments: Map { "letters": List<VnLetter>, "currentIndex": int }
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => LetterScreen(
            letters: args['letters'] as List<VnLetter>,
            currentIndex: args['currentIndex'] as int,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Route không tồn tại")),
          ),
        );
    }
  }
}
