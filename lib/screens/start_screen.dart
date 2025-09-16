import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/app_routes.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

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
          child: Stack(
            children: [
              // ⭐ Sao bay nền
              const FloatingBackground(),

              Column(
                children: [
                  const SizedBox(height: 16),

                  // 🌈 Tiêu đề gradient
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.pink, Colors.purple, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      "✨ Bé học chữ cái ✨",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🐙 Mascot có animation
                  const BouncingMascot(),

                  const SizedBox(height: 24),

                  // 🎨 Các nút WOW
                  WowButton(
                    title: "Học theo thứ tự",
                    iconPath: "assets/images/icon_book.png",
                    routeName: AppRoutes.home,
                    colors: [Colors.pinkAccent, Colors.orangeAccent, Colors.yellow],
                  ),
                  WowButton(
                    title: "Flashcard",
                    iconPath: "assets/images/icon_flashcard.png",
                    routeName: AppRoutes.flashcard,
                    colors: [Colors.lightBlueAccent, Colors.purpleAccent, Colors.blueAccent],
                  ),
                  WowButton(
                    title: "Trò chơi tìm chữ",
                    iconPath: "assets/images/icon_game.png",
                    routeName: AppRoutes.game,
                    colors: [Colors.yellowAccent, Colors.pinkAccent, Colors.redAccent],
                  ),

                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🐙 Mascot nhún nhảy
class BouncingMascot extends StatefulWidget {
  const BouncingMascot({super.key});

  @override
  State<BouncingMascot> createState() => _BouncingMascotState();
}

class _BouncingMascotState extends State<BouncingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: RotationTransition(
        turns: Tween(begin: -0.01, end: 0.01).animate(_c),
        child: Image.asset(
          "assets/images/mascot.png",
          height: 250,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.pets, size: 120, color: Colors.white70),
        ),
      ),
    );
  }
}

/// ⭐ Sao bay nền
class FloatingBackground extends StatelessWidget {
  const FloatingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        6,
            (i) => _FloatingItem(
          left: 40.0 + i * 50,
          delay: i * 500,
        ),
      ),
    );
  }
}

class _FloatingItem extends StatefulWidget {
  final double left;
  final int delay;

  const _FloatingItem({required this.left, required this.delay});

  @override
  State<_FloatingItem> createState() => _FloatingItemState();
}

class _FloatingItemState extends State<_FloatingItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final random = math.Random();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final dy = MediaQuery.of(context).size.height *
            (1 - (_c.value + widget.delay / 6000) % 1);
        return Positioned(
          left: widget.left + random.nextDouble() * 20,
          top: dy,
          child: Opacity(
            opacity: 0.6,
            child: Icon(
              Icons.star,
              size: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        );
      },
    );
  }
}

/// 🍭 Nút WOW cho bé
class WowButton extends StatefulWidget {
  final String title;
  final String iconPath;
  final String routeName;
  final List<Color> colors;

  const WowButton({
    super.key,
    required this.title,
    required this.iconPath,
    required this.routeName,
    required this.colors,
  });

  @override
  State<WowButton> createState() => _WowButtonState();
}

class _WowButtonState extends State<WowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          Navigator.pushNamed(context, widget.routeName);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = (0.5 + 0.5 * (1 + math.sin(_c.value * math.pi * 2)));
            final scale = (_pressed ? 0.93 : 0.97) + 0.06 * t;

            return Transform.scale(
              scale: scale,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: widget.colors.last.withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 3,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      widget.iconPath,
                      height: 40,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.star, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 3,
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
      ),
    );
  }
}
