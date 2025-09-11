class LetterAssets {
  static String getImage(String filename, {bool isDark = false}) {
    final theme = isDark ? "dark" : "light";
    return "assets/images/$theme/$filename";
  }

  static String getAudio(String filename) {
    return "assets/audio/$filename";
  }
}
