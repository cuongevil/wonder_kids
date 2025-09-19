import 'package:flutter/material.dart';
import '../services/progress_service.dart';

class GameInfo {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  int score;
  int round;

  GameInfo({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    this.score = 0,
    this.round = 0,
  });

  /// Load progress từ SharedPreferences
  static Future<GameInfo> withProgress(GameInfo game) async {
    final progress = await ProgressService.loadProgress(game.id);
    return GameInfo(
      id: game.id,
      title: game.title,
      icon: game.icon,
      color: game.color,
      route: game.route,
      score: progress['score'] ?? 0,
      round: progress['round'] ?? 0,
    );
  }
}
