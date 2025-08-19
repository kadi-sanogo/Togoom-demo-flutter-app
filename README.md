# TOGOOM Mobile - Application d'Identification Biométrique

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/togoom/togoom-mobile)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)](https://github.com/togoom/togoom-mobile)
[![Android](https://img.shields.io/badge/Android-5.0%2B-green.svg)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.16-02569B.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2-0175C2.svg)](https://dart.dev)

## 🎯 Vue d'ensemble

TOGOOM Mobile est l'application mobile du système d'identification biométrique TOGOOM, conçue pour offrir une expérience de vérification d'identité fluide et sécurisée sur smartphones et tablettes. Inspirée des meilleures pratiques d'Innovatrics DOT, l'app permet une vérification d'identité complète en quelques secondes.

### Fonctionnalités principales de l'app mobile

- 📸 **Capture de documents** : Scan intelligent des pièces d'identité avec guidage en temps réel
- 🤳 **Capture de selfie** : Interface intuitive avec détection automatique du visage
- 🔐 **Détection de vivacité** : Protection anti-fraude intégrée (passive et active)
- 📱 **Mode hors ligne** : Fonctionnement partiel sans connexion internet
- 🌍 **Multi-langue** : Support du français, anglais et langues locales
- ⚡ **Performance optimisée** : Conçu pour fonctionner sur tous types d'appareils

## 📱 Captures d'écran

*[Les captures d'écran seront ajoutées prochainement]*

## 🏗️ Architecture simplifiée

```
┌──────────────────────────────┐
│     TOGOOM Mobile App        │
│        (Flutter)             │
└──────────────┬───────────────┘
               │ HTTPS/REST
               ↓
┌──────────────────────────────┐
│      TOGOOM Backend API      │
│    • Vérification identité   │
│    • Matching biométrique    │
│    • Gestion des sessions    │
└──────────────────────────────┘
```

L'app mobile communique avec le backend TOGOOM via des APIs REST sécurisées. Le backend gère toute la logique métier complexe (microservices, bases de données, intégrations tierces).

## 🚀 Démarrage rapide

### Prérequis

#### Pour Android
- Android Studio Arctic Fox ou plus récent
- Flutter SDK 3.16+
- Dart SDK 3.2+
- Android SDK (API 21+)

#### Pour iOS
- Xcode 14+
- macOS Monterey ou plus récent
- CocoaPods 1.11+
- Flutter SDK 3.16+

### Installation

1. **Cloner le repository**
```bash
git clone https://github.com/togoom/togoom-mobile.git
cd togoom-mobile
```

2. **Vérifier l'installation Flutter**
```bash
flutter doctor
```

3. **Installer les dépendances**
```bash
flutter pub get
```

4. **Configuration iOS (macOS uniquement)**
```bash
cd ios
pod install
cd ..
```

5. **Configuration de l'environnement**
```bash
cp .env.example .env
# Éditer .env avec l'URL de votre API backend
```

### Lancer l'application

#### Android
```bash
# Démarrer un émulateur ou connecter un appareil
flutter run
# ou spécifiquement pour Android
flutter run -d android
```

#### iOS
```bash
# Démarrer un simulateur
flutter run
# ou spécifiquement pour iOS
flutter run -d ios
```

#### Mode développement avec hot reload
```bash
# Hot reload est automatiquement activé avec flutter run
# Appuyez sur 'r' pour hot reload
# Appuyez sur 'R' pour hot restart
flutter run
```

## 📋 Configuration

### Variables d'environnement (.env)

```env
# API Backend
API_BASE_URL=https://api.togoom.com
API_TIMEOUT=30000

# Configuration App
APP_ENV=development
ENABLE_LOGS=true

# Sécurité
ENABLE_BIOMETRIC_AUTH=true
ENABLE_SSL_PINNING=true

# Camera
DOCUMENT_CAPTURE_QUALITY=high
SELFIE_CAPTURE_QUALITY=medium

# Cache & Offline
CACHE_SIZE_MB=100
OFFLINE_MODE_ENABLED=true
```

### Configuration par plateforme

#### Android (`android/app/build.gradle`)
```gradle
defaultConfig {
    applicationId "com.togoom.mobile"
    minSdkVersion flutter.minSdkVersion
    targetSdkVersion flutter.targetSdkVersion
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName
}
```

#### iOS (`ios/Runner/Info.plist`)
- Configuration des permissions caméra
- Configuration Face ID / Touch ID  
- URL schemes pour deep linking

#### Flutter (`pubspec.yaml`)
```yaml
name: togoom_mobile
description: TOGOOM Mobile - Application d'identification biométrique
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: ">=3.16.0"
```

## 📊 Fonctionnalités de l'app mobile

### Processus de vérification
1. **Scan du document d'identité**
   - Guide visuel en temps réel
   - Détection automatique du type de document
   - Extraction OCR des informations
   - Validation de la qualité de capture

2. **Capture du selfie**
   - Détection automatique du visage
   - Guide de positionnement
   - Vérification de la luminosité
   - Capture haute résolution

3. **Détection de vivacité**
   - Mode passif : Analyse automatique
   - Mode actif : Suivi du regard ou sourire
   - Protection anti-fraude avancée

4. **Résultat de vérification**
   - Affichage du score de matching
   - Détails de la vérification
   - Options d'export du rapport

### Fonctionnalités additionnelles
- 📱 **Mode offline** : Capture et stockage local en attente de connexion
- 🔄 **Synchronisation automatique** : Envoi des données dès que la connexion est rétablie
- 🌍 **Support multi-langue** : FR, EN, langues locales
- 🔐 **Stockage sécurisé** : Chiffrement local des données sensibles
- 📊 **Historique** : Consultation des vérifications précédentes

## 🔒 Sécurité de l'app mobile

### Protection des données
- **Chiffrement local** : AES-256 pour toutes les données stockées
- **SSL Pinning** : Protection contre les attaques MITM
- **Obfuscation du code** : Protection contre le reverse engineering
- **Root/Jailbreak detection** : Blocage sur appareils compromis

### Authentification
- **Biométrie** : Face ID, Touch ID, empreinte digitale
- **PIN/Pattern** : Code d'accès local
- **Session timeout** : Déconnexion automatique après inactivité

### Protection de la vie privée
- Aucune donnée biométrique stockée sur l'appareil
- Suppression automatique des photos après traitement
- Consentement explicite pour chaque capture
- Conformité RGPD intégrée

## 🏛️ Structure du projet

```
togoom-mobile/
├── android/                 # Code natif Android
│   ├── app/
│   └── gradle/
├── ios/                     # Code natif iOS
│   ├── Runner/
│   └── Pods/
├── lib/                     # Code source Flutter/Dart
│   ├── core/               # Configuration et constantes
│   ├── features/           # Fonctionnalités par domaine
│   │   ├── auth/           # Authentification
│   │   ├── document/       # Capture de documents
│   │   ├── biometric/      # Capture biométrique
│   │   └── verification/   # Processus de vérification
│   ├── shared/             # Composants partagés
│   │   ├── widgets/        # Widgets réutilisables
│   │   ├── services/       # Services API
│   │   └── utils/          # Utilitaires
│   └── main.dart           # Point d'entrée de l'application
├── assets/                 # Assets (images, fonts, etc.)
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/                   # Tests unitaires et d'intégration
├── integration_test/       # Tests d'intégration
├── .env.example           # Variables d'environnement exemple
├── pubspec.yaml           # Dépendances Flutter
└── README.md             # Ce fichier
```

## 🧪 Tests

### Tests unitaires
```bash
flutter test
```

### Tests d'intégration
```bash
flutter test integration_test
```

### Tests avec couverture
```bash
flutter test --coverage
```

### Tests sur appareil réel

#### Android
```bash
# Générer l'APK de test
flutter build apk --debug
# L'APK se trouve dans build/app/outputs/flutter-apk/
```

#### iOS
```bash
# Build pour iOS
flutter build ios --debug --no-codesign
# Ouvrir dans Xcode
open ios/Runner.xcworkspace
# Build and Run sur un appareil connecté
```

## 🚢 Déploiement

### Build de production

#### Android
```bash
# Générer l'AAB pour le Play Store
flutter build appbundle
# Le bundle se trouve dans build/app/outputs/bundle/release/

# Ou générer un APK
flutter build apk --release
```

#### iOS
```bash
# Build pour iOS
flutter build ios --release
# Puis via Xcode
1. Ouvrir ios/Runner.xcworkspace
2. Product > Archive
3. Distribute App
```

### Publication

#### Google Play Store
1. Générer le bundle AAB signé
2. Upload sur Google Play Console
3. Remplir les informations de l'app
4. Soumettre pour review

#### Apple App Store
1. Archive l'app via Xcode
2. Upload sur App Store Connect
3. Remplir les métadonnées
4. Soumettre pour review

## 🗺️ Roadmap Mobile

### Version 1.0 (MVP - En cours)
- ✅ Capture de documents
- ✅ Capture de selfie
- ✅ Détection de vivacité passive
- ✅ Intégration API backend
- 🔄 Tests et optimisations

### Version 1.1 (Q2 2025)
- 📱 Support tablettes
- 🔄 Mode offline amélioré
- 🎨 Thème sombre
- 🌍 Nouvelles langues locales

### Version 2.0 (Q3 2025)
- 🤳 Détection de vivacité active avancée
- 📊 Dashboard utilisateur
- 🔐 Authentification biométrique renforcée
- 📱 Widget iOS/Android

### Version 3.0 (Q4 2025)
- 🎯 SDK pour intégration tierces
- 🔄 Synchronisation multi-appareils
- 🤖 Assistant IA intégré
- 📈 Analytics avancées

## 🤝 Contribution

Les contributions sont les bienvenues ! Consultez notre [guide de contribution](CONTRIBUTING.md) pour :
- Standards de code
- Process de review
- Tests requis
- Documentation

## 📝 Licence

Ce projet est propriétaire et développé par NEIBA Technologies pour TOGOOM.

Tous droits réservés © 2025 NEIBA Technologies

## 📞 Support

- **Email** : support@togoom.com
- **Documentation** : https://docs.togoom.com
- **Issues** : https://github.com/togoom/togoom/issues

## 🏢 À propos

**NEIBA Technologies**  
Immeuble NÉHÉMIE, Bingerville Oribat  
93QP+MR Abidjan, Côte d'Ivoire  
Email : contact@neiba-technologies.com  
Téléphone : +225 27 22 23 45 68

---

*Développé avec ❤️ en Côte d'Ivoire pour l'Afrique*