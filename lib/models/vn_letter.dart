class VnLetter {
  final String char;
  final String? sampleWord;
  final String? imagePath;
  final String? audioPath;

  const VnLetter({
    required this.char,
    this.sampleWord,
    this.imagePath,
    this.audioPath,
  });

  factory VnLetter.fromJson(Map<String, dynamic> json) {
    return VnLetter(
      char: json['char'] as String,
      sampleWord: json['word'] as String?,
      imagePath: json['imagePath'] as String?,
      audioPath: json['audioPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'char': char,
    'word': sampleWord,
    'imagePath': imagePath,
    'audioPath': audioPath,
  };
}
