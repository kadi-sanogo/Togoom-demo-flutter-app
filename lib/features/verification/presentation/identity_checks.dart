import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/scan_doc.dart';
import 'package:togoom/features/document/presentation/scan_doc_recto.dart';
import 'package:togoom/shared/services/language_service.dart';

class IdentityVerificationPage extends StatelessWidget {
  IdentityVerificationPage({super.key});
  final lang = LanguageService();

  final List<_DocumentType> _acceptedDocuments = const [
    _DocumentType(
      title: "Carte d'Identité",
      icon: "assets/icons/svg/identity-card.svg",
    ),
    _DocumentType(title: "Passeport", icon: "assets/icons/svg/passport-01.svg"),
    _DocumentType(
      title: "Permis de conduire",
      icon: "assets/icons/svg/car-04.svg",
    ),
    _DocumentType(
      title: "Carte de résidence",
      icon: "assets/icons/svg/student-card.svg",
    ),
  ];

  final List<String> _instructions = const [
    "Munissez-vous de votre document d'identité",
    "Trouvez un endroit bien éclairé",
    "Assurez-vous que votre caméra fonctionne",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 80,
        centerTitle: true,
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TOGGOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Traitement des documents d'identité",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Vérification d'identité",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Pour sécuriser votre compte et respecter la réglementation, nous devons vérifier votre identité.",
              style: TextStyle(fontSize: 14, color: Colors.black, height: 1.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Documents acceptés",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._acceptedDocuments.map(
                    (doc) => _DocumentTile(title: doc.title, icon: doc.icon),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Temps estimé : 2 minutes",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._instructions.map(
                    (instruction) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              instruction,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: 406,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomCameraScreen(
                        documentType: "recto",
                        onImageCaptured: (String imagePath) {
                          print("Recto capturé : $imagePath");

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScanPage(
                                rectoImagePath: imagePath,
                                versoImagePath: null,
                              ),
                            ),
                          );
                        },
                        requiresVerso: false,
                      ),
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
                  "Commencer la vérification",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Vos données sont sécurisées et ne seront utilisées que pour la vérification.",
              style: TextStyle(fontSize: 12, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final String icon;

  const _DocumentTile({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, width: 20, height: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentType {
  final String title;
  final String icon;
  const _DocumentType({required this.title, required this.icon});
}
