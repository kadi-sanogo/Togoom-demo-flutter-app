import 'package:flutter/material.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'dart:io';

import 'package:togoom/features/splash/presentation/check_liveliness_one.dart';
import 'package:togoom/features/splash/presentation/check_liveliness_three.dart';
import 'package:togoom/features/splash/presentation/check_liveliness_two.dart';
import 'package:togoom/features/splash/presentation/face_capture_two.dart';

class ScanPage extends StatelessWidget {
  final String? rectoImagePath;
  final String? versoImagePath;

  const ScanPage({super.key, this.rectoImagePath, this.versoImagePath});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 100,
        centerTitle: true,
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TOGGOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Traitement des documents d'identité",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: const [
                  Text(
                    "Vérification des captures",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Étape 3 sur 3",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DocumentSection(
                      title: "Recto du document",
                      imagePath: rectoImagePath,
                      isRecto: true,
                      onRetake: () => Navigator.pop(context),
                      width: screenWidth * 0.85,
                      height: screenHeight * 0.25,
                    ),
                    _DocumentSection(
                      title: "Verso du document",
                      imagePath: versoImagePath,
                      isRecto: false,
                      onRetake: () => Navigator.pop(context),
                      width: screenWidth * 0.85,
                      height: screenHeight * 0.25,
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(

                   onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FaceCaptureTwoScreen(
                        onFaceCaptured: (facePath) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LivenessPageThree(
                                faceImagePath: facePath,
                                versoImagePath: "chemin_vers_verso",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Continuer vers la vérification",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  final String title;
  final String? imagePath;
  final bool isRecto;
  final VoidCallback onRetake;
  final double width;
  final double height;

  const _DocumentSection({
    required this.title,
    this.imagePath,
    required this.isRecto,
    required this.onRetake,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              width: 120,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                onTap: onRetake,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.refresh, size: 18, color: Colors.black),
                    SizedBox(width: 4),
                    Text(
                      "Reprendre",
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImageContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (imagePath == null) {
      return _buildPlaceholder();
    }

    if (imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 36, color: Colors.grey[400]),
          const SizedBox(height: 4),
          Text(
            isRecto ? "Photo du recto" : "Photo du verso",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
