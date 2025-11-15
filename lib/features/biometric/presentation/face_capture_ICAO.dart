import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/biometric/presentation/face_capture.dart';
import 'package:togoom/features/biometric/presentation/footprints_capture_two.dart';
import 'package:togoom/features/verification/language_service.dart';

class FaceCaptureIcao extends StatefulWidget {
  const FaceCaptureIcao({super.key});

  @override
  State<FaceCaptureIcao> createState() => _FaceCaptureIcaoState();
}

class _FaceCaptureIcaoState extends State<FaceCaptureIcao> {
  bool _dontShowAgain = false;
  final lang = LanguageService();
  @override
  Widget build(BuildContext context) {
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
              'Capture photo ICAO',
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
            const SizedBox(height: 10),

            const Text(
              'Capture de votre visage',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Container(
              width: 406,
              height: 268,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInstructionItem(
                    iconAsset: 'assets/icons/svg/four-finger-02.svg',
                    text: 'Vous ne portez pas de chapeau',
                  ),

                  const SizedBox(height: 20),

                  _buildInstructionItem(
                    iconAsset: 'assets/icons/svg/glasses.svg',
                    text: 'Vous ne portez pas de lunettes de soleil.',
                  ),

                  const SizedBox(height: 20),

                  _buildInstructionItem(
                    iconAsset: 'assets/icons/svg/sun-03.svg',
                    text: "Vous êtes dans une lumière vive",
                  ),

                  const SizedBox(height: 20),

                  _buildInstructionItem(
                    iconAsset: 'assets/icons/svg/happy-01.svg',
                    text:
                        "Vous regardez directement l'objectif de la caméra du téléphone.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Ne me le montrez plus',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _dontShowAgain = !_dontShowAgain;
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _dontShowAgain ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: _dontShowAgain ? AppColors.primary : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: _dontShowAgain
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bouton
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FaceCaptureCamera(
                        onFaceCaptured: (String imagePath) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FootprintsCaptureTwo(),
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
                  'Commencer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Vos données sont sécurisées et ne seront utilisées que pour la vérification d\'identité.',
              style: TextStyle(fontSize: 12, color: Colors.black),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required String iconAsset,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(iconAsset, width: 24, height: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
