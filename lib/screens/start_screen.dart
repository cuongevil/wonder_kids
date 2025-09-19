import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/vn_letter.dart';
import '../models/game_info.dart';
import '../models/learning_info.dart';
import '../widgets/learning_button.dart';
import '../widgets/game_card.dart';
import '../services/game_registry.dart';
import '../services/learning_registry.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              const SizedBox(height: 8),
              Hero(
                tag: "mascot",
                child: Image.asset("assets/images/mascot.png", height: 100),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.deepPurple,
                labelColor: Colors.deepPurple,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.menu_book), text: "Học"),
                  Tab(icon: Icon(Icons.videogame_asset), text: "Trò chơi"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRegistryList(isLearning: true),
                    _buildRegistryList(isLearning: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistryList({required bool isLearning}) {
    if (isLearning) {
      final learnings = LearningRegistry.getLearnings();
      return ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: learnings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final l = learnings[i];
          return FutureBuilder<String?>(
            future: LearningRegistry.getProgress(l),
            builder: (context, snapshot) {
              final progress = snapshot.data;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + i * 100),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: LearningButton(
                  title: l.title,
                  icon: l.icon,
                  gradient: l.gradient,
                  progress: progress,
                  onTap: () async {
                    if (l.id == "learn3") {
                      final data = await DefaultAssetBundle.of(context)
                          .loadString('assets/config/letters.json');
                      final letters = (jsonDecode(data) as List)
                          .map((e) => VnLetter.fromJson(e))
                          .toList();

                      Navigator.pushNamed(
                        context,
                        l.route,
                        arguments: {
                          "letters": letters,
                          "startIndex": 0,
                        },
                      ).then((_) => setState(() {}));
                    } else {
                      Navigator.pushNamed(context, l.route)
                          .then((_) => setState(() {}));
                    }
                  },
                ),
              );
            },
          );
        },
      );
    } else {
      final games = GameRegistry.getGames();
      return GridView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: games.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, i) {
          final g = games[i];
          return FutureBuilder<String?>(
            future: GameRegistry.getProgress(g),
            builder: (context, snapshot) {
              final progress = snapshot.data;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + i * 120),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 40 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: GameCard(
                  gameId: g.id,
                  title: g.title,
                  icon: g.icon,
                  color: g.color,
                  progress: progress,
                  onTap: () {
                    Navigator.pushNamed(context, g.route)
                        .then((_) => setState(() {}));
                  },
                ),
              );
            },
          );
        },
      );
    }
  }
}
