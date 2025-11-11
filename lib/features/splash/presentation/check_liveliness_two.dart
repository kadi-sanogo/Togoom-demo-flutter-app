import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/check_liveliness_three.dart';
import 'package:togoom/features/splash/presentation/face_capture_two.dart';
import 'package:togoom/features/verification/language_service.dart';

class LivenessPageTwo extends StatefulWidget {
  final String? rectoImagePath;

  const LivenessPageTwo({super.key, this.rectoImagePath});

  @override
  State<LivenessPageTwo> createState() => _LivenessCapturePageState();
}

class _LivenessCapturePageState extends State<LivenessPageTwo> {
  bool isVerified = false;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 120,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'TOGOOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Traitement des documents d\'identité',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
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
            const Text(
              'Vérification en cours',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            const Text(
              'Gardez votre visage dans l\'ovale',
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 406,
                      height: 453,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Container(
                          width: 250,
                          height: 348,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(128),
                            border: Border.all(color: Colors.black, width: 3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(128),
                            child: widget.rectoImagePath != null
                                ? Image.file(
                                    File(widget.rectoImagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: SvgPicture.asset(
                                      'assets/icons/svg/camera-01.svg',
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Vérifier',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 406,
              height: 130,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/svg/clock-01.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Instructions simples',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _BulletItem(
                          text:
                              "Cadrez votre visage dans l'ovale qui apparaîtra",
                        ),
                        _BulletItem(
                          text: "Restez immobile pendant quelques secondes",
                        ),
                        _BulletItem(
                          text:
                              "Le système détectera automatiquement votre vivacité",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 406,
              height: 50,
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
                  'Capture du visage',
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

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 8, right: 8),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
