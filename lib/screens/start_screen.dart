import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'home_screen.dart';
import 'flashcard_screen.dart';
import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _bgmPlayer;

  @override
  void initState() {
    super.initState();
    _bgmPlayer = AudioPlayer();
    _playBgmSafe();
  }

  Future<void> _playBgmSafe() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.35);

      // Ưu tiên mp3, nếu không có sẽ fallback sang wav
      final candidates = ["audio/bgm.mp3", "audio/bgm.wav"];
      for (final src in candidates) {
        try {
          await _bgmPlayer.play(AssetSource(src));
          // nếu play ok thì thoát
          return;
        } catch (_) {
          // thử cái tiếp theo
        }
      }
    } catch (e) {
      debugPrint("BGM error: $e");
    }
  }

  @override
  void dispose() {
    _bgmPlayer.stop();
    _bgmPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                "Bé học chữ cái",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 12),
              Image.asset(
                "assets/images/mascot.png",
                height: 150,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.pets, size: 120, color: Colors.white70),
              ),
              const SizedBox(height: 24),

              // Nút 1: Học theo thứ tự (hồng -> cam, động)
              AnimatedGradientButton(
                title: "Học theo thứ tự",
                iconPath: "assets/images/icon_book.png",
                screen: const HomeScreen(),
                gradient1: const [Color(0xFFF8BBD0), Color(0xFFFFCC80)],
                gradient2: const [Color(0xFFFFE0B2), Color(0xFFF48FB1)],
              ),

              // Nút 2: Flashcard (xanh -> tím, động)
              AnimatedGradientButton(
                title: "Flashcard",
                iconPath: "assets/images/icon_flashcard.png",
                screen: const FlashcardScreen(),
                gradient1: const [Color(0xFFB3E5FC), Color(0xFFD1C4E9)],
                gradient2: const [Color(0xFFCE93D8), Color(0xFF81D4FA)],
              ),

              // Nút 3: Trò chơi (vàng -> hồng, động)
              AnimatedGradientButton(
                title: "Trò chơi tìm chữ",
                iconPath: "assets/images/icon_game.png",
                screen: const GameScreen(),
                gradient1: const [Color(0xFFFFF59D), Color(0xFFF48FB1)],
                gradient2: const [Color(0xFFFFF176), Color(0xFFFF8A80)],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút full-width với gradient động "thở"
class AnimatedGradientButton extends StatefulWidget {
  final String title;
  final String iconPath;
  final Widget screen;
  final List<Color> gradient1;
  final List<Color> gradient2;

  const AnimatedGradientButton({
    super.key,
    required this.title,
    required this.iconPath,
    required this.screen,
    required this.gradient1,
    required this.gradient2,
  });

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          final colors = [
            Color.lerp(widget.gradient1[0], widget.gradient2[0], t)!,
            Color.lerp(widget.gradient1[1], widget.gradient2[1], t)!,
          ];
          return InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => widget.screen),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    widget.iconPath,
                    height: 28,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
