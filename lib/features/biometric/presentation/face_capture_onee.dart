import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/biometric/presentation/face_capture_two.dart';
import 'package:togoom/features/verification/presentation/face_verify.dart';

class FaceCaptureScreenOne extends StatefulWidget {
  final String rectoImagePath;
  final String extractedPortraitBase64;

  const FaceCaptureScreenOne({
    super.key,
    required this.rectoImagePath,
    required this.extractedPortraitBase64,
  });

  @override
  State<FaceCaptureScreenOne> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreenOne> {
  String? _capturedImagePath;

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
    if (_capturedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez d'abord prendre une photo")),
      );
      return;
    }

   try {
  final Uint8List faceBytes = base64Decode(widget.extractedPortraitBase64);

  if (!mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VerificationSuccessPage(
        selfieImagePath: widget.rectoImagePath, 
        extractedPortraitBase64: widget.extractedPortraitBase64, 
        extractedPortraitPath: null, 
      ),
    ),
  );
}
    catch (e) {
      debugPrint("Erreur décodage photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de charger la photo d'identité")),
        );
      }
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
                          border: Border.all(color: Colors.green, width: 3),
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
                                  child: const Icon(Icons.camera, size: 45, color: Colors.black),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
