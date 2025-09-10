import 'package:flutter/material.dart';
import '../models/vn_letter.dart';
import '../services/letter_loader.dart';
import 'letter_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Color> pastelColors = const [
    Color(0xFFFFF9C4), // vàng nhạt
    Color(0xFFFFE0B2), // cam nhạt
    Color(0xFFB2DFDB), // xanh ngọc nhạt
    Color(0xFFC8E6C9), // xanh lá nhạt
    Color(0xFFD1C4E9), // tím nhạt
    Color(0xFFFFCDD2), // hồng nhạt
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE1F5FE), Color(0xFFFFFDE7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Bé học chữ cái tiếng Việt',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<List<VnLetter>>(
          future: LetterLoader.load(), // 🔥 đọc JSON
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Lỗi tải dữ liệu: ${snapshot.error}"),
              );
            }
            final letters = snapshot.data ?? [];
            if (letters.isEmpty) {
              return const Center(child: Text("Chưa có dữ liệu chữ cái."));
            }

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: letters.length,
                itemBuilder: (context, index) {
                  final letter = letters[index];
                  final bgColor = pastelColors[index % pastelColors.length];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LetterScreen(letter: letter),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (letter.imagePath != null)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  letter.imagePath!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          Text(
                            letter.char,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
