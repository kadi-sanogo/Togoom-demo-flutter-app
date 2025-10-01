import 'package:flutter/material.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'dart:io';

import 'package:togoom/features/splash/presentation/check_liveliness_one.dart';
import 'package:togoom/features/splash/presentation/check_liveliness_two.dart';

class ScanPage extends StatelessWidget {
  final String? rectoImagePath;
  final String? versoImagePath;

  const ScanPage({super.key, this.rectoImagePath, this.versoImagePath});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Vérification des captures",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Étape 3 sur 3",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            const SizedBox(height: 10),

            _DocumentSection(
              title: "Recto du document",
              imagePath: rectoImagePath,
              isRecto: true,
              onRetake: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 10),

            _DocumentSection(
              title: "Verso du document",
              imagePath: versoImagePath,
              isRecto: false,
              onRetake: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 25),

            Container(
              width: 406,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LivenessPageTwo(),
                    ),
                  );
                  print("Recto: $rectoImagePath");
                  print("Verso: $versoImagePath");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Continuer vers la vérification",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
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

  const _DocumentSection({
    required this.title,
    this.imagePath,
    required this.isRecto,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200], 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
                width: 147,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GestureDetector(
                  onTap: onRetake,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 20, color: Colors.black),
                      const SizedBox(width: 4),
                      const Text(
                        "Reprendre",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: 382,
            height: 242,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageContent(),
            ),
          ),

        
        ],
      ),
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
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          isRecto ? "Photo du recto" : "Photo du verso",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// Exemple de navigation vers cette page depuis vos pages de capture :
/*
// Depuis votre page de capture du recto :
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ScanPage(
      rectoImagePath: capturedRectoPath, // Le chemin de l'image capturée
      versoImagePath: null, // Pas encore capturé
    ),
  ),
);

// Depuis votre page de capture du verso :
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => ScanPage(
      rectoImagePath: rectoPath, // Passé depuis la page précédente
      versoImagePath: capturedVersoPath, // Le chemin de l'image capturée
    ),
  ),
);
*/
