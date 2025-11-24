import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/biometric/presentation/footprints_capture_two.dart';
import 'package:togoom/shared/services/language_service.dart';

class CaptureFootprints extends StatefulWidget {
  const CaptureFootprints({super.key});

  @override
  State<CaptureFootprints> createState() => _CaptureFootprintsState();
}

class _CaptureFootprintsState extends State<CaptureFootprints> {
  bool _dontShowAgain = false;
  final lang = LanguageService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Capture d\'empreintes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Icon(
                Icons.fingerprint,
                size: 80,
                color: AppColors.primary,
              ),

              const SizedBox(height: 24),

              const Text(
                'Capture de vos empreintes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Suivez les instructions ci-dessous',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildInstructionItem(
                      iconAsset: 'assets/icons/svg/four-finger-02.svg',
                      text: 'Étendez et gardez les doigts ensemble',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      iconAsset: 'assets/icons/svg/camera-ai.svg',
                      text: 'Placez vos doigts devant la caméra',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      iconAsset: 'assets/icons/svg/2nd-bracket.svg',
                      text: "Restez immobile à l'intérieur du rectangle",
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      iconAsset: 'assets/icons/svg/loading-02.svg',
                      text: "Attendez la capture automatique",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _dontShowAgain = !_dontShowAgain;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _dontShowAgain ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: _dontShowAgain ? AppColors.primary : Colors.grey[400]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _dontShowAgain
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ne plus afficher cette page',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FootprintsCaptureTwo(),
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Vos données sont sécurisées',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
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
