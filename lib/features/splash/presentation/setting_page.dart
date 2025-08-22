import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/use_case.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  final List<_SettingItem> _settings = const [
    _SettingItem(
      title: "Cas d’utilisations activés/désactivé",
      icon: "assets/icons/svg/customize.svg",
    ),
    _SettingItem(
      title: "Termes & conditions",
      icon: "assets/icons/svg/file-01.svg",
    ),
    _SettingItem(
      title: "Partager",
      icon: "assets/icons/svg/share-08.svg",
    ),
    _SettingItem(
      title: "A propos de TOGOOM",
      icon: "assets/icons/svg/alert-circle.svg",
    ),
    _SettingItem(
      title: "Changer la langue",
      icon: "assets/icons/svg/language-skill.svg",
    ),
    _SettingItem(
      title: "Nous contacter",
      icon: "assets/icons/svg/contact-02.svg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 90,
        centerTitle: true,
        title: const Text(
          'Paramètres',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _settings.length,
                itemBuilder: (context, index) {
                  final setting = _settings[index];
                  return GestureDetector(
                    onTap: () {
                      if (setting.title == "Cas d’utilisations activés/désactivé") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UseCasePage(),
                          ),
                        );
                      }
                    },
                    child: FeatureTile(
                      title: setting.title,
                      iconPath: setting.icon,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Langue: Français\nVersion 1.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
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

class _SettingItem {
  final String title;
  final String icon;
  final bool isPrimary;

  const _SettingItem({
    required this.title,
    required this.icon,
    this.isPrimary = false,
    fontWeight = FontWeight.bold,
  });
}