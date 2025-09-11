import 'package:flutter/material.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bé học chữ cái',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.pinkAccent,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const StartScreen(),
    );
  }
}
