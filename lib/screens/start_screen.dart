import 'package:flutter/material.dart';
import '../widgets/game_card.dart';
import '../widgets/learning_button.dart';
import '../models/game_info.dart';
import '../config/app_routes.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late Future<List<GameInfo>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    _gamesFuture = _loadGames();
  }

  Future<List<GameInfo>> _loadGames() async {
    final rawGames = [
      GameInfo(
        id: "game1",
        title: "Tìm chữ",
        icon: Icons.search,
        color: Colors.pink,
        route: AppRoutes.gameFind,
      ),
      GameInfo(
        id: "game2",
        title: "Ghép hình",
        icon: Icons.image,
        color: Colors.teal,
        route: AppRoutes.gameMatch,
      ),
      GameInfo(
        id: "game3",
        title: "Điền chữ",
        icon: Icons.edit,
        color: Colors.blue,
        route: AppRoutes.gameFill,
      ),
      GameInfo(
        id: "game4",
        title: "Nghe & chọn",
        icon: Icons.volume_up,
        color: Colors.orange,
        route: AppRoutes.gameListen,
      ),
    ];

    return Future.wait(rawGames.map(GameInfo.withProgress));
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
              const SizedBox(height: 16),
              Image.asset("assets/images/mascot.png", height: 120),

              const SizedBox(height: 24),
              const Text(
                "📚 Học",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),

              LearningButton(
                title: "Học theo thứ tự",
                icon: Icons.sort_by_alpha,
                gradient: [Colors.orange, Colors.yellow],
                onTap: () => Navigator.pushNamed(context, AppRoutes.home),
              ),
              const SizedBox(height: 16),
              LearningButton(
                title: "Flashcard",
                icon: Icons.style,
                gradient: [Colors.blue, Colors.purple],
                onTap: () => Navigator.pushNamed(context, AppRoutes.flashcard),
              ),

              const SizedBox(height: 28),
              const Text(
                "🎮 Trò chơi",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: FutureBuilder<List<GameInfo>>(
                  future: _gamesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final games = snapshot.data!;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: games.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, i) {
                        final g = games[i];
                        return GameCard(
                          gameId: g.id,
                          title: g.title,
                          icon: g.icon,
                          color: g.color,
                          score: g.score,
                          round: g.round,
                          onTap: () async {
                            await Navigator.pushNamed(context, g.route);
                            setState(() {
                              _gamesFuture = _loadGames(); // 🔄 reload khi back
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
