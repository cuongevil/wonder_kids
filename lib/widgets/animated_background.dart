import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final String currentLetter;

  const AnimatedBackground({
    super.key,
    required this.child,
    required this.currentLetter,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _buildFallingEmojis(String letter) {
    final emojis = letterEmojis[letter] ?? ["✨", "☁️"];
    final items = <Widget>[];
    for (int i = 0; i < 10; i++) {
      final emoji = emojis[i % emojis.length];
      final startX =
          _random.nextDouble() *
          MediaQuery.of(context).size.width.clamp(200, 400);
      final delay = _random.nextDouble();
      final size = [24.0, 32.0, 40.0][_random.nextInt(3)];
      final rotationDirection = _random.nextBool() ? 1 : -1;
      final amplitude = 30 + _random.nextDouble() * 40;
      items.add(
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = (_controller.value + delay) % 1.0;
            final top = MediaQuery.of(context).size.height * value - 50;
            final left = startX + amplitude * sin(value * 2 * pi);
            final rotation = value * 2 * pi * 0.05 * rotationDirection;
            return Positioned(
              top: top,
              left: left,
              child: Opacity(
                opacity: 1.0 - value,
                child: Transform.rotate(
                  angle: rotation,
                  child: Text(emoji, style: TextStyle(fontSize: size)),
                ),
              ),
            );
          },
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF1F3), Color(0xFFD1E9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        widget.child,
        ..._buildFallingEmojis(widget.currentLetter),
      ],
    );
  }
}

/// Emoji mapping cơ bản
final Map<String, List<String>> letterEmojis = {
  "A": ["👕", "🧥"], // Áo
  "Ă": ["🍽️", "🍚"], // Ăn
  "Â": ["🍵", "🔥"], // Ấm (ấm trà / ấm áp)
  "B": ["👶", "🎈"], // Bé, Bóng
  "C": ["🐟", "🐶"], // Cá, Cún
  "D": ["🐐", "🍉"], // Dê, Dưa (dưa hấu)
  "Đ": ["🏮", "🧊"], // Đèn, Đá
  "E": ["👧", "🐦"], // Em, Én
  "Ê": ["🛏️", "🐸"], // Êm, Ếch
  "G": ["🐔", "🪵"], // Gà, Gỗ
  "H": ["🌸", "📖"], // Hoa, Học
  "I": ["➖", "🖨️"], // Ít, In
  "K": ["🍬", "🔑"], // Kẹo, Khóa
  "L": ["🍃", "🍐"], // Lá, Lê
  "M": ["👩", "🐱"], // Mẹ, Mèo
  "N": ["🎀", "👒"], // Nơ, Nón
  "O": ["🐝", "🍯"], // Ong, (mật) Ong
  "Ô": ["🚗", "☂️"], // Ô tô, Ô (dù)
  "Ơ": ["🗣️", "🏠"], // Ơi, Ở (nhà)
  "P": ["🍜", "☕"], // Phở, Phin (cà phê)
  "Q": ["🍎", "🪭"], // Quả, Quạt
  "R": ["🐢", "🌳"], // Rùa, Rừng
  "S": ["⭐", "📚"], // Sao, Sách
  "T": ["🍤", "🍎"], // Tôm, Táo
  "U": ["👶", "🥤"], // Út, Uống
  "Ư": ["🌠", "💭"], // Ước, Ưu (ý niệm/ưu tiên)
  "V": ["🐘", "🌿"], // Voi, Vườn
  "X": ["🥭", "🚲"], // Xoài, Xe (đạp)
  "Y": ["❤️", "💡"], // Yêu, Ý (tưởng)
};
