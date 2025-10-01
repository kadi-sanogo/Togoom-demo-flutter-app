import 'package:flutter/material.dart';
import 'package:togoom/features/splash/presentation/check_liveliness_one.dart';
import 'package:togoom/features/splash/presentation/face_capture.dart' show FaceCaptureCamera;
import 'package:togoom/features/splash/presentation/scan_doc_verso.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() {
  runApp(const TogoomApp());
}

class TogoomApp extends StatelessWidget {
  const TogoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Togoom',
      theme: ThemeData(
        fontFamily: 'SFPro', 
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(),
          bodyMedium: TextStyle(),
          displayLarge: TextStyle(),
          displayMedium: TextStyle(),
          titleMedium: TextStyle(),
          titleSmall: TextStyle(),
          labelLarge: TextStyle(),
        ),
      ),
      home: const SplashScreen(),
      //home : FaceCaptureCamera(onFaceCaptured: (String ) {  },)
    );
  }
}
