import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:togoom/features/verification/presentation/IDVerificationScreen.dart';
import 'package:togoom/features/biometric/presentation/eye_capture.dart';
import 'package:togoom/features/biometric/presentation/iris_capture.dart';
import 'package:togoom/features/biometric/presentation/smile_capture.dart';
import 'package:togoom/features/verification/language_service.dart';
import 'package:togoom/features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );
  await LanguageService().loadLanguage();
  
  runApp(TogoomApp()); 
}

class TogoomApp extends StatelessWidget {
  TogoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, child) {
        final lang = LanguageService();
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Togoom',
          
          locale: lang.currentLocale,
          supportedLocales: lang.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
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
          
          home: SplashScreen(), 
        );
      },
    );
  }
}



/*import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:togoom/features/verification/presentation/check_liveliness_one.dart';
import 'package:togoom/features/biometric/presentation/face_capture.dart' show FaceCaptureCamera;
import 'package:togoom/features/document/presentation/scan_doc_verso.dart';
import 'package:togoom/features/verification/language_service.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  // Initialisation nécessaire pour les plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger la langue sauvegardée
  await LanguageService().loadLanguage();
  
  runApp(const TogoomApp());
}

class TogoomApp extends StatelessWidget {
  const TogoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder écoute les changements de langue
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, child) {
        final lang = LanguageService();
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Togoom',
          
          // Configuration de la localisation
          locale: lang.currentLocale,
          supportedLocales: lang.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
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
          
          home:  SplashScreen(),
          //home: FaceCaptureCamera(onFaceCaptured: (String) {}),
        );
      },
    );
  }
}*/