import '../models/vn_letter.dart';
import 'letter_mapping.dart';

List<VnLetter> buildLetters() {
  return letterFileToChar.entries.map((entry) {
    final fileKey = entry.key;   // ví dụ: A_breve
    final char = entry.value;    // ví dụ: Ă
    return VnLetter(
      char: char,
      sampleWord: null,
      imagePath: 'assets/images/letters/$fileKey.png',
      audioPath: 'assets/audio/letters/$fileKey.wav',
    );
  }).toList();
}

final List<VnLetter> kVnLetters = buildLetters();
