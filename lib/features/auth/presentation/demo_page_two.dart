import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/shared/services/language_service.dart';

class DemoPageNFC extends StatefulWidget {
  const DemoPageNFC({super.key});

  @override
  State<DemoPageNFC> createState() => _DemoPageNFCState();
}

class _DemoPageNFCState extends State<DemoPageNFC> {
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
              'Démo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.2,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre principal
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Traitement MRZ et NFC",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/icons/svg/google-doc.svg',
                  width: 24,
                  height: 24,
                ),
              ],
            ),

            const SizedBox(height: 5),
            const Text(
              "Suivez les étapes ci-dessous pour une vérification réussie :",
              style: TextStyle(fontSize: 14, color: Colors.black),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/shared-wifi.svg',
              text: "Scannez le document NFC",
              bottomText:
                  "Placez votre pièce contre l’arrière de votre téléphone et attendez la lecture.",
            ),
            const SizedBox(height: 16),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/face-id.svg',
              text: "Prenez un selfie",
              bottomText:
                  "Positionnez votre visage dans le cercle. Vos yeux, nez et bouche doivent être visibles.",
            ),
            const SizedBox(height: 16),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/cardiogram-02.svg',
              text: "Vérification de vivacité",
              bottomText:
                  "Restez immobile. Ne portez ni masque, ni lunettes noires.",
            ),
            const SizedBox(height: 24),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/iris-scan.svg',
              text: "Scannez votre document NFC",
              bottomText: "Placez votre document dans le rectangle.",
            ),
            const SizedBox(height: 20),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/shared-wifi.svg',
              text: 'Lancez la numrisation sans fil',
              bottomText:
                  "Placez votre document contre votre téléphone et attendez le progrès",
            ),
            const SizedBox(height: 20),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/face-id.svg',
              text:
                  "Nettoyez l'objectif de l'appareil photo avec un chiffon sec. ",
              bottomText: "Positionnez votre visage dans le cercle.",
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/capture-recto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Commencer la vérification",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required String iconAsset,
    required String text,
    String? bottomText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(iconAsset, width: 20, height: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (bottomText != null && bottomText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 6),
            child: Text(
              bottomText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}
