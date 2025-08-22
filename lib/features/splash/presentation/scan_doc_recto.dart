import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/camera_scan.dart';

class ScanDocRecto extends StatelessWidget {
  const ScanDocRecto({super.key});

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
          padding: const EdgeInsets.only(
            top: 25,
          ),
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
            "Recto du document",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Étape 1 sur 3",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 1 / 3, 
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Zone de capture
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
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
                    ),
                  ),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: 406,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200]!,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Positionnez votre document dans le cadre",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: 406,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraScanScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Démarrer la capture automatique",
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