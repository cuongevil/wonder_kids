import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý tiến độ game: lưu & lấy điểm số.
/// Nếu SharedPreferences không khả dụng (ví dụ Web lỗi), sẽ fallback vào Map in-memory.
class ProgressService {
  static const String _prefix = "game_progress_";

  /// Fallback bộ nhớ tạm
  static final Map<String, int> _memoryStore = {};

  static Future<void> saveProgress(String gameId, int score, int round) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${gameId}_score", score);
    await prefs.setInt("${gameId}_round", round);
  }

  static Future<Map<String, int>> loadProgress(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt("${gameId}_score") ?? 0;
    final round = prefs.getInt("${gameId}_round") ?? 0;
    return {"score": score, "round": round};
  }

  static Future<(int score, int total)> getProgress(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final score = prefs.getInt("$_prefix${gameId}_score") ?? 0;
      final total = prefs.getInt("$_prefix${gameId}_total") ?? 0;
      return (score, total);
    } catch (e) {
      final score = _memoryStore["${gameId}_score"] ?? 0;
      final total = _memoryStore["${gameId}_total"] ?? 0;
      return (score, total);
    }
  }

  static Future<void> resetProgress(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("${gameId}_score");
    await prefs.remove("${gameId}_round");
  }
}
