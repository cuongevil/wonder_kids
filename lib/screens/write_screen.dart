import 'package:flutter/material.dart';
import '../models/vn_letter.dart';
import '../services/audio_service.dart';

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
  final List<Offset> points = [];
  Color penColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.startIndex;
  }

  void _nextLetter() {
    setState(() {
      if (currentIndex < widget.letters.length - 1) {
        currentIndex++;
        points.clear();
      } else {
        currentIndex = 0; // quay lại chữ đầu
        points.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letters[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Luyện viết: ${letter.char}"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {
              if (letter.audioPath != null) {
                AudioService.play(letter.audioPath!);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final box = context.findRenderObject() as RenderBox;
                  points.add(box.globalToLocal(details.globalPosition));
                });
              },
              onPanEnd: (_) => points.add(Offset.zero),
              child: CustomPaint(
                painter: _WritingPainter(points, penColor, letter.char),
                size: Size.infinite,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => points.clear());
                },
                icon: const Icon(Icons.clear),
                label: const Text("Xóa"),
              ),
              ElevatedButton.icon(
                onPressed: _nextLetter,
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Tiếp tục"),
              ),
              DropdownButton<Color>(
                value: penColor,
                items: const [
                  DropdownMenuItem(value: Colors.blue, child: Text("Xanh")),
                  DropdownMenuItem(value: Colors.red, child: Text("Đỏ")),
                  DropdownMenuItem(value: Colors.green, child: Text("Xanh lá")),
                ],
                onChanged: (c) {
                  if (c != null) setState(() => penColor = c);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// CustomPainter để vẽ nét viết + chữ cái mờ
class _WritingPainter extends CustomPainter {
  final List<Offset> points;
  final Color penColor;
  final String letter;

  _WritingPainter(this.points, this.penColor, this.letter);

  @override
  void paint(Canvas canvas, Size size) {
    // chữ cái mờ làm nền
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.width / 2,
          color: Colors.black.withOpacity(0.1),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2),
    );

    // nét viết của bé
    final paint = Paint()
      ..color = penColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_WritingPainter oldDelegate) => true;
}
