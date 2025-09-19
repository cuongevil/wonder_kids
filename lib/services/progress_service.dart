import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static Future<void> saveProgress(
      String key, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${key}_score", score);
    await prefs.setInt("${key}_total", total);
  }

  static Future<Map<String, int>> loadProgress(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt("${key}_score") ?? 0;
    final total = prefs.getInt("${key}_total") ?? 0;
    return {"score": score, "total": total};
  }
}
