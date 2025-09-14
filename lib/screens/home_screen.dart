import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/vn_letter.dart';
import '../widgets/letter_card.dart';
import '../services/audio_service.dart';
import '../config/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VnLetter> letters = [];
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    final String response =
    await rootBundle.loadString('assets/config/letters.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      letters = data.map((e) => VnLetter.fromJson(e)).toList();
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    AudioService.play("audio/ting.mp3"); // hiệu ứng khi sang trang
  }

  @override
  Widget build(BuildContext context) {
    // chia danh sách chữ cái thành từng nhóm 6
    final chunks = <List<VnLetter>>[];
    for (var i = 0; i < letters.length; i += 6) {
      chunks.add(
        letters.sublist(i, i + 6 > letters.length ? letters.length : i + 6),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bé học chữ cái tiếng Việt"),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent.shade100,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: chunks.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, pageIndex) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - pageIndex;
                        value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                      }
                      return Transform.scale(
                        scale: value,
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(24),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: chunks[pageIndex].length,
                      itemBuilder: (context, index) {
                        final letter = chunks[pageIndex][index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.letter,
                              arguments: letter, // 👉 truyền sang LetterScreen
                            );
                          },
                          child: LetterCard(letter: letter),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            // Thanh chấm chỉ số trang
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(chunks.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.pinkAccent
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
