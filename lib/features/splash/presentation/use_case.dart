import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';

class UseCasePage extends StatefulWidget {
  const UseCasePage({super.key});

  @override
  State<UseCasePage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<UseCasePage> {
  bool documentIdentityProcessing = true;
  bool createCryptographer = true;
  bool mrzNfcProcessing = true;
  bool faceVerification = true;

  bool palmVerification = false;
  bool strictIcaoControl = false;
  bool magnifeyeLiveness = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 90,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Paramètres',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              "Cas d'utilisations actives",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Cas d'utilisations actives",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.lock_open,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              UseCaseTile(
                title: "Traitement des documents d'identité",
                iconPath: "assets/icons/svg/google-doc.svg",
                isActive: documentIdentityProcessing,
                onChanged: (value) {
                  setState(() {
                    documentIdentityProcessing = value;
                  });
                },
                  switchScale: 1,
              ),
              UseCaseTile(
                title: "Créer un cryptographe",
                iconPath: "assets/icons/svg/blockchain-04.svg",
                isActive: createCryptographer,
                onChanged: (value) {
                  setState(() {
                    createCryptographer = value;
                  });
                },
                  switchScale: 1,
              ),
              UseCaseTile(
                title: "Traitement MRZ et NFC",
                iconPath: "assets/icons/svg/smartphone-wifi.svg",
                isActive: mrzNfcProcessing,
                onChanged: (value) {
                  setState(() {
                    mrzNfcProcessing = value;
                  });
                },
                  switchScale: 1,
              ),
              UseCaseTile(
                title: "Vérification faciale",
                iconPath: "assets/icons/svg/face-id.svg",
                isActive: faceVerification,
                onChanged: (value) {
                  setState(() {
                    faceVerification = value;
                  });
                },
                 switchScale: 1,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Text(
                    "Cas d'utilisations désactives",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.lock,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              UseCaseTile(
                title: "Vérification de la paume",
                iconPath: "assets/icons/svg/fingerprint-scan.svg",
                isActive: palmVerification,
                onChanged: (value) {
                  setState(() {
                    palmVerification = value;
                  });
                },
                  switchScale: 1,
              ),
              UseCaseTile(
                title: "Contrôle ICAO strict",
                iconPath: "assets/icons/svg/security-password-02.svg",
                isActive: strictIcaoControl,
                onChanged: (value) {
                  setState(() {
                    strictIcaoControl = value;
                  });
                },
                  switchScale: 1,
              ),
              UseCaseTile(
                title: "MagnifEye liveness",
                iconPath: "assets/icons/svg/eye.svg",
                isActive: magnifeyeLiveness,
                onChanged: (value) {
                  setState(() {
                    magnifeyeLiveness = value;
                  });
                },
                  switchScale: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}class UseCaseTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final double switchScale;
  const UseCaseTile({
    super.key,
    required this.title,
    required this.iconPath,
    required this.isActive,
    required this.onChanged,
    this.switchScale = 1.2, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            color: AppColors.secondary,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          Transform.scale(
            scale: switchScale,  
            child: Switch(
              value: isActive,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.secondary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
