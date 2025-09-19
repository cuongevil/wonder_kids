import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';

class MascotWidget extends StatefulWidget {
  const MascotWidget({super.key});

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _orbitController;
  late AnimationController _glowController;

  // Biểu cảm khác nhau
  final List<String> _expressions = [
    "assets/images/mascot.png",
    "assets/images/mascot_1.png",
    "assets/images/mascot_2.png",
    "assets/images/mascot_3.png",
    "assets/images/mascot_4.png",
    "assets/images/mascot_5.png",
    "assets/images/mascot_6.png",
    "assets/images/mascot_7.png",
    "assets/images/mascot_8.png",
    "assets/images/mascot_9.png",
    "assets/images/mascot_10.png",
  ];
  late String _currentExpression;
  Timer? _expressionTimer;

  @override
  void initState() {
    super.initState();

    _currentExpression = _expressions.first;

    // Animation controllers
    _bounceController =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    _orbitController =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _glowController =
    AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    // Random thay đổi biểu cảm 5s/lần
    _expressionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        _currentExpression =
            (_expressions..shuffle()).first; // chọn ngẫu nhiên
      });
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _orbitController.dispose();
    _glowController.dispose();
    _expressionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "mascot",
      child: GestureDetector(
        onTap: () {
          // Khi bé tap → mascot nhảy + phát tiếng cười
          HapticFeedback.lightImpact();
          AudioService.play("audio/correct.mp3"); // thay bằng audio cười vui
          _bounceController.forward(from: 0.0);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow gradient
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final scale = 1 + 0.2 * _glowController.value;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.yellow.withOpacity(0.6),
                          Colors.pink.withOpacity(0.2),
                          Colors.transparent
                        ],
                        stops: const [0.3, 0.6, 1],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Mascot chính
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, child) {
                final offset =
                    math.sin(_bounceController.value * 2 * math.pi) * 8;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
              child: Image.asset(_currentExpression, height: 120),
            ),

            // Các icon nhỏ bay quanh
            ...List.generate(5, (i) {
              return AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  final angle = _orbitController.value * 2 * math.pi +
                      (i * 2 * math.pi / 5);
                  final radius = 80.0;
                  final dx = math.cos(angle) * radius;
                  final dy = math.sin(angle) * radius;

                  return Positioned(
                    left: 60 + dx,
                    top: 60 + dy,
                    child: Opacity(
                      opacity: 0.7,
                      child: Icon(
                        i.isEven ? Icons.star : Icons.favorite,
                        color: i.isEven ? Colors.yellow : Colors.pinkAccent,
                        size: 18,
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
