import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/identity_checks.dart';
import 'package:togoom/features/splash/presentation/setting_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  final List<_FeatureItem> _features = const [
    _FeatureItem(
      title: "Traitement des documents d'identité",
      icon: "assets/icons/svg/google-doc.svg",
      isPrimary: true,
    ),
    _FeatureItem(
      title: "Créer un cryptographe",
      icon: "assets/icons/svg/blockchain-04.svg",
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
      title: "Vérification de la paume",
      icon: "assets/icons/svg/fingerprint-scan.svg",
    ),
    _FeatureItem(
      title: "Contrôle ICAO strict",
      icon: "assets/icons/svg/security-password-02.svg",
    ),
    _FeatureItem(title: "MagnifEye liveness", icon: "assets/icons/svg/eye.svg"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 90,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: SvgPicture.asset(
            "assets/images/logos/togoom-logo 1.svg",
            height: 32,
            width: 32,
          ),
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
              "Outils d’intégration",
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
                MaterialPageRoute(builder: (context) => const SettingsPage()),
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
              "Cas d’utilisations activés",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return GestureDetector(
                    onTap: () {
                      if (feature.title == "Traitement des documents d'identité") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const IdentityVerificationPage(),
                          ),
                        );
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
          const SizedBox(width: 12),
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
