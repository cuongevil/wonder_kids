class VnLetter {
  final String key;
  final String char;
  final String? sampleWord;
  final String? imagePath;
  final String? gameImagePath;
  final String? audioPath;

  const VnLetter({
    required this.key,
    required this.char,
    this.sampleWord,
    this.imagePath,
    this.gameImagePath,
    this.audioPath,
  });

  factory VnLetter.fromJson(Map<String, dynamic> json) {
    return VnLetter(
      key: json['key'] as String,
      char: json['char'] as String,
      sampleWord: json['word'] as String?,
      imagePath: json['imagePath'] as String?,
      gameImagePath: json['gameImagePath'] as String?,
      audioPath: json['audioPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'char': char,
    'word': sampleWord,
    'imagePath': imagePath,
    'gameImagePath': gameImagePath,
    'audioPath': audioPath,
  };
}
