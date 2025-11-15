import 'dart:io';
import 'package:flutter/material.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/scanner_MRZ_final.dart';
import 'package:togoom/features/verification/language_service.dart';

class ScannerMrzTwo extends StatelessWidget {
  final File imageFile;
  final lang = LanguageService();

  ScannerMrzTwo({super.key, required this.imageFile});

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
        leading: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              "Scanner MRZ",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Positionnez la zone MRZ dans le cadre",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: imageFile != null
                    ? Image.file(imageFile, fit: BoxFit.contain)
                    : Container(
                        width: 250,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Détection MRZ...",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1. Placer le document sur une surface plane",
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "2. Assurez-vous que la zone MRZ est bien visible",
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "3. Évitez les reflets et ombres",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: 406,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Future.delayed(const Duration(seconds: 5), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScannerMrzFinal(),
                      ),
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9091AB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Scanne en cours...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
