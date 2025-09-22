import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

import '../models/vn_letter.dart';

// 🎨 loại bút
enum BrushType { normal, rainbow, neon, glitter }

class WriteScreen extends StatefulWidget {
  final List<VnLetter> letters;
  final int startIndex;

  const WriteScreen({
    super.key,
    required this.letters,
    this.startIndex = 0,
  });

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  late int currentIndex;
  final ValueNotifier<List<List<Offset>>> strokesNotifier =
  ValueNotifier<List<List<Offset>>>([]);
  final List<List<Offset>> _redoStack = [];

  Color penColor = Colors.blue;
  double strokeWidth = 8.0;
  bool showGuide = true;
  BrushType brushType = BrushType.normal; // ✅ mặc định

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.startIndex.clamp(0, widget.letters.length - 1);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _nextLetter() {
    _confettiController.play();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        currentIndex = (currentIndex + 1) % widget.letters.length;
        strokesNotifier.value = [];
        _redoStack.clear();
      });
    });
  }

  void _clear() {
    strokesNotifier.value = [];
    _redoStack.clear();
  }

  void _undo() {
    if (strokesNotifier.value.isNotEmpty) {
      final newStrokes = List<List<Offset>>.from(strokesNotifier.value);
      final last = newStrokes.removeLast();
      _redoStack.add(last);
      strokesNotifier.value = newStrokes;
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final newStrokes = List<List<Offset>>.from(strokesNotifier.value)
        ..add(_redoStack.removeLast());
      strokesNotifier.value = newStrokes;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.letters.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Không có dữ liệu chữ để luyện viết")),
      );
    }

    final letter = widget.letters[currentIndex];

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ cho phép bottomSheet đẩy body lên
      appBar: AppBar(
        title: Text("Bé tập viết: ${letter.char}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _nextLetter,
          ),
        ],
      ),
      body: Builder( // ✅ lấy context sạch cho bottomSheet
        builder: (scaffoldContext) {
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (details) {
                        final newStrokes =
                        List<List<Offset>>.from(strokesNotifier.value)
                          ..add([details.localPosition]);
                        strokesNotifier.value = newStrokes;
                      },
                      onPanUpdate: (details) {
                        final newStrokes =
                        List<List<Offset>>.from(strokesNotifier.value);
                        newStrokes.last.add(details.localPosition);
                        strokesNotifier.value = newStrokes;
                      },
                      child: ValueListenableBuilder<List<List<Offset>>>(
                        valueListenable: strokesNotifier,
                        builder: (_, strokes, __) {
                          return SizedBox.expand(
                            child: CustomPaint(
                              painter: _WritingPainter(
                                strokes,
                                penColor,
                                strokeWidth,
                                letter.char,
                                showGuide,
                                brushType,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 🎨 Toolbar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolbarButton(
                            Icons.undo, "Hoàn tác", _undo, Colors.pink),
                        _buildToolbarButton(
                            Icons.redo, "Làm lại", _redo, Colors.pink),
                        _buildToolbarButton(
                            Icons.clear, "Xóa", _clear, Colors.orange),
                        _buildToolbarButton(
                          showGuide ? Icons.grid_off : Icons.grid_on,
                          "Lưới",
                              () => setState(() => showGuide = !showGuide),
                          Colors.blue,
                        ),
                        _buildToolbarButton(Icons.brush, "Bút", () {
                          _showBrushOptions(scaffoldContext); // ✅ dùng context này
                        }, Colors.green),
                        _buildToolbarButton(Icons.palette, "Màu", () {
                          _showColorPalette(scaffoldContext); // ✅ dùng context này
                        }, Colors.purple),
                      ],
                    ),
                  ),
                ],
              ),

              // 🎉 Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================================
  // 🔘 Toolbar button
  // ================================
  Widget _buildToolbarButton(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ================================
  // ✏️ Brush Options
  // ================================
  void _showBrushOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("✏️ Độ dày nét bút",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: strokeWidth,
                min: 2,
                max: 20,
                divisions: 9,
                label: strokeWidth.toStringAsFixed(0),
                onChanged: (v) {
                  setState(() => strokeWidth = v);
                },
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Hoàn tất"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================
  // 🎨 Color Palette
  // ================================
  void _showColorPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: _buildColorPalette(ctx),
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context) {
    final pastelColors = [
      Colors.pink.shade200,
      Colors.purple.shade200,
      Colors.blue.shade200,
      Colors.cyan.shade200,
      Colors.teal.shade200,
      Colors.green.shade200,
      Colors.lightGreen.shade200,
      Colors.lime.shade200,
      Colors.yellow.shade200,
      Colors.orange.shade200,
      Colors.deepOrange.shade200,
      Colors.red.shade200,
      Colors.brown.shade200,
      Colors.grey.shade400,
      Colors.indigo.shade200,
      Colors.amber.shade200,
      Colors.blueGrey.shade200,
      Colors.pink.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🎨 Bảng màu pastel",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pastelColors.map((c) {
              final isSelected =
                  penColor == c && brushType == BrushType.normal;
              return InkWell(
                onTap: () {
                  setState(() {
                    penColor = c;
                    brushType = BrushType.normal;
                  });
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                      isSelected ? Colors.white : Colors.grey.shade300,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: c.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                      color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text("✨ Bút đặc biệt",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _buildSpecialBrush("🌈", "Cầu vồng", BrushType.rainbow),
              _buildSpecialBrush("🔥", "Neon", BrushType.neon),
              _buildSpecialBrush("✨", "Nhũ", BrushType.glitter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialBrush(String emoji, String label, BrushType type) {
    final isSelected = brushType == type;
    return InkWell(
      onTap: () {
        setState(() => brushType = type);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.pink : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ===================================================
// 🎨 Painter
// ===================================================
class _WritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color penColor;
  final double strokeWidth;
  final String letter;
  final bool showGuide;
  final BrushType brushType;

  _WritingPainter(this.strokes, this.penColor, this.strokeWidth, this.letter,
      this.showGuide, this.brushType);

  @override
  void paint(Canvas canvas, Size size) {
    // 🟦 Dòng kẻ tập viết chuẩn
    if (showGuide) {
      final lineBold = Paint()
        ..color = Colors.blue.shade300
        ..strokeWidth = 2;
      final lineThin = Paint()
        ..color = Colors.blue.shade100
        ..strokeWidth = 1;

      double top = size.height / 3;
      double mid = size.height / 2;
      double bottom = size.height * 2 / 3;

      canvas.drawLine(Offset(0, top), Offset(size.width, top), lineBold);
      canvas.drawLine(Offset(0, mid), Offset(size.width, mid), lineThin);
      canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), lineBold);
    }

    // 🅰️ Chữ nền xám mờ
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: GoogleFonts.fredoka(
          fontSize: size.width / 2,
          fontWeight: FontWeight.bold,
          color: Colors.black.withOpacity(0.15),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );

    // 🖊️ Bút vẽ
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke;

      switch (brushType) {
        case BrushType.normal:
          paint.color = penColor;
          break;
        case BrushType.rainbow:
          paint.shader = LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
          break;
        case BrushType.neon:
          paint.color = penColor;
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          break;
        case BrushType.glitter:
          paint.color = penColor;
          for (final p in stroke) {
            if (p.dx.toInt() % 15 == 0) {
              canvas.drawCircle(
                  p, 1.5, Paint()..color = Colors.white.withOpacity(0.7));
            }
          }
          break;
      }

      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, strokeWidth / 2, paint);
      } else {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length - 1; i++) {
          final p1 = stroke[i];
          final p2 = stroke[i + 1];
          final midPoint =
          Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
        }
        path.lineTo(stroke.last.dx, stroke.last.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPainter old) {
    return old.strokes != strokes ||
        old.penColor != penColor ||
        old.strokeWidth != strokeWidth ||
        old.letter != letter ||
        old.showGuide != showGuide ||
        old.brushType != brushType;
  }
}
