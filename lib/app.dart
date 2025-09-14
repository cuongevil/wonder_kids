import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';

class WonderKidsApp extends StatelessWidget {
  const WonderKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wonder Kids',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.start,
      routes: AppRoutes.map(),
    );
  }
}
