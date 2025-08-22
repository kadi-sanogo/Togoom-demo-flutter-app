import 'package:flutter/material.dart';
import 'package:togoom/features/splash/presentation/splash_screen.dart';

class TogoomApp extends StatelessWidget {
  const TogoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOGOOM Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
