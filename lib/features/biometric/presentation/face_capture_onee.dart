import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/biometric/presentation/face_capture_two.dart';
import 'package:togoom/features/verification/presentation/face_verify.dart';
import 'package:togoom/shared/services/language_service.dart';

class FaceCaptureScreenOne extends StatefulWidget {
  const FaceCaptureScreenOne({super.key});

  @override
  State<FaceCaptureScreenOne> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreenOne> {
  String? _capturedImagePath;
final lang = LanguageService();
  void _openFaceCaptureTwoScreen() async {
    final capturedPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceCaptureTwoScreen(
          onFaceCaptured: (path) {
            Navigator.pop(context, path); 
          },
        ),
      ),
    );

    if (capturedPath != null) {
      setState(() {
        _capturedImagePath = capturedPath;
      });
    }
  }

  void _validatePhoto() async {
    if (_capturedImagePath != null) {
      final faceBytes = await File(_capturedImagePath!).readAsBytes();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VerificationSuccessPage(
              faceImage: faceBytes, imagePath: _capturedImagePath!, 
            ),
          ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez d'abord prendre une photo")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 100,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'TOGGOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Créer un cryptographe",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Approchez votre visage de la caméra',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: _openFaceCaptureTwoScreen,
              child: Container(
                width: 406,
                height: 413,
                color: Colors.grey[300],
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green,
                            width: 3,
                          ),
                          color: Colors.grey[100],
                        ),
                        child: _capturedImagePath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_capturedImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: InkWell(
                                  onTap: _openFaceCaptureTwoScreen,
                                  child: const Image(
                                    image: AssetImage(
                                        "assets/icons/svg/camera-01.png"),
                                    width: 45,
                                    height: 45,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Vérifié',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _validatePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Valider',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


