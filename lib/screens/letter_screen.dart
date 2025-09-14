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
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có âm thanh cho chữ này")),
      );
      return;
    }
    await _player.stop();
    await _player.play(AssetSource(path));
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.letter;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chữ ${l.char}"),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent.shade100,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Ảnh minh họa to full width
            if (l.imagePath != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Image.asset(
                  l.imagePath!,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.4,
                  fit: BoxFit.contain, // giữ tỉ lệ, không crop mất nội dung
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported, size: 120),
                ),
              ),

            const SizedBox(height: 20),

            // Từ ví dụ trong card bo tròn
            if (l.sampleWord != null)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Text(
                  l.sampleWord!,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // 3 nút tròn icon-only pastel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircleButton(
                  icon: Icons.volume_up,
                  color: Colors.pinkAccent,
                  onTap: _speakLetter,
                ),
                const SizedBox(width: 30),
                _buildCircleButton(
                  icon: Icons.record_voice_over,
                  color: Colors.blueAccent,
                  onTap: l.sampleWord == null ? null : _speakSample,
                ),
                const SizedBox(width: 30),
                _buildCircleButton(
                  icon: Icons.music_note,
                  color: Colors.green,
                  onTap: l.audioPath == null ? null : _playAudioIfAny,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: nút tròn pastel
  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(2, 4),
            )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
