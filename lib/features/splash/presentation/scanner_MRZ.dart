import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/scanner_MRZ_two.dart';

class ScannerMrz extends StatelessWidget {
  const ScannerMrz({super.key});

  Future<void> _openCamera(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScannerMrzTwo(imageFile: File(image.path)),
        ),
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
      body: Column(
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
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // 👉 Cadre de prévisualisation
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!, width: 12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                     child: Stack(
                      children: [
                        ..._buildCorners(),
                        Center(
                          child: SvgPicture.asset(
                            "assets/icons/svg/camera-01.svg",
                            width: 45,
                            height: 45,
                          ),
                        ),
                      ],
                    )
                  ),

                  const SizedBox(height: 25),

                  // 👉 Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("1. Positionnez votre document dans le cadre",
                            style: TextStyle(fontSize: 14)),
                        SizedBox(height: 6),
                        Text("2. Assurez-vous que la zone MRZ est bien visible",
                            style: TextStyle(fontSize: 14)),
                        SizedBox(height: 6),
                        Text("3. Évitez les reflets et ombres",
                            style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 👉 Bouton
                  SizedBox(
                    width: 406,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _openCamera(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Commencer le scanne",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    return [
      Positioned(
        child: Container(
          width: 100,
          height: 50,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 3),
              left: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: 100,
          height: 50,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 3),
              right: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: 100,
          height: 50,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.primary, width: 3),
              left: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: 100,
          height: 50,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.primary, width: 3),
              right: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
    ];
  }
}
