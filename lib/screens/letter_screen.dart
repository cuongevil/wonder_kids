import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/vn_letter.dart';
import '../services/tts_service.dart';


class LetterScreen extends StatefulWidget {
  final VnLetter letter;
  const LetterScreen({super.key, required this.letter});


  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> {
  final _tts = TtsService();
  final _player = AudioPlayer();

  @override
  void dispose() {
    _tts.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _speakLetter() async {
    await _tts.speak('Chữ ${widget.letter.char}');
  }

  Future<void> _speakSample() async {
    final s = widget.letter.sampleWord;
    if (s == null || s.isEmpty) return;
    await _tts.speak(s);
  }

  Future<void> _playAudioIfAny() async {
    final path = widget.letter.audioPath;
    if (path == null) return;
// Nếu bạn có file trong assets/audio/letters/, hãy bật dòng dưới và thêm AssetSource
    await _player.stop();
    await _player.play(AssetSource(path));
  }


  @override
  Widget build(BuildContext context) {
    final l = widget.letter;
    return Scaffold(
      appBar: AppBar(title: Text('Chữ ${l.char}')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.char,
              style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (l.sampleWord != null)
              Text(
                l.sampleWord!,
                style: const TextStyle(fontSize: 32),
              ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _speakLetter,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Phát âm chữ'),
                ),
                ElevatedButton.icon(
                  onPressed: l.sampleWord == null ? null : _speakSample,
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text('Đọc ví dụ'),
                ),
                ElevatedButton.icon(
                  onPressed: l.audioPath == null ? null : _playAudioIfAny,
                  icon: const Icon(Icons.music_note),
                  label: const Text('Âm thanh mẫu'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}