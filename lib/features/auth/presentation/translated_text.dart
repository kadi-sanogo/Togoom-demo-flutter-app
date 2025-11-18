import 'package:flutter/material.dart';
import 'package:togoom/shared/services/language_service.dart';

class TText extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

   TText(
    this.translationKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });
final lang = LanguageService();
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, child) {
        return Text(
          LanguageService().t(translationKey),
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

mixin TranslationMixin<T extends StatefulWidget> on State<T> {
  final lang = LanguageService();
  
  String tr(String key) => lang.t(key);
  
  @override
  void initState() {
    super.initState();
    lang.addListener(_onLanguageChanged);
  }
  
  @override
  void dispose() {
    lang.removeListener(_onLanguageChanged);
    super.dispose();
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}

extension TranslationHelper on String {
  String get tr => LanguageService().t(this);
}