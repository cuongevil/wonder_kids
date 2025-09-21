import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/vn_letter.dart';

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
  final List<List<Offset>> _redoStack = []; // ✅ redo stack
  Color penColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.startIndex.clamp(0, widget.letters.length - 1);
  }

  void _nextLetter() {
    if (currentIndex < widget.letters.length - 1) {
      setState(() {
        currentIndex++;
        strokesNotifier.value = [];
        _redoStack.clear();
      });
    } else {
      setState(() {
        currentIndex = 0;
        strokesNotifier.value = [];
        _redoStack.clear();
      });
    }
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
      appBar: AppBar(
        title: Text("Luyện viết: ${letter.char}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _nextLetter,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
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
                      painter: _WritingPainter(strokes, penColor, letter.char),
                    ),
                  );
                },
              ),
            ),
          ),

          // 🎨 Toolbar
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: "Undo",
                  onPressed: _undo,
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: "Redo",
                  onPressed: _redo,
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: "Clear",
                  onPressed: _clear,
                ),

                // 🎨 chọn màu bút
                Row(
                  children: [
                    _buildColorDot(Colors.blue),
                    _buildColorDot(Colors.red),
                    _buildColorDot(Colors.green),
                    _buildColorDot(Colors.orange),
                    _buildColorDot(Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return GestureDetector(
      onTap: () => setState(() => penColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: penColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _WritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color penColor;
  final String letter;

  _WritingPainter(this.strokes, this.penColor, this.letter);

  @override
  void paint(Canvas canvas, Size size) {
    // chữ cái nền mờ
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: GoogleFonts.fredoka(
          fontSize: size.width / 2,
          fontWeight: FontWeight.bold,
          color: Colors.black.withOpacity(0.1),
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

    // bút vẽ
    final paint = Paint()
      ..color = penColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    // vẽ nét
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 4, paint);
      } else if (stroke.length > 1) {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length - 1; i++) {
          final p1 = stroke[i];
          final p2 = stroke[i + 1];
          final midPoint = Offset(
            (p1.dx + p2.dx) / 2,
            (p1.dy + p2.dy) / 2,
          );
          path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
        }
        path.lineTo(stroke.last.dx, stroke.last.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_WritingPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.penColor != penColor;
}
