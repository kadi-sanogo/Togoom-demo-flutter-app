import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/capture_mrz_one.dart';
import 'package:togoom/features/document/presentation/capture_recto_piece.dart';
import 'package:togoom/features/verification/presentation/cryptographe_one.dart';
import 'package:togoom/features/biometric/presentation/eye_capture.dart';
import 'package:togoom/features/biometric/presentation/face_capture.dart';
import 'package:togoom/features/biometric/presentation/footprints_capture_two.dart';
import 'package:togoom/features/biometric/presentation/icao_screen.dart';
import 'package:togoom/features/auth/presentation/setting_page.dart';
import 'package:togoom/shared/services/language_service.dart';
import 'package:togoom/features/auth/domain/feature_item.dart';
import 'package:togoom/features/auth/presentation/widgets/feature_tile.dart';

class StartPage extends StatelessWidget {
  StartPage({super.key});
  final lang = LanguageService();

  final List<FeatureItem> _features = const [
    FeatureItem(
      title: "Traitement des documents d'identité",
      icon: "assets/icons/svg/google-doc.svg",
    ),
    FeatureItem(
      title: "Traitement MRZ et NFC",
      icon: "assets/icons/svg/smartphone-wifi.svg",
    ),
    FeatureItem(
      title: "Vérification faciale",
      icon: "assets/icons/svg/face-id.svg",
    ),
    FeatureItem(
      title: "Vérification des empreintes",
      icon: "assets/icons/svg/fingerprint-scan.svg",
    ),
    FeatureItem(
      title: "Créer un cryptographe",
      icon: "assets/icons/svg/blockchain-04.svg",
    ),
    FeatureItem(
      title: "Vérification liveness",
      icon: "assets/icons/svg/eye.svg",
    ),
    FeatureItem(
      title: "Passive liveness",
      icon: "assets/icons/svg/activity-03.svg",
    ),
    FeatureItem(
      title: "Photo normes ICAO",
      icon: "assets/icons/svg/security-password-02.svg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 90,
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            "assets/images/logos/togoom-logo 1(1).png",
            width: 46,
            height: 44,
          ),
          onPressed: () {},
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "TOGOOM",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              "Outils d'intégration",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              "assets/icons/svg/settings-02.svg",
              color: AppColors.secondary,
              height: 28,
              width: 28,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cas d'utilisations ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return FeatureTile(
                    title: feature.title,
                    iconPath: feature.icon,
                    isPrimary: feature.isPrimary,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      if (feature.title ==
                          "Traitement des documents d'identité") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaptureRectoPage(),
                          ),
                        );
                      } else if (feature.title == "Traitement MRZ et NFC") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaptureMrzOne(),
                          ),
                        );
                      } else if (feature.title == "Créer un cryptographe") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CryptoPage(),
                          ),
                        );
                      } else if (feature.title == "Vérification faciale") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FaceCaptureCamera(
                              onFaceCaptured: (String imagePath) {
                                print('Photo capturée : $imagePath');
                              },
                            ),
                          ),
                        );
                      } else if (feature.title ==
                          "Vérification des empreintes") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FootprintsCaptureTwo(),
                          ),
                        );
                      } else if (feature.title == "Vérification liveness") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EyeVerificationScreen(),
                          ),
                        );
                      } else if (feature.title == "Photo normes ICAO") {
                        final status = await Permission.camera.request();
                        if (!status.isGranted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Permission caméra requise'),
                            ),
                          );
                          return;
                        }

                        try {
                          final cameras = await availableCameras();
                          final frontCamera = cameras.firstWhere(
                            (camera) =>
                                camera.lensDirection ==
                                CameraLensDirection.front,
                            orElse: () => cameras.first,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  IcaoScreen(camera: frontCamera),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur caméra : $e')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

