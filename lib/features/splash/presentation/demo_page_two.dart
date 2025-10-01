import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';

class DemoPageNFC extends StatefulWidget {
  const DemoPageNFC({super.key});

  @override
  State<DemoPageNFC> createState() => _DemoPageNFCState();
}

class _DemoPageNFCState extends State<DemoPageNFC> {
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
          children: [
            const SizedBox(height: 10),

            // Titre principal avec icône à droite
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
              "Les étapes pour procéder au traitement MRZ et NFC :",
              style: TextStyle(fontSize: 14, color: Colors.black),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Instructions
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/iris-scan.svg',
              text: "Scannez votre document NFC",
              bottomText: "Placez votre document dans le rectangle.",
            ),
             const SizedBox(height: 20),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/shared-wifi.svg',
              text: 'Lancez la numrisation sans fil',
              bottomText: "Placez votre document contre votre téléphone et attendez le progrès",
            ),
            const SizedBox(height: 20),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/face-id.svg',
              text: 'Prenez un selfie',
              bottomText: "Positionnez votre visage dans le cercle.",
            ),
            const SizedBox(height: 20),
            _buildInstructionItem(
              iconAsset: 'assets/icons/svg/cardiogram-02.svg',
              text: "Vérification de la vivacité",
              bottomText:
                  "Essayez nos vérifications de vivacité actives et passives.",
            ),
           
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required String iconAsset,
    required String text,
    required String bottomText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(iconAsset, width: 24, height: 24),
            const SizedBox(width: 16),
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
        if (bottomText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Text(
              bottomText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
