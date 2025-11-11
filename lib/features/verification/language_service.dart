import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Locale _currentLocale = const Locale('fr');
  Locale get currentLocale => _currentLocale;
  String get currentLanguage => _currentLocale.languageCode;

  // Toutes les traductions de l'application
  final Map<String, Map<String, String>> _translations = {
    // Navigation et commun
    'settings': {'fr': 'Paramètres', 'en': 'Settings'},
    'back': {'fr': 'Retour', 'en': 'Back'},
    'confirm': {'fr': 'Confirmer', 'en': 'Confirm'},
    'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
    'yes': {'fr': 'Oui', 'en': 'Yes'},
    'no': {'fr': 'Non', 'en': 'No'},
    'save': {'fr': 'Enregistrer', 'en': 'Save'},
    'delete': {'fr': 'Supprimer', 'en': 'Delete'},
    'edit': {'fr': 'Modifier', 'en': 'Edit'},
    
    // Page des paramètres
    'use_cases': {'fr': "Cas d'utilisations activés/désactivé", 'en': 'Enabled/Disabled Use Cases'},
    'terms': {'fr': 'Termes & conditions', 'en': 'Terms & Conditions'},
    'share': {'fr': 'Partager', 'en': 'Share'},
    'about': {'fr': 'A propos de TOGOOM', 'en': 'About TOGOOM'},
    'change_language': {'fr': 'Changer la langue', 'en': 'Change Language'},
    'contact_us': {'fr': 'Nous contacter', 'en': 'Contact Us'},
    'language_label': {'fr': 'Langue', 'en': 'Language'},
    'version': {'fr': 'Version', 'en': 'Version'},
    
    // Page de langue
    'select_language': {'fr': 'Sélectionnez votre langue préférée', 'en': 'Select your preferred language'},
    'language_changed_fr': {'fr': 'Langue changée en Français', 'en': 'Language changed to French'},
    'language_changed_en': {'fr': 'Langue changée en Anglais', 'en': 'Language changed to English'},
    
    // Scan de documents
    'document_processing': {'fr': "Traitement des documents d'identité", 'en': 'Identity Document Processing'},
    'document_front': {'fr': 'Recto du document', 'en': 'Front of Document'},
    'document_back': {'fr': 'Verso du document', 'en': 'Back of Document'},
    'step': {'fr': 'Étape', 'en': 'Step'},
    'of': {'fr': 'sur', 'en': 'of'},
    'scan_document': {'fr': 'Scan du document', 'en': 'Document Scan'},
    'position_document': {'fr': 'Positionnez votre document dans le cadre', 'en': 'Position your document in the frame'},
    'start_capture': {'fr': 'Démarrer la capture automatique', 'en': 'Start Automatic Capture'},
    'capture_front': {'fr': 'Capturer le recto', 'en': 'Capture Front'},
    'capture_back': {'fr': 'Capturer le verso', 'en': 'Capture Back'},
    'front_captured': {'fr': 'Recto capturé ✓', 'en': 'Front Captured ✓'},
    'back_captured': {'fr': 'Verso capturé ✓', 'en': 'Back Captured ✓'},
    'capture_front_first': {'fr': "Capturez d'abord le recto", 'en': 'Capture Front First'},
    
    // Messages et notifications
    'success': {'fr': 'Succès', 'en': 'Success'},
    'error': {'fr': 'Erreur', 'en': 'Error'},
    'loading': {'fr': 'Chargement...', 'en': 'Loading...'},
    'please_wait': {'fr': 'Veuillez patienter', 'en': 'Please wait'},
    
    // Page d'accueil / Splash
    'welcome': {'fr': 'Bienvenue', 'en': 'Welcome'},
    'get_started': {'fr': 'Commencer', 'en': 'Get Started'},
    
    // Cas d'usage
    'use_case': {'fr': "Cas d'usage", 'en': 'Use Case'},
    'enabled': {'fr': 'Activé', 'en': 'Enabled'},
    'disabled': {'fr': 'Désactivé', 'en': 'Disabled'},
    
    // Vérification d'identité
    'identity_verification': {'fr': "Vérification d'identité", 'en': 'Identity Verification'},
    'face_capture': {'fr': 'Capture du visage', 'en': 'Face Capture'},
    'liveness_check': {'fr': 'Vérification de vivacité', 'en': 'Liveness Check'},
    
    // Boutons d'action
    'next': {'fr': 'Suivant', 'en': 'Next'},
    'previous': {'fr': 'Précédent', 'en': 'Previous'},
    'finish': {'fr': 'Terminer', 'en': 'Finish'},
    'retry': {'fr': 'Réessayer', 'en': 'Retry'},
    'continue': {'fr': 'Continuer', 'en': 'Continue'},
  };

  String translate(String key) {
    return _translations[key]?[currentLanguage] ?? key;
  }

  // Raccourci pour traduire
  String t(String key) => translate(key);

  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language') ?? 'fr';
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement de la langue: $e');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != 'fr' && languageCode != 'en') return;
    
    _currentLocale = Locale(languageCode);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la langue: $e');
    }
    
    notifyListeners();
  }

  String getLanguageName() {
    return currentLanguage == 'fr' ? 'Français' : 'English';
  }

  // Support des locales Flutter
  List<Locale> get supportedLocales => const [
    Locale('fr'),
    Locale('en'),
  ];
}

// Extension pour faciliter l'utilisation dans BuildContext
extension TranslationExtension on BuildContext {
  String tr(String key) {
    return LanguageService().translate(key);
  }
  
  LanguageService get lang => LanguageService();
}