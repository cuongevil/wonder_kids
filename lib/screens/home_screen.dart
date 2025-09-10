import 'package:flutter/material.dart';
import '../widgets/letter_card.dart';
import '../services/letter_loader.dart';
import '../models/vn_letter.dart';
import 'letter_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bé học chữ cái tiếng Việt'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<VnLetter>>(
        future: LetterLoader.load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
            );
          }
          final letters = snapshot.data ?? [];
          if (letters.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu chữ cái.'));
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: letters.length,
              itemBuilder: (context, index) {
                final letter = letters[index];
                return LetterCard(
                  letter: letter,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LetterScreen(letter: letter),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
