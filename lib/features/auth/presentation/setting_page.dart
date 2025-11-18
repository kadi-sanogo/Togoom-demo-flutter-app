
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/auth/presentation/use_case.dart';
import 'package:togoom/features/auth/presentation/language_page.dart';
import 'package:togoom/shared/services/language_service.dart';
import 'package:togoom/features/auth/presentation/widgets/feature_tile.dart';

class SettingsPage extends StatefulWidget {
   SettingsPage({super.key});
  final lang = LanguageService();

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LanguageService lang = LanguageService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: lang,
      builder: (context, child) {
        final List<_SettingItem> settings = [
          _SettingItem(
            title: lang.t('use_cases'),
            icon: "assets/icons/svg/customize.svg",
            key: 'use_cases',
          ),
          _SettingItem(
            title: lang.t('terms'),
            icon: "assets/icons/svg/file-01.svg",
            key: 'terms',
          ),
          _SettingItem(
            title: lang.t('share'),
            icon: "assets/icons/svg/share-08.svg",
            key: 'share',
          ),
          _SettingItem(
            title: lang.t('about'),
            icon: "assets/icons/svg/alert-circle.svg",
            key: 'about',
          ),
          _SettingItem(
            title: lang.t('change_language'),
            icon: "assets/icons/svg/language-skill.svg",
            key: 'change_language',
          ),
          _SettingItem(
            title: lang.t('contact_us'),
            icon: "assets/icons/svg/contact-02.svg",
            key: 'contact_us',
          ),
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            toolbarHeight: 90,
            centerTitle: true,
            title: Text(
              lang.t('settings'),
              style: const TextStyle(
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
                    itemCount: settings.length,
                    itemBuilder: (context, index) {
                      final setting = settings[index];
                      return FeatureTile(
                        title: setting.title,
                        iconPath: setting.icon,
                        onTap: () async {
                          if (setting.key == 'use_cases') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UseCasePage(),
                              ),
                            );
                          } else if (setting.key == 'change_language') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>  LanguagePage(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${lang.t('language_label')}: ${lang.getLanguageName()}\n${lang.t('version')} 1.0',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingItem {
  final String title;
  final String icon;
  final String key;
  final bool isPrimary;

  const _SettingItem({
    required this.title,
    required this.icon,
    required this.key,
    this.isPrimary = false,
  });
}