import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:togoom/features/auth/presentation/start_page.dart';
import 'package:togoom/shared/services/language_service.dart';
import 'dart:async';
import 'package:togoom/features/auth/presentation/home_page.dart';

class SplashScreen extends StatefulWidget {
   SplashScreen({super.key});
  final lang = LanguageService();

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late GifController _controller;

  @override
  void initState() {
    super.initState();

    _controller = GifController(vsync: this);
    _controller.addStatusListener((status) {
      if (status.isCompleted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Gif(
          image: AssetImage("assets/img_gif/TOGOOM-1.gif"),
          controller:
              _controller,
          duration: const Duration(seconds: 5),
          autostart: Autostart.no,
          onFetchCompleted: () {
            _controller.reset();
            _controller.forward();
          },
        ),
      ),
    );
  }
}
