import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/capture_mrz_one.dart';
import 'package:togoom/features/splash/presentation/capture_recto_piece.dart';
import 'package:togoom/features/splash/presentation/cryptographe_one.dart';
import 'package:togoom/features/splash/presentation/eye_capture.dart';
import 'package:togoom/features/splash/presentation/face_capture.dart';
import 'package:togoom/features/splash/presentation/footprints_capture.dart';
import 'package:togoom/features/splash/presentation/footprints_capture_two.dart';
import 'package:togoom/features/splash/presentation/icao_screen.dart';
import 'package:togoom/features/splash/presentation/setting_page.dart';
import 'package:togoom/features/verification/language_service.dart';

class StartPage extends StatelessWidget {
  StartPage({super.key});
  final lang = LanguageService();

  final List<_FeatureItem> _features = const [
    _FeatureItem(
      title: "Traitement des documents d'identité",
      icon: "assets/icons/svg/google-doc.svg",
      isPrimary: true,
    ),
    _FeatureItem(
      title: "Traitement MRZ et NFC",
      icon: "assets/icons/svg/smartphone-wifi.svg",
    ),
    _FeatureItem(
      title: "Vérification faciale",
      icon: "assets/icons/svg/face-id.svg",
    ),
    _FeatureItem(
      title: "Vérification des empreintes",
      icon: "assets/icons/svg/fingerprint-scan.svg",
    ),
    _FeatureItem(
      title: "Créer un cryptographe",
      icon: "assets/icons/svg/blockchain-04.svg",
    ),
    _FeatureItem(
      title: "Vérification liveness",
      icon: "assets/icons/svg/eye.svg",
    ),
    _FeatureItem(
      title: "Passive liveness",
      icon: "assets/icons/svg/activity-03.svg",
    ),
    _FeatureItem(
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
              "Cas d'utilisations activés",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return GestureDetector(
                    onTap: () async {
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
                    child: FeatureTile(
                      title: feature.title,
                      iconPath: feature.icon,
                      isPrimary: feature.isPrimary,
                    ),
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

class FeatureTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final bool isPrimary;

  const FeatureTile({
    super.key,
    required this.title,
    required this.iconPath,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.secondary : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            color: isPrimary ? Colors.white : AppColors.secondary,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isPrimary ? Colors.white : AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String icon;
  final bool isPrimary;

  const _FeatureItem({
    required this.title,
    required this.icon,
    this.isPrimary = false,
  });
}
