class VnLetter {
  final String key;
  final String char;
  final String? sampleWord;
  final String? imagePath;
  final String? audioPath;

  const VnLetter({
    required this.key,
    required this.char,
    this.sampleWord,
    this.imagePath,
    this.audioPath,
  });

  factory VnLetter.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String;
    return VnLetter(
      key: key,
      char: json['char'] as String,
      sampleWord: json['word'] as String?,
      imagePath: 'assets/images/letters/$key.png',
      audioPath: 'audio/letters/$key.mp3',
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'char': char,
    'word': sampleWord,
    'imagePath': imagePath,
    'audioPath': audioPath,
  };
}
